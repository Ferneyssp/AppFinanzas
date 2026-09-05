import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/balance_card.dart';
import '../widgets/budget_status_card.dart';
import '../widgets/movement_tile.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'income_list_screen.dart';
import 'movements_screen.dart';
import 'voice_capture_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finanzas = context.watch<FinanceProvider>();
    final settings = context.watch<SettingsProvider>();

    if (finanzas.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${settings.alias} 👋'),
        actions: [
          IconButton(
            tooltip: 'Ver ingresos del mes',
            icon: const Icon(Icons.savings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IncomeListScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Registrar por voz',
            icon: const Icon(Icons.mic_none_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VoiceCaptureScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: finanzas.cargar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              '${settings.nombreMesMostrado()} ${settings.emojiMes}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo disponible', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.format(finanzas.saldoDisponible),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    titulo: 'Total ingresos',
                    valor: finanzas.totalIngresos,
                    icono: Icons.trending_up_rounded,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    titulo: 'Total gastado',
                    valor: finanzas.totalEgresos,
                    icono: Icons.trending_down_rounded,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BudgetStatusCard(
              nivel: finanzas.nivelAlerta,
              porcentajeDisponible: finanzas.porcentajeDisponible,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Ingreso'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                    ),
                    icon: const Icon(Icons.remove),
                    label: const Text('Egreso'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Movimientos recientes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MovementsScreen()),
                  ),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (finanzas.recientes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Aún no tienes movimientos registrados.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...finanzas.recientes.map((m) => MovementTile(movimiento: m)),
          ],
        ),
      ),
    );
  }
}
