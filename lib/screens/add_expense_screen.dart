import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/categorias.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/validators.dart';
import 'add_income_screen.dart' show MovimientoInterpretadoPrellenado;

/// Formulario de registro de egresos. Aplica en tiempo real la regla de
/// negocio "los egresos no pueden superar los ingresos": el botón de
/// guardar se deshabilita apenas el monto ingresado supera el saldo
/// disponible, y además se vuelve a validar justo antes de persistir.
class AddExpenseScreen extends StatefulWidget {
  final MovimientoInterpretadoPrellenado? prellenado;

  const AddExpenseScreen({super.key, this.prellenado});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _montoCtrl;
  String _categoria = CategoriasEgreso.otro;
  DateTime _fecha = DateTime.now();
  bool _guardando = false;
  String? _errorSaldo;

  @override
  void initState() {
    super.initState();
    final pre = widget.prellenado;
    _descripcionCtrl = TextEditingController(text: pre?.descripcion ?? '');
    _montoCtrl = TextEditingController(text: pre != null ? pre.monto.round().toString() : '');
    if (pre != null && CategoriasEgreso.todas.contains(pre.categoria)) {
      _categoria = pre.categoria;
    }
    _montoCtrl.addListener(_revisarSaldoEnVivo);
  }

  @override
  void dispose() {
    _montoCtrl.removeListener(_revisarSaldoEnVivo);
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  void _revisarSaldoEnVivo() {
    final finanzas = context.read<FinanceProvider>();
    final monto = CurrencyFormatter.parse(_montoCtrl.text);
    if (monto == null) {
      if (_errorSaldo != null) setState(() => _errorSaldo = null);
      return;
    }
    final saldo = finanzas.saldoDisponible;
    if (monto > saldo) {
      setState(() {
        _errorSaldo = 'Saldo disponible: ${CurrencyFormatter.format(saldo)}. '
            'Monto máximo permitido: ${CurrencyFormatter.format(saldo)}.';
      });
    } else if (_errorSaldo != null) {
      setState(() => _errorSaldo = null);
    }
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
    final resultado = await finanzas.intentarAgregarEgreso(
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
          title: const Text('No puedes registrar este gasto'),
          content: Text('${resultado.mensajePrincipal}\n\n${resultado.mensajeSecundario}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Egreso registrado correctamente.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final finanzas = context.watch<FinanceProvider>();
    final montoActual = CurrencyFormatter.parse(_montoCtrl.text);
    final excedeSaldo = montoActual != null && montoActual > finanzas.saldoDisponible;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar egreso')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Saldo disponible: ${CurrencyFormatter.format(finanzas.saldoDisponible)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej. Almuerzo, Bus universitario',
              ),
              validator: Validators.descripcionRequerida,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: CategoriasEgreso.todas
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v ?? _categoria),
              validator: Validators.categoriaRequerida,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoCtrl,
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                errorText: _errorSaldo,
                errorMaxLines: 3,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              validator: (v) {
                final base = Validators.montoRequerido(v);
                if (base != null) return base;
                if (_errorSaldo != null) return _errorSaldo;
                return null;
              },
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
              onPressed: (_guardando || excedeSaldo) ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: excedeSaldo ? Colors.grey : null,
              ),
              child: _guardando
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(excedeSaldo ? 'Supera tu saldo disponible' : 'Guardar egreso'),
            ),
          ],
        ),
      ),
    );
  }
}
