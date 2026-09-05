import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../services/preferencias_service.dart';
import '../theme/color_palettes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Seccion(
            titulo: 'Perfil',
            child: _CampoAlias(aliasActual: settings.alias),
          ),
          const SizedBox(height: 20),
          _Seccion(
            titulo: 'Mes activo',
            child: _CampoMes(settings: settings),
          ),
          const SizedBox(height: 20),
          _Seccion(
            titulo: 'Tema',
            child: Row(
              children: [
                Expanded(
                  child: _OpcionTema(
                    label: '☀️ Claro',
                    seleccionado: settings.tema == ModoTema.claro,
                    onTap: () => settings.cambiarTema(ModoTema.claro),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OpcionTema(
                    label: '🌙 Oscuro',
                    seleccionado: settings.tema == ModoTema.oscuro,
                    onTap: () => settings.cambiarTema(ModoTema.oscuro),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Seccion(
            titulo: 'Paleta de colores',
            child: Row(
              children: PaletaColor.values.map((paleta) {
                final colores = paletteDefinitions[paleta]!;
                final seleccionado = settings.paleta == paleta;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => settings.cambiarPaleta(paleta),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: colores.primario.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: seleccionado ? colores.primario : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(radius: 14, backgroundColor: colores.primario),
                            const SizedBox(height: 6),
                            Text(
                              paleta.name[0].toUpperCase() + paleta.name.substring(1),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          _Seccion(
            titulo: 'Datos',
            child: Column(
              children: [
                _BotonDatosDemo(),
                const SizedBox(height: 12),
                _BotonEliminarTodo(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Finanzas Student · v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _Seccion({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: child)),
      ],
    );
  }
}

class _CampoAlias extends StatefulWidget {
  final String aliasActual;
  const _CampoAlias({required this.aliasActual});

  @override
  State<_CampoAlias> createState() => _CampoAliasState();
}

class _CampoAliasState extends State<_CampoAlias> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.aliasActual);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      decoration: InputDecoration(
        labelText: 'Nombre o alias',
        suffixIcon: IconButton(
          icon: const Icon(Icons.check),
          onPressed: () async {
            await context.read<SettingsProvider>().cambiarAlias(_ctrl.text);

            if (!context.mounted) return;

            FocusScope.of(context).unfocus();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Alias actualizado.'),
              ),
            );
          },
        ),
      ),
      onSubmitted: (v) => context.read<SettingsProvider>().cambiarAlias(v),
    );
  }
}

class _CampoMes extends StatefulWidget {
  final SettingsProvider settings;
  const _CampoMes({required this.settings});

  @override
  State<_CampoMes> createState() => _CampoMesState();
}

class _CampoMesState extends State<_CampoMes> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _emojiCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.settings.nombreMesMostrado());
    _emojiCtrl = TextEditingController(text: widget.settings.emojiMes);
  }

  void _guardar() {
    widget.settings.cambiarNombreMes(_nombreCtrl.text);
    widget.settings.cambiarEmojiMes(_emojiCtrl.text);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Mes activo actualizado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del mes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _emojiCtrl,
                decoration: const InputDecoration(labelText: 'Emoji'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(onPressed: _guardar, child: const Text('Guardar')),
        ),
      ],
    );
  }
}

class _OpcionTema extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionTema({required this.label, required this.seleccionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.12) : Colors.transparent,
          border: Border.all(color: seleccionado ? color : Colors.black12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
      ),
    );
  }
}

class _BotonDatosDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Cargar datos de demostración'),
        onPressed: () async {
          final finanzas = context.read<FinanceProvider>();
          await finanzas.cargarDatosDemo();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✓ Datos de demostración agregados.')),
            );
          }
        },
      ),
    );
  }
}

class _BotonEliminarTodo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: EstadoPresupuestoColors.critico,
          side: const BorderSide(color: EstadoPresupuestoColors.critico),
        ),
        icon: const Icon(Icons.delete_forever_outlined),
        label: const Text('Eliminar todos los movimientos'),
        onPressed: () async {
          final confirmar = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('¿Eliminar todos los movimientos?'),
              content: const Text('Esta acción no se puede deshacer.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
              ],
            ),
          );
          if (confirmar == true) {
            await context.read<FinanceProvider>().eliminarTodosLosDatos();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Todos los movimientos fueron eliminados.')),
              );
            }
          }
        },
      ),
    );
  }
}
