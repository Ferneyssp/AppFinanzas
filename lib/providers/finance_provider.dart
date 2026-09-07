import 'package:flutter/material.dart';

import '../models/categorias.dart';
import '../models/movimiento.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../services/notificacion_service.dart';
import '../services/preferencias_service.dart';

/// Provider central de la aplicación: mantiene en memoria la lista de
/// movimientos, calcula los totales/alertas del mes activo mediante
/// [FinanceCalculator], coordina la persistencia ([DatabaseService]) y
/// dispara notificaciones locales cuando corresponde.
///
/// Se mantiene deliberadamente sin lógica de UI: las pantallas solo
/// leen sus getters y llaman a sus métodos.
class FinanceProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final PreferenciasService _prefs = PreferenciasService.instance;
  final NotificacionService _notificaciones = NotificacionService.instance;

  List<Movimiento> _movimientos = [];
  bool _cargando = true;

  List<Movimiento> get todos => List.unmodifiable(_movimientos);
  bool get cargando => _cargando;

  String get _claveMesActivo {
    final ahora = DateTime.now();
    return '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';
  }

  List<Movimiento> get movimientosDelMesActivo {
    final ahora = DateTime.now();
    return _movimientos.where((m) {
      return m.fecha.year == ahora.year && m.fecha.month == ahora.month;
    }).toList();
  }

  List<Movimiento> get ingresosDelMes =>
      movimientosDelMesActivo.where((m) => m.esIngreso).toList();

  List<Movimiento> get egresosDelMes =>
      movimientosDelMesActivo.where((m) => m.esEgreso).toList();

  double get totalIngresos =>
      ingresosDelMes.fold(0.0, (suma, m) => suma + m.monto);

  double get totalEgresos =>
      egresosDelMes.fold(0.0, (suma, m) => suma + m.monto);

  double get saldoDisponible => FinanceCalculator.calcularSaldo(
        totalIngresos: totalIngresos,
        totalEgresos: totalEgresos,
      );

  double? get porcentajeDisponible => FinanceCalculator.calcularPorcentajeDisponible(
        totalIngresos: totalIngresos,
        saldoDisponible: saldoDisponible,
      );

  NivelAlerta get nivelAlerta => FinanceCalculator.calcularNivelAlerta(
        totalIngresos: totalIngresos,
        porcentajeDisponible: porcentajeDisponible,
      );

  /// Movimientos más recientes primero, para el resumen del dashboard.
  List<Movimiento> get recientes {
    final lista = List<Movimiento>.from(_movimientos);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista.take(5).toList();
  }

  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();
    _movimientos = await _db.obtenerTodos();
    _cargando = false;
    notifyListeners();
    await _evaluarAlertaCritica();
  }

  Future<void> agregarIngreso({
    required String descripcion,
    required String categoria,
    required double monto,
    required DateTime fecha,
  }) async {
    final movimiento = Movimiento(
      tipo: TipoMovimiento.ingreso,
      descripcion: descripcion,
      categoria: categoria,
      monto: monto,
      fecha: fecha,
      createdAt: DateTime.now(),
    );
    final id = await _db.insertarMovimiento(movimiento);
    _movimientos.insert(0, movimiento.copyWith(id: id));
    notifyListeners();
    await _evaluarAlertaCritica();
  }

  /// Intenta registrar un egreso. Vuelve a validar la regla de negocio
  /// justo antes de guardar (defensa en profundidad, además de la
  /// validación que deshabilita el botón en el formulario).
  Future<ResultadoValidacionEgreso> intentarAgregarEgreso({
    required String descripcion,
    required String categoria,
    required double monto,
    required DateTime fecha,
  }) async {
    final validacion = FinanceCalculator.validarEgreso(
      totalIngresos: totalIngresos,
      totalEgresosActuales: totalEgresos,
      nuevoMonto: monto,
    );
    if (!validacion.esValido) return validacion;

    final movimiento = Movimiento(
      tipo: TipoMovimiento.egreso,
      descripcion: descripcion,
      categoria: categoria,
      monto: monto,
      fecha: fecha,
      createdAt: DateTime.now(),
    );
    final id = await _db.insertarMovimiento(movimiento);
    _movimientos.insert(0, movimiento.copyWith(id: id));
    notifyListeners();
    await _evaluarAlertaCritica();
    return validacion;
  }

  /// Igual que [intentarAgregarEgreso] pero para editar uno existente,
  /// excluyendo su monto anterior del cálculo del límite.
  Future<ResultadoValidacionEgreso> intentarActualizarEgreso({
    required Movimiento original,
    required String descripcion,
    required String categoria,
    required double monto,
    required DateTime fecha,
  }) async {
    final validacion = FinanceCalculator.validarEgreso(
      totalIngresos: totalIngresos,
      totalEgresosActuales: totalEgresos,
      nuevoMonto: monto,
      montoEgresoExcluido: original.monto,
    );
    if (!validacion.esValido) return validacion;

    final actualizado = original.copyWith(
      descripcion: descripcion,
      categoria: categoria,
      monto: monto,
      fecha: fecha,
    );
    await _db.actualizarMovimiento(actualizado);
    final index = _movimientos.indexWhere((m) => m.id == original.id);
    if (index != -1) _movimientos[index] = actualizado;
    notifyListeners();
    await _evaluarAlertaCritica();
    return validacion;
  }

  /// Permite actualizar un ingreso existente asegurando que el total de
  /// ingresos no quede por debajo del total de gastos del mes activo.
  Future<ResultadoValidacionIngreso> intentarActualizarIngreso({
    required Movimiento original,
    required String descripcion,
    required String categoria,
    required double monto,
    required DateTime fecha,
  }) async {
    final ahora = DateTime.now();
    final eraDelMesActivo =
        original.fecha.year == ahora.year && original.fecha.month == ahora.month;
    final seraDelMesActivo =
        fecha.year == ahora.year && fecha.month == ahora.month;

    if (eraDelMesActivo || seraDelMesActivo) {
      final totalIngresosActual = totalIngresos;
      final montoOriginalMes = eraDelMesActivo ? original.monto : 0.0;
      final nuevoMontoMes = seraDelMesActivo ? monto : 0.0;

      final validacion = FinanceCalculator.validarActualizacionIngreso(
        totalIngresosActuales: totalIngresosActual,
        totalEgresos: totalEgresos,
        montoIngresoOriginal: montoOriginalMes,
        nuevoMonto: nuevoMontoMes,
      );
      if (!validacion.esValido) return validacion;
    }

    final actualizado = original.copyWith(
      descripcion: descripcion,
      categoria: categoria,
      monto: monto,
      fecha: fecha,
    );
    await _db.actualizarMovimiento(actualizado);
    final index = _movimientos.indexWhere((m) => m.id == original.id);
    if (index != -1) _movimientos[index] = actualizado;
    notifyListeners();
    await _evaluarAlertaCritica();
    return const ResultadoValidacionIngreso.valido();
  }

  /// Intenta eliminar un movimiento. Si es un ingreso del mes activo,
  /// valida que los gastos restantes no superen los ingresos.
  Future<ResultadoValidacionIngreso> intentarEliminarMovimiento(Movimiento m) async {
    final ahora = DateTime.now();
    final esDelMesActivo =
        m.fecha.year == ahora.year && m.fecha.month == ahora.month;

    if (m.esIngreso && esDelMesActivo) {
      final validacion = FinanceCalculator.validarEliminacionIngreso(
        totalIngresosActuales: totalIngresos,
        totalEgresos: totalEgresos,
        montoIngresoEliminado: m.monto,
      );
      if (!validacion.esValido) return validacion;
    }

    if (m.id != null) {
      await _db.eliminarMovimiento(m.id!);
      _movimientos.removeWhere((item) => item.id == m.id);
      notifyListeners();
      await _evaluarAlertaCritica();
    }
    return const ResultadoValidacionIngreso.valido();
  }

  Future<void> eliminarMovimiento(int id) async {
    await _db.eliminarMovimiento(id);
    _movimientos.removeWhere((m) => m.id == id);
    notifyListeners();
    await _evaluarAlertaCritica();
  }

  /// Evalúa si corresponde disparar la notificación de estado crítico,
  /// evitando repetirla innecesariamente en el mismo mes. Si el estado
  /// deja de ser crítico, se restablece la bandera para que una futura
  /// reentrada al estado crítico vuelva a notificar.
  Future<void> _evaluarAlertaCritica() async {
    final clave = _claveMesActivo;
    if (nivelAlerta == NivelAlerta.critico) {
      final yaNotifico = await _prefs.yaNotificoCriticoEnMes(clave);
      if (!yaNotifico) {
        await _notificaciones.mostrarAlertaCritica(
          'Tu presupuesto está casi agotado. Solo tienes disponible el '
          '${porcentajeDisponible?.toStringAsFixed(0) ?? 0}% de tus ingresos.',
        );
        await _prefs.marcarNotificoCriticoEnMes(clave, true);
      }
    } else {
      await _prefs.marcarNotificoCriticoEnMes(clave, false);
    }
  }

  /// Carga un conjunto de movimientos de demostración, solo si el
  /// usuario aún no lo ha hecho antes y no interfiere con datos reales
  /// ya existentes (se agrega, no reemplaza).
  Future<void> cargarDatosDemo() async {
    final ahora = DateTime.now();
    final demo = <Movimiento>[
      Movimiento(
        tipo: TipoMovimiento.ingreso,
        descripcion: 'Beca universitaria',
        categoria: CategoriasIngreso.beca,
        monto: 800000,
        fecha: DateTime(ahora.year, ahora.month, 2),
        createdAt: DateTime.now(),
      ),
      Movimiento(
        tipo: TipoMovimiento.ingreso,
        descripcion: 'Mesada',
        categoria: CategoriasIngreso.mesada,
        monto: 400000,
        fecha: DateTime(ahora.year, ahora.month, 3),
        createdAt: DateTime.now(),
      ),
      Movimiento(
        tipo: TipoMovimiento.ingreso,
        descripcion: 'Trabajo freelance',
        categoria: CategoriasIngreso.trabajo,
        monto: 300000,
        fecha: DateTime(ahora.year, ahora.month, 5),
        createdAt: DateTime.now(),
      ),
      Movimiento(
        tipo: TipoMovimiento.egreso,
        descripcion: 'Mercado del mes',
        categoria: CategoriasEgreso.alimentacion,
        monto: 250000,
        fecha: DateTime(ahora.year, ahora.month, 6),
        createdAt: DateTime.now(),
      ),
      Movimiento(
        tipo: TipoMovimiento.egreso,
        descripcion: 'Bus universitario',
        categoria: CategoriasEgreso.transporte,
        monto: 100000,
        fecha: DateTime(ahora.year, ahora.month, 7),
        createdAt: DateTime.now(),
      ),
      Movimiento(
        tipo: TipoMovimiento.egreso,
        descripcion: 'Matrícula complementaria',
        categoria: CategoriasEgreso.educacion,
        monto: 200000,
        fecha: DateTime(ahora.year, ahora.month, 8),
        createdAt: DateTime.now(),
      ),
      Movimiento(
        tipo: TipoMovimiento.egreso,
        descripcion: 'Cine con amigos',
        categoria: CategoriasEgreso.entretenimiento,
        monto: 100000,
        fecha: DateTime(ahora.year, ahora.month, 9),
        createdAt: DateTime.now(),
      ),
    ];
    for (final m in demo) {
      final id = await _db.insertarMovimiento(m);
      _movimientos.insert(0, m.copyWith(id: id));
    }
    await _prefs.marcarDemoCargada(true);
    notifyListeners();
    await _evaluarAlertaCritica();
  }

  Future<bool> demoYaCargada() => _prefs.obtenerDemoCargada();

  Future<void> eliminarTodosLosDatos() async {
    await _db.eliminarTodos();
    _movimientos = [];
    await _prefs.marcarDemoCargada(false);
    notifyListeners();
    await _evaluarAlertaCritica();
  }
}
