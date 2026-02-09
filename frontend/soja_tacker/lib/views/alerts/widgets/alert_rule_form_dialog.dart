// lib/views/alerts/widgets/alert_rule_form_dialog.dart
import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../data/models/alerts/alert_rule_create.dart';
import '../../../data/models/alerts/alert_rule_read.dart';
import '../../../data/models/alerts/alert_rule_update.dart';

class AlertRuleFormResult {
  final AlertRuleCreate? create;
  final AlertRuleUpdate? update;

  const AlertRuleFormResult._({this.create, this.update});

  factory AlertRuleFormResult.create(AlertRuleCreate c) => AlertRuleFormResult._(create: c);
  factory AlertRuleFormResult.update(AlertRuleUpdate u) => AlertRuleFormResult._(update: u);
}

class AlertRuleFormDialog extends StatefulWidget {
  final AlertRuleRead? initial; // se vier, é edição
  const AlertRuleFormDialog({super.key, this.initial});

  @override
  State<AlertRuleFormDialog> createState() => _AlertRuleFormDialogState();
}

class _AlertRuleFormDialogState extends State<AlertRuleFormDialog> {
  final _nomeCtrl = TextEditingController();
  final _tipoCtrl = TextEditingController();
  final _paramsCtrl = TextEditingController();
  bool _ativo = true;

  bool get isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _nomeCtrl.text = i.nome;
      _tipoCtrl.text = i.tipo;
      _paramsCtrl.text = i.paramsJson; // já vem string JSON
      _ativo = i.ativo;
    } else {
      _paramsCtrl.text = '{}';
      _ativo = true;
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _tipoCtrl.dispose();
    _paramsCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _parseParamsOrNull(String raw) {
    final txt = raw.trim();
    if (txt.isEmpty) return null;
    try {
      final decoded = jsonDecode(txt);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
      return null;
    } catch (_) {
      return null;
    }
  }

  void _submit() {
    final nome = _nomeCtrl.text.trim();
    final tipo = _tipoCtrl.text.trim();
    final params = _parseParamsOrNull(_paramsCtrl.text);

    if (nome.isEmpty || tipo.isEmpty) return;

    if (!isEdit) {
      Navigator.pop(
        context,
        AlertRuleFormResult.create(
          AlertRuleCreate(nome: nome, tipo: tipo, params: params, ativo: _ativo),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      AlertRuleFormResult.update(
        AlertRuleUpdate(nome: nome, tipo: tipo, params: params, ativo: _ativo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final can = _nomeCtrl.text.trim().isNotEmpty && _tipoCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text(isEdit ? 'Editar regra' : 'Nova regra'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tipoCtrl,
              decoration: const InputDecoration(labelText: 'Tipo'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _ativo,
              onChanged: (v) => setState(() => _ativo = v),
              title: const Text('Ativo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _paramsCtrl,
              decoration: const InputDecoration(
                labelText: 'Params (JSON)',
                hintText: '{"threshold": 0.1, "symbol":"ZS=F"}',
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 8),
            const Text(
              'Dica: deixe {} se não precisar de params.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: can ? _submit : null, child: const Text('Salvar')),
      ],
    );
  }
}
