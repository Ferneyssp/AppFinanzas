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
}
