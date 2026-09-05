/// Catálogos de categorías utilizados por los formularios y por el
/// intérprete de comandos de voz. Mantenerlos centralizados evita
/// duplicación e inconsistencias entre pantallas.
class CategoriasIngreso {
  static const beca = 'Beca';
  static const mesada = 'Mesada';
  static const trabajo = 'Trabajo';
  static const negocio = 'Negocio';
  static const ayudaFamiliar = 'Ayuda familiar';
  static const otro = 'Otro';

  static const List<String> todas = [
    beca,
    mesada,
    trabajo,
    negocio,
    ayudaFamiliar,
    otro,
  ];
}

class CategoriasEgreso {
  static const alimentacion = 'Alimentación';
  static const transporte = 'Transporte';
  static const entretenimiento = 'Entretenimiento';
  static const salud = 'Salud';
  static const educacion = 'Educación';
  static const otro = 'Otro';

  static const List<String> todas = [
    alimentacion,
    transporte,
    entretenimiento,
    salud,
    educacion,
    otro,
  ];
}

/// Devuelve un ícono (emoji) representativo para cada categoría, usado
/// en listados e historial para mejorar la jerarquía visual.
String emojiParaCategoria(String categoria) {
  switch (categoria) {
    case CategoriasIngreso.beca:
      return '🎓';
    case CategoriasIngreso.mesada:
      return '👛';
    case CategoriasIngreso.trabajo:
      return '💼';
    case CategoriasIngreso.negocio:
      return '🏪';
    case CategoriasIngreso.ayudaFamiliar:
      return '👨‍👩‍👧';
    case CategoriasEgreso.alimentacion:
      return '🍔';
    case CategoriasEgreso.transporte:
      return '🚌';
    case CategoriasEgreso.entretenimiento:
      return '🎬';
    case CategoriasEgreso.salud:
      return '💊';
    case CategoriasEgreso.educacion:
      return '📚';
    default:
      return '💳';
  }
}
