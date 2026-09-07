import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:finanzas_student/models/movimiento.dart';
import 'package:finanzas_student/utils/currency_formatter.dart';
import 'package:finanzas_student/widgets/movement_tile.dart';

void main() {
  testWidgets('MovementTile muestra datos de ingreso correctamente', (tester) async {
    await initializeDateFormatting('es');

    final movimiento = Movimiento(
      id: 1,
      tipo: TipoMovimiento.ingreso,
      descripcion: 'Beca universitaria',
      categoria: 'Beca',
      monto: 500000,
      fecha: DateTime(2026, 9, 1),
      createdAt: DateTime(2026, 9, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovementTile(
            movimiento: movimiento,
          ),
        ),
      ),
    );

    expect(find.text('Beca universitaria'), findsOneWidget);
    expect(find.text('+${CurrencyFormatter.format(500000)}'), findsOneWidget);
  });
}
