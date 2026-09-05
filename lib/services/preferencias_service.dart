import 'package:shared_preferences/shared_preferences.dart';

/// Paletas de color disponibles para personalizar la interfaz.
enum PaletaColor { azul, verde, morado }

/// Modo de tema visual.
enum ModoTema { claro, oscuro }

/// Servicio de persistencia de preferencias del usuario mediante
/// SharedPreferences. Se usa SharedPreferences (y no SQLite) porque son
/// pares clave-valor simples, sin necesidad de consultas relacionales.
class PreferenciasService {
  PreferenciasService._internal();
  static final PreferenciasService instance = PreferenciasService._internal();

  static const _kAlias = 'pref_alias';
  static const _kTema = 'pref_tema';
  static const _kPaleta = 'pref_paleta';
  static const _kMesNombre = 'pref_mes_nombre';
  static const _kMesEmoji = 'pref_mes_emoji';
  static const _kDemoCargada = 'pref_demo_cargada';
  static const _kNotificadoCriticoPrefix = 'pref_notificado_critico_';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String> obtenerAlias() async {
    final prefs = await _prefs;
    return prefs.getString(_kAlias) ?? 'Estudiante';
  }

  Future<void> guardarAlias(String alias) async {
    final prefs = await _prefs;
    await prefs.setString(_kAlias, alias.trim().isEmpty ? 'Estudiante' : alias.trim());
  }

  Future<ModoTema> obtenerTema() async {
    final prefs = await _prefs;
    final valor = prefs.getString(_kTema);
    return valor == 'oscuro' ? ModoTema.oscuro : ModoTema.claro;
  }

  Future<void> guardarTema(ModoTema tema) async {
    final prefs = await _prefs;
    await prefs.setString(_kTema, tema == ModoTema.oscuro ? 'oscuro' : 'claro');
  }

  Future<PaletaColor> obtenerPaleta() async {
    final prefs = await _prefs;
    final valor = prefs.getString(_kPaleta);
    switch (valor) {
      case 'verde':
        return PaletaColor.verde;
      case 'morado':
        return PaletaColor.morado;
      default:
        return PaletaColor.azul;
    }
  }

  Future<void> guardarPaleta(PaletaColor paleta) async {
    final prefs = await _prefs;
    await prefs.setString(_kPaleta, paleta.name);
  }

  Future<String> obtenerNombreMes() async {
    final prefs = await _prefs;
    return prefs.getString(_kMesNombre) ?? '';
  }

  Future<void> guardarNombreMes(String nombre) async {
    final prefs = await _prefs;
    await prefs.setString(_kMesNombre, nombre.trim());
  }

  Future<String> obtenerEmojiMes() async {
    final prefs = await _prefs;
    return prefs.getString(_kMesEmoji) ?? '💰';
  }

  Future<void> guardarEmojiMes(String emoji) async {
    final prefs = await _prefs;
    await prefs.setString(_kMesEmoji, emoji.trim().isEmpty ? '💰' : emoji.trim());
  }

  Future<bool> obtenerDemoCargada() async {
    final prefs = await _prefs;
    return prefs.getBool(_kDemoCargada) ?? false;
  }

  Future<void> marcarDemoCargada(bool valor) async {
    final prefs = await _prefs;
    await prefs.setBool(_kDemoCargada, valor);
  }

  /// Controla si ya se notificó el estado crítico para un mes dado
  /// (formato clave: 'YYYY-MM'), evitando notificaciones repetidas cada
  /// vez que se reconstruye la interfaz o se reinicia la app el mismo día.
  Future<bool> yaNotificoCriticoEnMes(String claveMes) async {
    final prefs = await _prefs;
    return prefs.getBool('$_kNotificadoCriticoPrefix$claveMes') ?? false;
  }

  Future<void> marcarNotificoCriticoEnMes(String claveMes, bool valor) async {
    final prefs = await _prefs;
    await prefs.setBool('$_kNotificadoCriticoPrefix$claveMes', valor);
  }
}
