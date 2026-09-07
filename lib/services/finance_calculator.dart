import '../utils/currency_formatter.dart';

/// Nivel de alerta del presupuesto mensual.
enum NivelAlerta {
  /// Aún no se han registrado ingresos: no aplica ningún cálculo.
  sinIngresos,

  /// Saldo disponible > 30% de los ingresos.
  normal,

  /// Saldo disponible <= 30% de los ingresos.
  precaucion,

  /// Saldo disponible <= 10% de los ingresos.
  critico,
}

/// Resultado de validar si un egreso puede registrarse.
class ResultadoValidacionEgreso {
  final bool esValido;
  final String? mensajePrincipal;
  final String? mensajeSecundario;

  const ResultadoValidacionEgreso.valido()
      : esValido = true,
        mensajePrincipal = null,
        mensajeSecundario = null;

  const ResultadoValidacionEgreso.invalido({
    required String mensaje,
    required String montoMaximo,
  })  : esValido = false,
        mensajePrincipal = mensaje,
        mensajeSecundario = montoMaximo;
}

/// Resultado de validar si un ingreso puede actualizarse o eliminarse.
class ResultadoValidacionIngreso {
  final bool esValido;
  final String? mensajePrincipal;
  final String? mensajeSecundario;

  const ResultadoValidacionIngreso.valido()
      : esValido = true,
        mensajePrincipal = null,
        mensajeSecundario = null;

  const ResultadoValidacionIngreso.invalido({
    required String mensaje,
    required String montoMinimo,
  })  : esValido = false,
        mensajePrincipal = mensaje,
        mensajeSecundario = montoMinimo;
}

/// Contiene toda la lógica de negocio financiera de la aplicación,
/// deliberadamente separada de la interfaz y de la persistencia para
/// que pueda probarse de forma aislada (unit tests) y reutilizarse
/// desde cualquier pantalla o desde el intérprete de voz.
class FinanceCalculator {
  const FinanceCalculator._();

  /// Umbral (en fracción, no en %) a partir del cual se activa la
  /// alerta de precaución.
  static const double umbralPrecaucion = 0.30;

  /// Umbral a partir del cual se activa la alerta crítica.
  static const double umbralCritico = 0.10;

  static double calcularSaldo({
    required double totalIngresos,
    required double totalEgresos,
  }) {
    return totalIngresos - totalEgresos;
  }

  /// Retorna el porcentaje disponible (0-100) o `null` si aún no hay
  /// ingresos registrados (caso especial descrito en los requisitos).
  static double? calcularPorcentajeDisponible({
    required double totalIngresos,
    required double saldoDisponible,
  }) {
    if (totalIngresos <= 0) return null;
    final porcentaje = (saldoDisponible / totalIngresos) * 100;
    // Se permite mostrar negativos como 0 para no romper la UI, aunque
    // en la práctica la regla de negocio impide que el saldo sea negativo.
    return porcentaje < 0 ? 0 : porcentaje;
  }

  static NivelAlerta calcularNivelAlerta({
    required double totalIngresos,
    required double? porcentajeDisponible,
  }) {
    if (totalIngresos <= 0 || porcentajeDisponible == null) {
      return NivelAlerta.sinIngresos;
    }
    final fraccion = porcentajeDisponible / 100;
    if (fraccion <= umbralCritico) return NivelAlerta.critico;
    if (fraccion <= umbralPrecaucion) return NivelAlerta.precaucion;
    return NivelAlerta.normal;
  }

  /// Valida si un nuevo egreso (o la edición de uno existente) puede
  /// registrarse sin que el total de egresos supere el total de
  /// ingresos del mes activo.
  ///
  /// [montoEgresoExcluido] permite excluir el monto actual de un egreso
  /// que se está editando, para recalcular correctamente el límite.
  static ResultadoValidacionEgreso validarEgreso({
    required double totalIngresos,
    required double totalEgresosActuales,
    required double nuevoMonto,
    double montoEgresoExcluido = 0,
  }) {
    final egresosSinElActual = totalEgresosActuales - montoEgresoExcluido;
    final saldoActual = totalIngresos - egresosSinElActual;
    final saldoDespues = saldoActual - nuevoMonto;

    if (saldoDespues < 0) {
      final maximoPermitido = saldoActual < 0 ? 0 : saldoActual;
      return ResultadoValidacionEgreso.invalido(
        mensaje: 'No puedes registrar este gasto. Tu saldo disponible es de '
            '${CurrencyFormatter.format(maximoPermitido)} y estás intentando '
            'gastar ${CurrencyFormatter.format(nuevoMonto)}.',
        montoMaximo:
            'Monto máximo permitido: ${CurrencyFormatter.format(maximoPermitido)}',
      );
    }
    return const ResultadoValidacionEgreso.valido();
  }

  /// Valida si un ingreso existente puede actualizarse a [nuevoMonto] sin
  /// que el total de ingresos quede por debajo del total de gastos
  /// del mes activo.
  static ResultadoValidacionIngreso validarActualizacionIngreso({
    required double totalIngresosActuales,
    required double totalEgresos,
    required double montoIngresoOriginal,
    required double nuevoMonto,
  }) {
    final otrosIngresos = totalIngresosActuales - montoIngresoOriginal;
    final nuevoTotalIngresos = otrosIngresos + nuevoMonto;

    if (nuevoTotalIngresos < totalEgresos) {
      final minimoRequerido = totalEgresos - otrosIngresos;
      final minimoPermitido = minimoRequerido < 0 ? 0.0 : minimoRequerido;
      return ResultadoValidacionIngreso.invalido(
        mensaje: 'No puedes actualizar este ingreso con este monto. '
            'El total de ingresos no puede ser menor al total de gastos '
            '(${CurrencyFormatter.format(totalEgresos)}).',
        montoMinimo:
            'Monto mínimo requerido para este ingreso: ${CurrencyFormatter.format(minimoPermitido)}',
      );
    }
    return const ResultadoValidacionIngreso.valido();
  }

  /// Valida si un ingreso existente puede eliminarse sin que el total de
  /// ingresos quede por debajo del total de gastos del mes activo.
  static ResultadoValidacionIngreso validarEliminacionIngreso({
    required double totalIngresosActuales,
    required double totalEgresos,
    required double montoIngresoEliminado,
  }) {
    final nuevoTotalIngresos = totalIngresosActuales - montoIngresoEliminado;
    if (nuevoTotalIngresos < totalEgresos) {
      return ResultadoValidacionIngreso.invalido(
        mensaje: 'No puedes eliminar este ingreso porque el total de ingresos '
            'quedaría por debajo del total de gastos '
            '(${CurrencyFormatter.format(totalEgresos)}).',
        montoMinimo: 'Gastos actuales: ${CurrencyFormatter.format(totalEgresos)}',
      );
    }
    return const ResultadoValidacionIngreso.valido();
  }
}
