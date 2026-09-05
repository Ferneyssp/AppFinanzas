import 'package:flutter/material.dart';

import '../services/preferencias_service.dart';

/// Define los colores principal, secundario y de acento para cada
/// paleta disponible. Estos colores alimentan el `ColorScheme` de
/// Material 3, por lo que se propagan automáticamente a botones,
/// indicadores, barras de progreso e íconos destacados.
class PaletteColors {
  final Color primario;
  final Color secundario;
  final Color acento;

  const PaletteColors({
    required this.primario,
    required this.secundario,
    required this.acento,
  });
}

const Map<PaletaColor, PaletteColors> paletteDefinitions = {
  PaletaColor.azul: PaletteColors(
    primario: Color(0xFF2563EB),
    secundario: Color(0xFF60A5FA),
    acento: Color(0xFF1D4ED8),
  ),
  PaletaColor.verde: PaletteColors(
    primario: Color(0xFF059669),
    secundario: Color(0xFF34D399),
    acento: Color(0xFF047857),
  ),
  PaletaColor.morado: PaletteColors(
    primario: Color(0xFF7C3AED),
    secundario: Color(0xFFA78BFA),
    acento: Color(0xFF5B21B6),
  ),
};

/// Colores fijos para los estados del presupuesto, independientes de
/// la paleta seleccionada por el usuario (para mantener significado
/// universal: verde=bien, ámbar=precaución, rojo=crítico).
class EstadoPresupuestoColors {
  static const Color normal = Color(0xFF10B981);
  static const Color precaucion = Color(0xFFF59E0B);
  static const Color critico = Color(0xFFEF4444);
  static const Color neutro = Color(0xFF9CA3AF);
}
