import 'currency_formatter.dart';

/// Validadores reutilizables para los formularios de ingresos y
/// egresos. Retornan un mensaje de error (String) o `null` si el
/// campo es válido, siguiendo la convención de `FormField.validator`.
class Validators {
  static String? descripcionRequerida(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'La descripción es obligatoria.';
    }
    if (valor.trim().length < 2) {
      return 'La descripción es muy corta.';
    }
    return null;
  }

  static String? montoRequerido(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'El monto es obligatorio.';
    }
    final parsed = CurrencyFormatter.parse(valor);
    if (parsed == null) {
      return 'Ingresa un monto válido.';
    }
    if (parsed <= 0) {
      return 'Ingresa un monto mayor a \$0.';
    }
    return null;
  }

  static String? categoriaRequerida(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Selecciona una categoría.';
    }
    return null;
  }

  static String? fechaRequerida(DateTime? valor) {
    if (valor == null) return 'Selecciona una fecha.';
    final hoyMasUnDia = DateTime.now().add(const Duration(days: 1));
    if (valor.isAfter(hoyMasUnDia)) {
      return 'La fecha no puede ser en el futuro.';
    }
    return null;
  }
}
