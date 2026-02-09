// lib/views/fx/widgets/fx_quote_form_dialog.dart
import 'package:flutter/material.dart';

class FxQuoteFormDialog extends StatefulWidget {
  final String title;
  const FxQuoteFormDialog({super.key, required this.title});

  @override
  State<FxQuoteFormDialog> createState() => _FxQuoteFormDialogState();
}

class _FxQuoteFormDialogState extends State<FxQuoteFormDialog> {
  final _sourceCtrl = TextEditingController();
  final _brlCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  DateTime _capturadoEm = DateTime.now();
  DateTime _refMes = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _brlCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCapturedAt() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _capturadoEm,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    if (mounted) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_capturadoEm),
      );
      if (t == null) return;

      setState(() {
        _capturadoEm = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      });
    }
  }

  Future<void> _pickRefMes() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _refMes,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;

    setState(() {
      _refMes = DateTime(d.year, d.month, 1);
    });
  }

  void _submit() {
    final sourceId = int.tryParse(_sourceCtrl.text.trim());
    final brl = double.tryParse(_brlCtrl.text.replaceAll(',', '.'));
    if (sourceId == null || brl == null) return;

    Navigator.pop<Map<String, dynamic>>(context, {
      'sourceId': sourceId,
      'capturadoEm': _capturadoEm,
      'refMes': _refMes,
      'brlPerUsd': brl,
      'observacao': _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final sourceId = int.tryParse(_sourceCtrl.text.trim());
    final brl = double.tryParse(_brlCtrl.text.replaceAll(',', '.'));
    final canSubmit = sourceId != null && brl != null;

    String fmtDt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    String fmtDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _sourceCtrl,
            decoration: const InputDecoration(labelText: 'Source ID (ex: 1)'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Capturado em'),
            subtitle: Text(fmtDt(_capturadoEm)),
            trailing: IconButton(
              onPressed: _pickCapturedAt,
              icon: const Icon(Icons.schedule),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ref Mês'),
            subtitle: Text(fmtDate(_refMes)),
            trailing: IconButton(
              onPressed: _pickRefMes,
              icon: const Icon(Icons.date_range),
            ),
          ),
          TextField(
            controller: _brlCtrl,
            decoration: const InputDecoration(labelText: 'BRL por USD'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _obsCtrl,
            decoration: const InputDecoration(
              labelText: 'Observação (opcional)',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: canSubmit ? _submit : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
