/// Tipo de movimiento financiero.
enum TipoMovimiento { ingreso, egreso }

extension TipoMovimientoX on TipoMovimiento {
  String get valor => this == TipoMovimiento.ingreso ? 'INGRESO' : 'EGRESO';

  static TipoMovimiento fromValor(String valor) {
    return valor.toUpperCase() == 'INGRESO'
        ? TipoMovimiento.ingreso
        : TipoMovimiento.egreso;
  }
}

/// Representa un movimiento financiero (ingreso o egreso) registrado
/// por el estudiante. Este modelo es puro (sin dependencias de UI ni
/// de persistencia) para poder reutilizarse en toda la aplicación.
class Movimiento {
  final int? id;
  final TipoMovimiento tipo;
  final String descripcion;
  final String categoria;
  final double monto;
  final DateTime fecha;
  final DateTime createdAt;

  const Movimiento({
    this.id,
    required this.tipo,
    required this.descripcion,
    required this.categoria,
    required this.monto,
    required this.fecha,
    required this.createdAt,
  });

  bool get esIngreso => tipo == TipoMovimiento.ingreso;
  bool get esEgreso => tipo == TipoMovimiento.egreso;

  Movimiento copyWith({
    int? id,
    TipoMovimiento? tipo,
    String? descripcion,
    String? categoria,
    double? monto,
    DateTime? fecha,
    DateTime? createdAt,
  }) {
    return Movimiento(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'tipo': tipo.valor,
      'descripcion': descripcion,
      'categoria': categoria,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Movimiento.fromMap(Map<String, Object?> map) {
    return Movimiento(
      id: map['id'] as int?,
      tipo: TipoMovimientoX.fromValor(map['tipo'] as String),
      descripcion: map['descripcion'] as String,
      categoria: map['categoria'] as String,
      monto: (map['monto'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
