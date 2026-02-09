// lib/views/farms/widgets/farm_form_dialog.dart
import 'package:flutter/material.dart';

class FarmFormDialog extends StatefulWidget {
  final String title;
  final String? initialNome;
  final bool showAtivo;
  final bool? initialAtivo;

  const FarmFormDialog({
    super.key,
    required this.title,
    this.initialNome,
    this.showAtivo = false,
    this.initialAtivo,
  });

  @override
  State<FarmFormDialog> createState() => _FarmFormDialogState();
}

class _FarmFormDialogState extends State<FarmFormDialog> {
  final _nomeCtrl = TextEditingController();
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _nomeCtrl.text = widget.initialNome ?? '';
    _ativo = widget.initialAtivo ?? true;
  }

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
      if (widget.showAtivo) 'ativo': _ativo,
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _nomeCtrl.text.trim().length >= 2;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nomeCtrl,
            decoration: const InputDecoration(labelText: 'Nome da fazenda'),
            onChanged: (_) => setState(() {}),
          ),
          if (widget.showAtivo) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              value: _ativo,
              onChanged: (v) => setState(() => _ativo = v),
              title: const Text('Ativa'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
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
