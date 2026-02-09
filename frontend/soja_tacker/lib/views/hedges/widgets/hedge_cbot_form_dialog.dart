import 'package:flutter/material.dart';
import '../../../data/models/hedges/hedge_cbot_create.dart';

class HedgeCbotFormDialog extends StatefulWidget {
  const HedgeCbotFormDialog({super.key});

  @override
  State<HedgeCbotFormDialog> createState() => _HedgeCbotFormDialogState();
}

class _HedgeCbotFormDialogState extends State<HedgeCbotFormDialog> {
  final _volInputCtrl = TextEditingController();
  String _volUnit = 'SACA'; // ✅ SACA | TON (compatível com back)
  final _volTonCtrl = TextEditingController();

  final _cbotCtrl = TextEditingController();
  final _symbolCtrl = TextEditingController(text: 'ZS=F');
  final _obsCtrl = TextEditingController();

  DateTime _executadoEm = DateTime.now();
  DateTime? _refMes;

  @override
  void dispose() {
    _volInputCtrl.dispose();
    _volTonCtrl.dispose();
    _cbotCtrl.dispose();
    _symbolCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  double? _parseNum(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  Future<void> _pickExec() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _executadoEm,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      _executadoEm = DateTime(
        d.year,
        d.month,
        d.day,
        _executadoEm.hour,
        _executadoEm.minute,
      );
    });
  }

  Future<void> _pickRefMes() async {
    final initial = _refMes ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => _refMes = DateTime(d.year, d.month, 1));
  }

  void _submit() {
    final volInput = _parseNum(_volInputCtrl);
    final volTon = _parseNum(_volTonCtrl);
    final cbot = _parseNum(_cbotCtrl);

    if (volInput == null || volTon == null || cbot == null) return;

    final payload = HedgeCbotCreate(
      executadoEm: _executadoEm,
      volumeInputValue: volInput,
      volumeInputUnit: _volUnit, // ✅ TON ou SACA
      volumeTon: volTon,
      cbotUsdPerBu: cbot,
      refMes: _refMes,
      symbol: _symbolCtrl.text.trim().isEmpty ? null : _symbolCtrl.text.trim(),
      observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final volInput = _parseNum(_volInputCtrl);
    final volTon = _parseNum(_volTonCtrl);
    final cbot = _parseNum(_cbotCtrl);

    final can =
        (volInput != null && volInput > 0) &&
        (volTon != null && volTon > 0) &&
        (cbot != null && cbot > 0);

    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: const Text('Novo hedge CBOT'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _volInputCtrl,
                    decoration: InputDecoration(
                      labelText: 'Volume input',
                      helperText: _volUnit == 'SACA'
                          ? 'Ex: 1000 sacas'
                          : 'Ex: 50 ton',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _volUnit,
                    items: const [
                      DropdownMenuItem(value: 'SACA', child: Text('SACA')),
                      DropdownMenuItem(value: 'TON', child: Text('TON')),
                    ],
                    onChanged: (v) => setState(() => _volUnit = v ?? 'SACA'),
                    decoration: const InputDecoration(labelText: 'Unidade'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _volTonCtrl,
              decoration: const InputDecoration(labelText: 'Volume (ton)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cbotCtrl,
              decoration: const InputDecoration(labelText: 'CBOT (USD/bu)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _symbolCtrl,
              decoration: const InputDecoration(labelText: 'Symbol (opcional)'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Executado em'),
              subtitle: Text(fmt(_executadoEm)),
              trailing: IconButton(
                onPressed: _pickExec,
                icon: const Icon(Icons.date_range),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ref mês (opcional)'),
              subtitle: Text(_refMes == null ? '—' : fmt(_refMes!)),
              trailing: IconButton(
                onPressed: _pickRefMes,
                icon: const Icon(Icons.calendar_month),
              ),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: can ? _submit : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
