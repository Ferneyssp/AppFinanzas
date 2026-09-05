import 'package:intl/intl.dart';

/// Formatea valores monetarios en pesos, sin decimales, con separador
/// de miles (formato habitual para estudiantes en Colombia: $1.500.000).
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('es_CO');

  static String format(num value) {
    return '\$${_formatter.format(value.round())}';
  }

  /// Parsea un texto ingresado por el usuario (puede incluir puntos,
  /// comas o el símbolo $) a un double. Retorna null si no es válido.
  static double? parse(String texto) {
    final limpio = texto.replaceAll(RegExp(r'[^\d.,]'), '');
    if (limpio.isEmpty) return null;
    // Se asume que puntos y comas son separadores de miles (no decimales),
    // ya que la app trabaja siempre con pesos enteros.
    final soloDigitos = limpio.replaceAll(RegExp(r'[.,]'), '');
    return double.tryParse(soloDigitos);
  }
}
