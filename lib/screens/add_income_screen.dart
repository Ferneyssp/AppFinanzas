import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/categorias.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/validators.dart';

/// Formulario de registro de ingresos. Puede prellenarse con datos
/// interpretados por voz mediante [prellenado].
class AddIncomeScreen extends StatefulWidget {
  final MovimientoInterpretadoPrellenado? prellenado;

  const AddIncomeScreen({super.key, this.prellenado});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

/// Estructura simple para pasar datos prellenados desde el flujo de voz
/// sin acoplar esta pantalla al servicio de voz directamente.
class MovimientoInterpretadoPrellenado {
  final String descripcion;
  final String categoria;
  final double monto;

  const MovimientoInterpretadoPrellenado({
    required this.descripcion,
    required this.categoria,
    required this.monto,
  });
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _montoCtrl;
  String _categoria = CategoriasIngreso.otro;
  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final pre = widget.prellenado;
    _descripcionCtrl = TextEditingController(text: pre?.descripcion ?? '');
    _montoCtrl = TextEditingController(text: pre != null ? pre.monto.round().toString() : '');
    if (pre != null && CategoriasIngreso.todas.contains(pre.categoria)) {
      _categoria = pre.categoria;
    }
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
    );
    if (seleccionada != null) setState(() => _fecha = seleccionada);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final monto = CurrencyFormatter.parse(_montoCtrl.text)!;
    final finanzas = context.read<FinanceProvider>();
    await finanzas.agregarIngreso(
      descripcion: _descripcionCtrl.text.trim(),
      categoria: _categoria,
      monto: monto,
      fecha: _fecha,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Ingreso registrado correctamente.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ingreso')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej. Mesada, Beca universitaria',
              ),
              validator: Validators.descripcionRequerida,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: CategoriasIngreso.todas
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v ?? _categoria),
              validator: Validators.categoriaRequerida,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoCtrl,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              validator: Validators.montoRequerido,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _seleccionarFecha,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Fecha'),
                child: Text('${_fecha.day}/${_fecha.month}/${_fecha.year}'),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar ingreso'),
            ),
          ],
        ),
      ),
    );
  }
}
