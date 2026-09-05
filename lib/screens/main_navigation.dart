import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'movements_screen.dart';
import 'settings_screen.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';

/// Contenedor de navegación principal con barra inferior: Inicio,
/// Movimientos, Agregar (acción rápida) y Ajustes.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _indiceActual = 0;

  final _pantallas = const [
    DashboardScreen(),
    MovementsScreen(),
    SizedBox.shrink(), // "Agregar" abre una hoja modal, no una pantalla fija.
    SettingsScreen(),
  ];

  Future<void> _abrirAgregar() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _HojaAgregar(
        onIngreso: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
          );
        },
        onEgreso: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indiceActual == 2 ? 0 : _indiceActual,
        children: _pantallas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual == 2 ? 0 : _indiceActual,
        onDestinationSelected: (i) {
          if (i == 2) {
            _abrirAgregar();
            return;
          }
          setState(() => _indiceActual = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Movimientos'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Agregar'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}

class _HojaAgregar extends StatelessWidget {
  final VoidCallback onIngreso;
  final VoidCallback onEgreso;

  const _HojaAgregar({required this.onIngreso, required this.onEgreso});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Qué quieres registrar?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OpcionAgregar(
                    icono: Icons.arrow_downward_rounded,
                    color: Colors.green,
                    titulo: 'Ingreso',
                    onTap: onIngreso,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OpcionAgregar(
                    icono: Icons.arrow_upward_rounded,
                    color: Colors.red,
                    titulo: 'Egreso',
                    onTap: onEgreso,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionAgregar extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final VoidCallback onTap;

  const _OpcionAgregar({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 28),
            const SizedBox(height: 8),
            Text(titulo, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
