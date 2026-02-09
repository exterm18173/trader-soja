// lib/views/expenses/widgets/expense_usd_form_dialog.dart
import 'package:flutter/material.dart';
import '../../../data/models/expenses/expense_usd_create.dart';
import '../../../data/models/expenses/expense_usd_read.dart';
import '../../../data/models/expenses/expense_usd_update.dart';

class ExpenseUsdFormResult {
  final ExpenseUsdCreate? create;
  final ExpenseUsdUpdate? update;

  const ExpenseUsdFormResult._({this.create, this.update});

  factory ExpenseUsdFormResult.create(ExpenseUsdCreate c) => ExpenseUsdFormResult._(create: c);
  factory ExpenseUsdFormResult.update(ExpenseUsdUpdate u) => ExpenseUsdFormResult._(update: u);
}

class ExpenseUsdFormDialog extends StatefulWidget {
  final ExpenseUsdRead? initial; // se vier, é edição
  const ExpenseUsdFormDialog({super.key, this.initial});

  @override
  State<ExpenseUsdFormDialog> createState() => _ExpenseUsdFormDialogState();
}

class _ExpenseUsdFormDialogState extends State<ExpenseUsdFormDialog> {
  late DateTime _competenciaMes;
  final _valorCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();

  bool get isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _competenciaMes = i?.competenciaMes ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    _valorCtrl.text = i == null ? '' : i.valorUsd.toStringAsFixed(2);
    _categoriaCtrl.text = i?.categoria ?? '';
    _descricaoCtrl.text = i?.descricao ?? '';
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _categoriaCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickMes() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _competenciaMes,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => _competenciaMes = DateTime(d.year, d.month, 1));
  }

  void _submit() {
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.'));
    if (valor == null || valor <= 0) return;

    final cat = _categoriaCtrl.text.trim();
    final desc = _descricaoCtrl.text.trim();

    if (!isEdit) {
      final payload = ExpenseUsdCreate(
        competenciaMes: _competenciaMes,
        valorUsd: valor,
        categoria: cat.isEmpty ? null : cat,
        descricao: desc.isEmpty ? null : desc,
      );
      Navigator.pop(context, ExpenseUsdFormResult.create(payload));
      return;
    }

    // update (manda campos que o usuário preencheu)
    final payload = ExpenseUsdUpdate(
      competenciaMes: _competenciaMes,
      valorUsd: valor,
      categoria: cat.isEmpty ? null : cat,
      descricao: desc.isEmpty ? null : desc,
    );
    Navigator.pop(context, ExpenseUsdFormResult.update(payload));
  }

  @override
  Widget build(BuildContext context) {
    final valorOk = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar despesa USD' : 'Nova despesa USD'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Competência (mês)'),
              subtitle: Text(_fmt(_competenciaMes)),
              trailing: IconButton(onPressed: _pickMes, icon: const Icon(Icons.calendar_month)),
            ),
            TextField(
              controller: _valorCtrl,
              decoration: const InputDecoration(labelText: 'Valor (USD)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _categoriaCtrl,
              decoration: const InputDecoration(labelText: 'Categoria (opcional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descricaoCtrl,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: valorOk ? _submit : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
