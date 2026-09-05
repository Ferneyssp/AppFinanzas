import 'package:flutter/material.dart';

import '../models/movimiento.dart';
import '../services/voz_service.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';

enum _EstadoVoz {
  inicial,
  escuchando,
  procesando,
  error,
  noSoportado,
}

/// Flujo completo de registro por voz.
class VoiceCaptureScreen extends StatefulWidget {
  const VoiceCaptureScreen({super.key});

  @override
  State<VoiceCaptureScreen> createState() => _VoiceCaptureScreenState();
}

class _VoiceCaptureScreenState extends State<VoiceCaptureScreen>
    with SingleTickerProviderStateMixin {
  final _voz = VozService.instance;

  _EstadoVoz _estado = _EstadoVoz.inicial;
  String _textoReconocido = '';

  late final AnimationController _pulso;

  @override
  void initState() {
    super.initState();

    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _iniciar();
  }

  @override
  void dispose() {
    _pulso.dispose();
    _voz.detener();
    super.dispose();
  }

  Future<void> _iniciar() async {
    if (!mounted) return;

    setState(() {
      _estado = _EstadoVoz.inicial;
      _textoReconocido = '';
    });

    final permisoOk = await _voz.solicitarPermiso();

    if (!mounted) return;

    if (!permisoOk) {
      setState(() {
        _estado = _EstadoVoz.error;
      });
      return;
    }

    final disponible = await _voz.inicializar();

    if (!mounted) return;

    if (!disponible) {
      setState(() {
        _estado = _EstadoVoz.noSoportado;
      });
      return;
    }

    setState(() {
      _estado = _EstadoVoz.escuchando;
      _textoReconocido = '';
    });

    await _voz.escuchar(
      onResultado: (texto) {
        if (!mounted) return;

        setState(() {
          _textoReconocido = texto;
        });
      },
      onFinalizado: _finalizarEscucha,
    );
  }

  Future<void> _finalizarEscucha() async {
    if (!mounted) return;

    // Guardamos una copia del texto antes de cambiar de estado.
    final texto = _textoReconocido.trim();

    // Si el micrófono terminó sin reconocer absolutamente nada,
    // mostramos directamente el mensaje de error.
    if (texto.isEmpty) {
      setState(() {
        _estado = _EstadoVoz.error;
      });
      return;
    }

    setState(() {
      _estado = _EstadoVoz.procesando;
    });

    final resultado = await _voz.procesarFlujoCompleto(texto);

    if (!mounted) return;

    if (resultado.error != null || resultado.movimiento == null) {
      setState(() {
        _estado = _EstadoVoz.error;
      });
      return;
    }

    final movimiento = resultado.movimiento!;

    final prellenado = MovimientoInterpretadoPrellenado(
      descripcion: movimiento.descripcion,
      categoria: movimiento.categoria,
      monto: movimiento.monto,
    );

    if (movimiento.tipo == TipoMovimiento.ingreso) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AddIncomeScreen(
            prellenado: prellenado,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AddExpenseScreen(
            prellenado: prellenado,
          ),
        ),
      );
    }
  }

  Future<void> _volverAIntentar() async {
    await _voz.detener();

    if (!mounted) return;

    setState(() {
      _textoReconocido = '';
      _estado = _EstadoVoz.inicial;
    });

    await _iniciar();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar por voz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // -----------------------------------------
              // ANIMACIÓN DEL MICRÓFONO
              // -----------------------------------------
              if (_estado == _EstadoVoz.escuchando ||
                  _estado == _EstadoVoz.inicial)
                _AnimacionEscuchando(
                  pulso: _pulso,
                ),

              // -----------------------------------------
              // PROCESANDO
              // -----------------------------------------
              if (_estado == _EstadoVoz.procesando)
                const CircularProgressIndicator(),

              // -----------------------------------------
              // ICONO DE ERROR
              // -----------------------------------------
              if (_estado == _EstadoVoz.error)
                Icon(
                  Icons.mic_off_rounded,
                  size: 80,
                  color: theme.colorScheme.error,
                ),

              // -----------------------------------------
              // ICONO NO SOPORTADO
              // -----------------------------------------
              if (_estado == _EstadoVoz.noSoportado)
                Icon(
                  Icons.mic_none_rounded,
                  size: 80,
                  color: theme.colorScheme.error,
                ),

              const SizedBox(height: 24),

              // -----------------------------------------
              // MENSAJE
              // -----------------------------------------
              Text(
                switch (_estado) {
                  _EstadoVoz.inicial =>
                  'Preparando micrófono…',

                  _EstadoVoz.escuchando =>
                  'Escuchando…',

                  _EstadoVoz.procesando =>
                  'Interpretando lo que dijiste…',

                  _EstadoVoz.error =>
                  'No pude reconocer tu voz.',

                  _EstadoVoz.noSoportado =>
                  'El reconocimiento de voz no está disponible en este dispositivo.',
                },
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              // -----------------------------------------
              // TEXTO RECONOCIDO
              // -----------------------------------------
              if (_textoReconocido.isNotEmpty &&
                  _estado != _EstadoVoz.error)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '"$_textoReconocido"',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // -----------------------------------------
              // BOTONES DE ERROR
              // -----------------------------------------
              if (_estado == _EstadoVoz.error) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _volverAIntentar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Volver a intentar'),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Ingresar manualmente'),
                  ),
                ),
              ],

              // -----------------------------------------
              // NO SOPORTADO
              // -----------------------------------------
              if (_estado == _EstadoVoz.noSoportado)
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continuar con formularios'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimacionEscuchando extends StatelessWidget {
  final AnimationController pulso;

  const _AnimacionEscuchando({
    required this.pulso,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: pulso,
      builder: (context, child) {
        final escala = 1 + (pulso.value * 0.25);

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: escala,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        );
      },
    );
  }
}