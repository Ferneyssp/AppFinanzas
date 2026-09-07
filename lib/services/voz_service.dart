import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/categorias.dart';
import '../models/movimiento.dart';

/// Resultado de interpretar un texto de voz como un movimiento.
class MovimientoInterpretado {
  final TipoMovimiento tipo;
  final String descripcion;
  final String categoria;
  final double monto;

  const MovimientoInterpretado({
    required this.tipo,
    required this.descripcion,
    required this.categoria,
    required this.monto,
  });
}

/// Errores posibles durante el flujo de reconocimiento de voz.
enum ErrorVoz { permisoDenegado, noSoportado, noReconocido }

class ResultadoEscuchaVoz {
  final String? textoReconocido;
  final MovimientoInterpretado? movimiento;
  final ErrorVoz? error;

  const ResultadoEscuchaVoz({this.textoReconocido, this.movimiento, this.error});
}

/// Servicio responsable de:
/// 1. Solicitar permisos de micrófono.
/// 2. Ejecutar el reconocimiento de voz (speech_to_text).
/// 3. Interpretar el texto reconocido y transformarlo en un
///    [MovimientoInterpretado] para pre-llenar el formulario de
///    confirmación. Nunca guarda datos directamente: eso siempre lo
///    decide el usuario desde la pantalla de confirmación.
class VozService {
  VozService._internal();
  static final VozService instance = VozService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _disponible = false;

  void Function(String textoParcial)? _onResultadoCallback;
  void Function()? _onFinalizadoCallback;
  bool _escuchandoActivo = false;
  Timer? _safetyTimer;

  Future<bool> solicitarPermiso() async {
    final estado = await Permission.microphone.request();
    return estado.isGranted;
  }

  Future<bool> inicializar() async {
    _disponible = await _speech.initialize(
      onError: (error) {
        print('ERROR VOZ: ${error.errorMsg}');
        print('ERROR PERMANENTE: ${error.permanent}');
        _manejarError(error);
      },
      onStatus: (status) {
        print('ESTADO VOZ: $status');
        _manejarStatus(status);
      },
    );
    return _disponible;
  }

