import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movimiento.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/movement_tile.dart';

/// Pantalla dedicada a consultar los ingresos del mes activo,
/// permitiendo ordenar por fecha y mostrando el total acumulado.
class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  bool _masRecientePrimero = true;

  @override
  Widget build(BuildContext context) {
    final finanzas = context.watch<FinanceProvider>();
    final ingresos = List<Movimiento>.from(finanzas.ingresosDelMes)
      ..sort((a, b) => _masRecientePrimero
          ? b.fecha.compareTo(a.fecha)
          : a.fecha.compareTo(b.fecha));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos del mes'),
        actions: [
          IconButton(
            tooltip: 'Cambiar orden',
            icon: Icon(_masRecientePrimero ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () => setState(() => _masRecientePrimero = !_masRecientePrimero),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total ingresos del mes'),
                    Text(
                      CurrencyFormatter.format(finanzas.totalIngresos),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ingresos.isEmpty
                ? Center(
                    child: Text('Aún no registras ingresos este mes.', style: Theme.of(context).textTheme.bodyMedium),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ingresos.length,
                    itemBuilder: (context, index) => MovementTile(movimiento: ingresos[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
