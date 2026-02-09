// lib/views/rates/widgets/offset_form_dialog.dart
import 'package:flutter/material.dart';

class OffsetFormDialog extends StatefulWidget {
  final String title;

  const OffsetFormDialog({super.key, required this.title});

  @override
  State<OffsetFormDialog> createState() => _OffsetFormDialogState();
}

class _OffsetFormDialogState extends State<OffsetFormDialog> {
  final _valueCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _valueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = double.tryParse(_valueCtrl.text.replaceAll(',', '.'));
    if (v == null) return;

    Navigator.pop<Map<String, dynamic>>(context, {
      'offsetValue': v,
      'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = double.tryParse(_valueCtrl.text.replaceAll(',', '.'));
    final canSubmit = v != null;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _valueCtrl,
            decoration: const InputDecoration(labelText: 'Offset'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Nota (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: canSubmit ? _submit : null, child: const Text('Salvar')),
      ],
    );
  }
}
