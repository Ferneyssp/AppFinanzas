import 'package:flutter/material.dart';

import '../services/preferencias_service.dart';

/// Maneja el estado de las preferencias de personalización: tema,
/// paleta de colores, alias del estudiante y nombre/emoji del mes
/// activo. Se carga una sola vez al iniciar la app y persiste cada
/// cambio inmediatamente mediante [PreferenciasService].
class SettingsProvider extends ChangeNotifier {
  final PreferenciasService _prefs = PreferenciasService.instance;

  ModoTema _tema = ModoTema.claro;
  PaletaColor _paleta = PaletaColor.azul;
  String _alias = 'Estudiante';
  String _nombreMes = '';
  String _emojiMes = '💰';
  bool _cargado = false;

  ModoTema get tema => _tema;
  PaletaColor get paleta => _paleta;
  String get alias => _alias;
  String get emojiMes => _emojiMes;
  bool get cargado => _cargado;

  /// Nombre a mostrar para el mes activo: si el usuario personalizó un
  /// nombre lo usa, de lo contrario cae al nombre real del mes en curso.
  String nombreMesMostrado() {
    if (_nombreMes.trim().isNotEmpty) return _nombreMes;
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return meses[DateTime.now().month - 1];
  }

  Future<void> cargar() async {
    _tema = await _prefs.obtenerTema();
    _paleta = await _prefs.obtenerPaleta();
    _alias = await _prefs.obtenerAlias();
    _nombreMes = await _prefs.obtenerNombreMes();
    _emojiMes = await _prefs.obtenerEmojiMes();
    _cargado = true;
    notifyListeners();
  }

  Future<void> cambiarTema(ModoTema nuevoTema) async {
    _tema = nuevoTema;
    notifyListeners();
    await _prefs.guardarTema(nuevoTema);
  }

  Future<void> cambiarPaleta(PaletaColor nuevaPaleta) async {
    _paleta = nuevaPaleta;
    notifyListeners();
    await _prefs.guardarPaleta(nuevaPaleta);
  }

  Future<void> cambiarAlias(String nuevoAlias) async {
    final aliasLimpio =
    nuevoAlias.trim().isEmpty ? 'Estudiante' : nuevoAlias.trim();

    await _prefs.guardarAlias(aliasLimpio);

    _alias = aliasLimpio;

    notifyListeners();
  }

  Future<void> cambiarNombreMes(String nombre) async {
    _nombreMes = nombre.trim();
    notifyListeners();
    await _prefs.guardarNombreMes(_nombreMes);
  }

  Future<void> cambiarEmojiMes(String emoji) async {
    _emojiMes = emoji.trim().isEmpty ? '💰' : emoji.trim();
    notifyListeners();
    await _prefs.guardarEmojiMes(_emojiMes);
  }
}
