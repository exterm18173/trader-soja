import 'package:flutter/material.dart';
import '../../../data/models/hedges/hedge_premium_create.dart';

class HedgePremiumFormDialog extends StatefulWidget {
  const HedgePremiumFormDialog({super.key});

  @override
  State<HedgePremiumFormDialog> createState() => _HedgePremiumFormDialogState();
}

class _HedgePremiumFormDialogState extends State<HedgePremiumFormDialog> {
  final _volInputCtrl = TextEditingController();
  String _volUnit = 'SACA'; // ✅ SACA | TON

  final _volTonCtrl = TextEditingController();

  final _premiumCtrl = TextEditingController();
  String _premiumUnit = 'USD_BU'; // ✅ USD_BU | USD_TON

  final _baseLocalCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  DateTime _executadoEm = DateTime.now();

  @override
  void dispose() {
    _volInputCtrl.dispose();
    _volTonCtrl.dispose();
    _premiumCtrl.dispose();
    _baseLocalCtrl.dispose();
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
    setState(() => _executadoEm = d);
  }

  void _submit() {
    final volInput = _parseNum(_volInputCtrl);
    final volTon = _parseNum(_volTonCtrl);
    final prem = _parseNum(_premiumCtrl); // pode ser negativo

    if (volInput == null || volTon == null || prem == null) return;
    if (volInput <= 0 || volTon <= 0) return;

    final payload = HedgePremiumCreate(
      executadoEm: _executadoEm,
      volumeInputValue: volInput,
      volumeInputUnit: _volUnit, // ✅ TON ou SACA
      volumeTon: volTon,
      premiumValue: prem,
      premiumUnit: _premiumUnit, // ✅ USD_BU | USD_TON
      baseLocal: _baseLocalCtrl.text.trim().isEmpty ? null : _baseLocalCtrl.text.trim(),
      observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final volInput = _parseNum(_volInputCtrl);
    final volTon = _parseNum(_volTonCtrl);
    final prem = _parseNum(_premiumCtrl);

    // premium pode ser negativo, então só checa "é número"
    final can = (volInput != null && volInput > 0) &&
        (volTon != null && volTon > 0) &&
        (prem != null);

    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: const Text('Novo hedge Premium'),
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
                      helperText: _volUnit == 'SACA' ? 'Ex: 1000 sacas' : 'Ex: 50 ton',
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

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _premiumCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Prêmio (pode ser negativo)',
                      hintText: 'ex: -0.15',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _premiumUnit,
                    items: const [
                      DropdownMenuItem(value: 'USD_BU', child: Text('USD_BU')),
                      DropdownMenuItem(value: 'USD_TON', child: Text('USD_TON')),
                    ],
                    onChanged: (v) => setState(() => _premiumUnit = v ?? 'USD_BU'),
                    decoration: const InputDecoration(labelText: 'Unidade prêmio'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            TextField(
              controller: _baseLocalCtrl,
              decoration: const InputDecoration(labelText: 'Base local (opcional)'),
            ),

            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Executado em'),
              subtitle: Text(fmt(_executadoEm)),
              trailing: IconButton(onPressed: _pickExec, icon: const Icon(Icons.date_range)),
            ),

            const SizedBox(height: 8),
            TextField(
              controller: _obsCtrl,
              decoration: const InputDecoration(labelText: 'Observação (opcional)'),
              maxLines: 2,
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
