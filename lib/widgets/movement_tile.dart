import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/categorias.dart';
import '../models/movimiento.dart';
import '../theme/color_palettes.dart';
import '../utils/currency_formatter.dart';

/// Fila reutilizable para mostrar un movimiento en listados e
/// historial, diferenciando visualmente ingresos (verde, +) de
/// egresos (rojo, -).
class MovementTile extends StatelessWidget {
  final Movimiento movimiento;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MovementTile({
    super.key,
    required this.movimiento,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esIngreso = movimiento.esIngreso;
    final color = esIngreso ? EstadoPresupuestoColors.normal : EstadoPresupuestoColors.critico;
    final signo = esIngreso ? '+' : '-';
    final fechaTexto = DateFormat('d MMM yyyy', 'es').format(movimiento.fecha);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  emojiParaCategoria(movimiento.categoria),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movimiento.descripcion,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${movimiento.categoria} · $fechaTexto',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$signo${CurrencyFormatter.format(movimiento.monto)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: theme.iconTheme.color?.withOpacity(0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
