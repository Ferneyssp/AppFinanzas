import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_student/services/finance_calculator.dart';

void main() {
  group('FinanceCalculator - Validaciones de Ingreso', () {
    test('Permite actualizar ingreso si totalIngresos >= totalEgresos', () {
      // Ingresos actuales = 1.000.000 (un ingreso de 400.000 y otros por 600.000)
      // Egresos actuales = 700.000
      // Editamos el ingreso de 400.000 para que ahora sea 200.000
      // Nuevo total ingresos = 600.000 + 200.000 = 800.000 >= 700.000 -> VÁLIDO
      final resultado = FinanceCalculator.validarActualizacionIngreso(
        totalIngresosActuales: 1000000,
        totalEgresos: 700000,
        montoIngresoOriginal: 400000,
        nuevoMonto: 200000,
      );

      expect(resultado.esValido, isTrue);
      expect(resultado.mensajePrincipal, isNull);
    });

    test('Rechaza actualizar ingreso si totalIngresos quedaría menor a totalEgresos', () {
      // Ingresos actuales = 1.000.000 (un ingreso de 400.000 y otros por 600.000)
      // Egresos actuales = 700.000
      // Editamos el ingreso de 400.000 para que ahora sea 50.000
      // Nuevo total ingresos = 600.000 + 50.000 = 650.000 < 700.000 -> INVÁLIDO
      final resultado = FinanceCalculator.validarActualizacionIngreso(
        totalIngresosActuales: 1000000,
        totalEgresos: 700000,
        montoIngresoOriginal: 400000,
        nuevoMonto: 50000,
      );

      expect(resultado.esValido, isFalse);
      expect(resultado.mensajePrincipal, contains('No puedes actualizar este ingreso'));
      expect(resultado.mensajeSecundario, contains('Monto mínimo requerido'));
    });

    test('Rechaza eliminar ingreso si totalIngresos quedaría menor a totalEgresos', () {
      // Ingresos actuales = 800.000
      // Egresos actuales = 600.000
      // Intentamos eliminar un ingreso de 300.000
      // Nuevo total ingresos = 500.000 < 600.000 -> INVÁLIDO
      final resultado = FinanceCalculator.validarEliminacionIngreso(
        totalIngresosActuales: 800000,
        totalEgresos: 600000,
        montoIngresoEliminado: 300000,
      );

      expect(resultado.esValido, isFalse);
      expect(resultado.mensajePrincipal, contains('No puedes eliminar este ingreso'));
    });

    test('Permite eliminar ingreso si totalIngresos se mantiene >= totalEgresos', () {
      // Ingresos actuales = 1.000.000
      // Egresos actuales = 400.000
      // Intentamos eliminar un ingreso de 200.000
      // Nuevo total ingresos = 800.000 >= 400.000 -> VÁLIDO
      final resultado = FinanceCalculator.validarEliminacionIngreso(
        totalIngresosActuales: 1000000,
        totalEgresos: 400000,
        montoIngresoEliminado: 200000,
      );

      expect(resultado.esValido, isTrue);
    });
  });
}
