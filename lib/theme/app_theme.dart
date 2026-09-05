import 'package:flutter/material.dart';

import '../services/preferencias_service.dart';
import 'color_palettes.dart';

/// Construye los `ThemeData` claro y oscuro a partir de la paleta
/// seleccionada por el usuario. Centralizar esta lógica aquí evita
/// tener que tocar cada pantalla cuando cambia el tema o la paleta.
class AppTheme {
  static ThemeData claro(PaletaColor paleta) {
    final colores = paletteDefinitions[paleta]!;
    final scheme = ColorScheme.fromSeed(
      seedColor: colores.primario,
      brightness: Brightness.light,
    );
    return _base(scheme, colores, Brightness.light);
  }

  static ThemeData oscuro(PaletaColor paleta) {
    final colores = paletteDefinitions[paleta]!;
    final scheme = ColorScheme.fromSeed(
      seedColor: colores.primario,
      brightness: Brightness.dark,
    );
    return _base(scheme, colores, Brightness.dark);
  }

  static ThemeData _base(
    ColorScheme scheme,
    PaletteColors colores,
    Brightness brightness,
  ) {
    final esOscuro = brightness == Brightness.dark;
    final fondo = esOscuro ? const Color(0xFF0F1115) : const Color(0xFFF7F8FA);
    final superficieTarjeta =
        esOscuro ? const Color(0xFF1B1E25) : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme.copyWith(primary: colores.primario),
      scaffoldBackgroundColor: fondo,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: esOscuro ? Colors.white : const Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: esOscuro ? Colors.white : const Color(0xFF111827),
        ),
      ),
      cardTheme: CardThemeData(
        color: superficieTarjeta,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colores.primario,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colores.primario,
          side: BorderSide(color: colores.primario),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficieTarjeta,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: esOscuro ? Colors.white24 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colores.primario, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: EstadoPresupuestoColors.critico),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colores.primario,
        linearTrackColor: esOscuro ? Colors.white12 : Colors.black12,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: superficieTarjeta,
        indicatorColor: colores.primario.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final seleccionado = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
            color: seleccionado
                ? colores.primario
                : (esOscuro ? Colors.white70 : Colors.black54),
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
