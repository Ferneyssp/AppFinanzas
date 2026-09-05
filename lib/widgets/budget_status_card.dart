import 'package:flutter/material.dart';

import '../services/finance_calculator.dart';
import '../theme/color_palettes.dart';

/// Componente reutilizable que traduce un [NivelAlerta] en una tarjeta
/// visual consistente: color, ícono, título, mensaje y barra de
/// progreso del presupuesto utilizado.
class BudgetStatusCard extends StatelessWidget {
  final NivelAlerta nivel;
  final double? porcentajeDisponible;

  const BudgetStatusCard({
    super.key,
    required this.nivel,
    required this.porcentajeDisponible,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (nivel == NivelAlerta.sinIngresos) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: EstadoPresupuestoColors.neutro),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Aún no has registrado ingresos este mes. Registra tu '
                  'primer ingreso para empezar a controlar tu presupuesto.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final (color, titulo, mensaje, icono) = switch (nivel) {
      NivelAlerta.critico => (
          EstadoPresupuestoColors.critico,
          '🚨 CRÍTICO',
          'Tu presupuesto está casi agotado. Solo tienes disponible el '
              '${porcentajeDisponible!.toStringAsFixed(0)}% de tus ingresos.',
          Icons.error_rounded,
        ),
      NivelAlerta.precaucion => (
          EstadoPresupuestoColors.precaucion,
          '⚠️ PRECAUCIÓN',
          'Has utilizado gran parte de tu presupuesto mensual. Te queda el '
              '${porcentajeDisponible!.toStringAsFixed(0)}% de tus ingresos.',
          Icons.warning_rounded,
        ),
      _ => (
          EstadoPresupuestoColors.normal,
          'Presupuesto saludable',
          'Vas muy bien. Te queda el '
              '${porcentajeDisponible!.toStringAsFixed(0)}% de tus ingresos.',
          Icons.check_circle_rounded,
        ),
    };

    final progreso = (100 - porcentajeDisponible!.clamp(0, 100)) / 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: color),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${porcentajeDisponible!.toStringAsFixed(1)}% disponible',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progreso.toDouble(),
                minHeight: 10,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 12),
            Text(mensaje, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
