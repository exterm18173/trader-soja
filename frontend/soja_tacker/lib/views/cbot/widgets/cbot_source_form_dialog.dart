// lib/views/cbot/widgets/cbot_source_form_dialog.dart
import 'package:flutter/material.dart';

class CbotSourceFormDialog extends StatefulWidget {
  final String title;
  const CbotSourceFormDialog({super.key, required this.title});

  @override
  State<CbotSourceFormDialog> createState() => _CbotSourceFormDialogState();
}

class _CbotSourceFormDialogState extends State<CbotSourceFormDialog> {
  final _nomeCtrl = TextEditingController();
  bool _ativo = true;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final nome = _nomeCtrl.text.trim();
    if (nome.length < 2) return;

    Navigator.pop<Map<String, dynamic>>(context, {
      'nome': nome,
      'ativo': _ativo,
    });
  }

  @override
  Widget build(BuildContext context) {
    final nomeOk = _nomeCtrl.text.trim().length >= 2;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nomeCtrl,
            decoration: const InputDecoration(labelText: 'Nome'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _ativo,
            onChanged: (v) => setState(() => _ativo = v),
            title: const Text('Ativo'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: nomeOk ? _submit : null, child: const Text('Salvar')),
      ],
    );
  }
}
