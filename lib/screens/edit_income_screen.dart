import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/categorias.dart';
import '../models/movimiento.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/validators.dart';

/// Permite editar descripción, categoría, monto y fecha de un ingreso
/// existente, validando que el total de ingresos no sea menor al total
/// de gastos acumulados en el mes activo.
class EditIncomeScreen extends StatefulWidget {
  final Movimiento movimiento;

  const EditIncomeScreen({super.key, required this.movimiento});

  @override
  State<EditIncomeScreen> createState() => _EditIncomeScreenState();
}

class _EditIncomeScreenState extends State<EditIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _montoCtrl;
  late String _categoria;
  late DateTime _fecha;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final m = widget.movimiento;
    _descripcionCtrl = TextEditingController(text: m.descripcion);
    _montoCtrl = TextEditingController(text: m.monto.round().toString());
    _categoria = CategoriasIngreso.todas.contains(m.categoria)
        ? m.categoria
        : CategoriasIngreso.otro;
    _fecha = m.fecha;
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
    final monto = CurrencyFormatter.parse(_montoCtrl.text)!;
    setState(() => _guardando = true);
    final finanzas = context.read<FinanceProvider>();
    final resultado = await finanzas.intentarActualizarIngreso(
      original: widget.movimiento,
      descripcion: _descripcionCtrl.text.trim(),
      categoria: _categoria,
      monto: monto,
      fecha: _fecha,
    );
    if (!mounted) return;
    setState(() => _guardando = false);

    if (!resultado.esValido) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No se puede actualizar'),
          content: Text(
            '${resultado.mensajePrincipal}\n\n${resultado.mensajeSecundario}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Ingreso actualizado correctamente.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar ingreso')),
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
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
