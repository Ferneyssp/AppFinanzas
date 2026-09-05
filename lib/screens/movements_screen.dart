import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/categorias.dart';
import '../models/movimiento.dart';
import '../providers/finance_provider.dart';
import '../widgets/movement_tile.dart';
import 'edit_expense_screen.dart';

/// Historial completo de movimientos (ingresos y egresos) con filtros
/// opcionales por tipo, categoría y fecha. El más reciente aparece
/// primero.
class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  TipoMovimiento? _filtroTipo;
  String? _filtroCategoria;
  DateTime? _filtroFecha;

  List<Movimiento> _aplicarFiltros(List<Movimiento> movimientos) {
    return movimientos.where((m) {
      if (_filtroTipo != null && m.tipo != _filtroTipo) return false;
      if (_filtroCategoria != null && m.categoria != _filtroCategoria) return false;
      if (_filtroFecha != null &&
          !(m.fecha.year == _filtroFecha!.year &&
            m.fecha.month == _filtroFecha!.month &&
            m.fecha.day == _filtroFecha!.day)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<void> _confirmarEliminar(BuildContext context, Movimiento m) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar este movimiento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true && m.id != null) {
      await context.read<FinanceProvider>().eliminarMovimiento(m.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movimiento eliminado.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final finanzas = context.watch<FinanceProvider>();
    final movimientos = _aplicarFiltros(finanzas.todos);
    final categoriasDisponibles = {
      ...CategoriasIngreso.todas,
      ...CategoriasEgreso.todas,
    }.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FiltroChip(
                    label: 'Todos',
                    seleccionado: _filtroTipo == null,
                    onTap: () => setState(() => _filtroTipo = null),
                  ),
                  _FiltroChip(
                    label: 'Ingresos',
                    seleccionado: _filtroTipo == TipoMovimiento.ingreso,
                    onTap: () => setState(() => _filtroTipo = TipoMovimiento.ingreso),
                  ),
                  _FiltroChip(
                    label: 'Egresos',
                    seleccionado: _filtroTipo == TipoMovimiento.egreso,
                    onTap: () => setState(() => _filtroTipo = TipoMovimiento.egreso),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String?>(
                    value: _filtroCategoria,
                    hint: const Text('Categoría'),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ...categoriasDisponibles.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (v) => setState(() => _filtroCategoria = v),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_filtroFecha == null
                        ? 'Fecha'
                        : '${_filtroFecha!.day}/${_filtroFecha!.month}/${_filtroFecha!.year}'),
                    onPressed: () async {
                      final seleccionada = await showDatePicker(
                        context: context,
                        initialDate: _filtroFecha ?? DateTime.now(),
                        firstDate: DateTime(DateTime.now().year - 2),
                        lastDate: DateTime.now(),
                      );
                      setState(() => _filtroFecha = seleccionada);
                    },
                  ),
                  if (_filtroFecha != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _filtroFecha = null),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: movimientos.isEmpty
                ? Center(
                    child: Text(
                      'No hay movimientos con estos filtros.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: movimientos.length,
                    itemBuilder: (context, index) {
                      final m = movimientos[index];
                      return MovementTile(
                        movimiento: m,
                        onTap: m.esEgreso
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => EditExpenseScreen(movimiento: m)),
                                )
                            : null,
                        onDelete: () => _confirmarEliminar(context, m),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  const _FiltroChip({required this.label, required this.seleccionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: seleccionado,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