  void _notificarFinalizado() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    if (_escuchandoActivo) {
      _escuchandoActivo = false;
      final cb = _onFinalizadoCallback;
      _onFinalizadoCallback = null;
      cb?.call();
    }
  }

  void _manejarStatus(String status) {
    if (status == 'notListening' || status == 'done') {
      _notificarFinalizado();
    }
  }

  void _manejarError(Object error) {
    _notificarFinalizado();
  }

  bool get estaEscuchando => _speech.isListening;

  /// Inicia la escucha y retorna, mediante [onResultado], el texto
  /// reconocido de forma incremental para poder mostrarlo en pantalla
  /// mientras el usuario habla.
  Future<void> escuchar({
    required void Function(String textoParcial) onResultado,
    required void Function() onFinalizado,
  }) async {
    _onResultadoCallback = onResultado;
    _onFinalizadoCallback = onFinalizado;
    _escuchandoActivo = true;

    _safetyTimer?.cancel();
    // Temporizador de respaldo si el motor no notifica tras finalizar el tiempo máximo
    _safetyTimer = Timer(const Duration(seconds: 13), () {
      if (_escuchandoActivo) {
        detener();
        _notificarFinalizado();
      }
    });

    await _speech.listen(
      localeId: 'es_CO',
      onResult: (result) {
        _onResultadoCallback?.call(result.recognizedWords);
        if (result.finalResult) {
          _notificarFinalizado();
        }
      },
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> detener() async {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    _escuchandoActivo = false;
    _onFinalizadoCallback = null;
    await _speech.stop();
  }

  Future<ResultadoEscuchaVoz> procesarFlujoCompleto(String textoFinal) async {
    if (textoFinal.trim().isEmpty) {
      return const ResultadoEscuchaVoz(error: ErrorVoz.noReconocido);
    }
    final interpretado = interpretarTexto(textoFinal);
    if (interpretado == null) {
      return ResultadoEscuchaVoz(
        textoReconocido: textoFinal,
        error: ErrorVoz.noReconocido,
      );
    }
    return ResultadoEscuchaVoz(
      textoReconocido: textoFinal,
      movimiento: interpretado,
    );
  }

  /// Interpreta un comando de voz en español y extrae tipo, monto,
  /// descripción y categoría sugerida.
  ///
  /// Ejemplos soportados:
  ///   "Gasté ocho mil pesos en transporte"
  ///   "Recibí quinientos mil pesos de mi beca"
  ///   "Pagué 20000 en almuerzo"
  ///   "Me llegó la mesada de 300000"
  static MovimientoInterpretado? interpretarTexto(String texto) {
    final textoNormalizado = texto.toLowerCase().trim();
    if (textoNormalizado.isEmpty) return null;

    final monto = _extraerMonto(textoNormalizado);
    if (monto == null || monto <= 0) return null;

    final esIngreso = _pareceIngreso(textoNormalizado);
    final tipo = esIngreso ? TipoMovimiento.ingreso : TipoMovimiento.egreso;

    final categoria = esIngreso
        ? _detectarCategoriaIngreso(textoNormalizado)
        : _detectarCategoriaEgreso(textoNormalizado);

    final descripcion = _generarDescripcion(categoria, esIngreso);

    return MovimientoInterpretado(
      tipo: tipo,
      descripcion: descripcion,
      categoria: categoria,
      monto: monto,
    );
  }

  static bool _pareceIngreso(String texto) {
    const palabrasIngreso = [
      'recibí',
      'recibi',
      'me llegó',
      'me llego',
      'ingresó',
      'ingreso',
      'ingreso de',
      'ingresé',
      'me pagaron',
      'me dieron',
      'gané',
      'gane',
      'cobré',
      'cobre',
    ];
    return palabrasIngreso.any(texto.contains);
  }

  static double? _extraerMonto(String texto) {
    // Primero buscamos números acompañados de "mil" o "millón/millones".
    //
    // Ejemplos:
    // "50 millones"  -> 50.000.000
    // "2 millones"   -> 2.000.000
    // "500 mil"      -> 500.000
    // "50 mil"       -> 50.000

    final regexMillones = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*millones?',
    );

    final matchMillones = regexMillones.firstMatch(texto);

    if (matchMillones != null) {
      final numeroTexto = matchMillones.group(1)!;

      final numero = double.tryParse(
        numeroTexto.replaceAll(',', '.'),
      );

      if (numero != null && numero > 0) {
        return numero * 1000000;
      }
    }

    final regexMiles = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*mil\b',
    );

    final matchMiles = regexMiles.firstMatch(texto);

    if (matchMiles != null) {
      final numeroTexto = matchMiles.group(1)!;

      final numero = double.tryParse(
        numeroTexto.replaceAll(',', '.'),
      );

      if (numero != null && numero > 0) {
        return numero * 1000;
      }
    }

    // Números escritos directamente:
    // "50000"
    // "50.000"
    // "1.500.000"
    final regexDigitos = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})+|\d+)',
    );

    final matchDigitos = regexDigitos.firstMatch(texto);

    if (matchDigitos != null) {
      final limpio = matchDigitos
          .group(0)!
          .replaceAll(RegExp(r'[.,]'), '');

      final valor = double.tryParse(limpio);

      if (valor != null && valor > 0) {
        return valor;
      }
    }

    // Finalmente intentamos números escritos en palabras.
    return _extraerMontoEnPalabras(texto);
  }

  static double? _extraerMontoEnPalabras(String texto) {
    const numeros = {
      'cero': 0,
      'un': 1,
      'uno': 1,
      'una': 1,
      'dos': 2,
      'tres': 3,
      'cuatro': 4,
      'cinco': 5,
      'seis': 6,
      'siete': 7,
      'ocho': 8,
      'nueve': 9,
      'diez': 10,
      'once': 11,
      'doce': 12,
      'trece': 13,
      'catorce': 14,
      'quince': 15,
      'dieciséis': 16,
      'dieciseis': 16,
      'diecisiete': 17,
      'dieciocho': 18,
      'diecinueve': 19,
      'veinte': 20,
      'treinta': 30,
      'cuarenta': 40,
      'cincuenta': 50,
      'sesenta': 60,
      'setenta': 70,
      'ochenta': 80,
      'noventa': 90,
      'cien': 100,
      'ciento': 100,
      'doscientos': 200,
      'trescientos': 300,
      'cuatrocientos': 400,
      'quinientos': 500,
      'seiscientos': 600,
      'setecientos': 700,
      'ochocientos': 800,
      'novecientos': 900,
    };

    final palabras = texto
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map(
          (p) => p.replaceAll(
        RegExp(r'[^a-záéíóúñ]'),
        '',
      ),
    )
        .toList();

    double total = 0;
    double grupo = 0;
    bool encontroNumero = false;

    for (final palabra in palabras) {
      if (numeros.containsKey(palabra)) {
        grupo += numeros[palabra]!;
        encontroNumero = true;
        continue;
      }

      if (palabra == 'mil') {
        if (grupo == 0) {
          grupo = 1;
        }

        total += grupo * 1000;
        grupo = 0;
        encontroNumero = true;
        continue;
      }

      if (palabra == 'millón' ||
          palabra == 'millon' ||
          palabra == 'millones') {
        if (grupo == 0) {
          grupo = 1;
        }

        total += grupo * 1000000;
        grupo = 0;
        encontroNumero = true;
        continue;
      }
    }

    total += grupo;

    if (!encontroNumero || total <= 0) {
      return null;
    }

    return total;
  }

  static String _detectarCategoriaIngreso(String texto) {
    if (texto.contains('beca')) return CategoriasIngreso.beca;
    if (texto.contains('mesada')) return CategoriasIngreso.mesada;
    if (texto.contains('trabajo') || texto.contains('sueldo') || texto.contains('salario')) {
      return CategoriasIngreso.trabajo;
    }
    if (texto.contains('negocio') || texto.contains('venta')) {
      return CategoriasIngreso.negocio;
    }
    if (texto.contains('familia') || texto.contains('papá') || texto.contains('papa') || texto.contains('mamá') || texto.contains('mama')) {
      return CategoriasIngreso.ayudaFamiliar;
    }
    return CategoriasIngreso.otro;
  }

  static String _detectarCategoriaEgreso(String texto) {
    if (texto.contains('comida') || texto.contains('almuerzo') || texto.contains('desayuno') || texto.contains('cena') || texto.contains('restaurante')) {
      return CategoriasEgreso.alimentacion;
    }
    if (texto.contains('transporte') || texto.contains('bus') || texto.contains('taxi') || texto.contains('uber') || texto.contains('gasolina') || texto.contains('pasaje')) {
      return CategoriasEgreso.transporte;
    }
    if (texto.contains('cine') || texto.contains('entretenimiento') || texto.contains('salida') || texto.contains('fiesta') || texto.contains('juego')) {
      return CategoriasEgreso.entretenimiento;
    }
    if (texto.contains('salud') || texto.contains('medicamento') || texto.contains('medicina') || texto.contains('doctor') || texto.contains('farmacia')) {
      return CategoriasEgreso.salud;
    }
    if (texto.contains('educación') || texto.contains('educacion') || texto.contains('libro') || texto.contains('matrícula') || texto.contains('matricula') || texto.contains('curso')) {
      return CategoriasEgreso.educacion;
    }
    return CategoriasEgreso.otro;
  }

  static String _generarDescripcion(String categoria, bool esIngreso) {
    if (esIngreso) return categoria;
    return categoria;
  }
}
