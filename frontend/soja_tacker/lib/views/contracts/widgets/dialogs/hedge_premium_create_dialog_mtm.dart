import 'package:flutter/material.dart';

import '../../../../data/models/contracts_mtm/contracts_mtm_response.dart';
import '../../../../data/models/hedges/hedge_premium_create.dart';

class HedgePremiumCreateDialogMtm extends StatefulWidget {
  final ContractBrief contract;
  const HedgePremiumCreateDialogMtm({super.key, required this.contract});

  @override
  State<HedgePremiumCreateDialogMtm> createState() => _HedgePremiumCreateDialogMtmState();
}

class _HedgePremiumCreateDialogMtmState extends State<HedgePremiumCreateDialogMtm> {
  final _volInputCtrl = TextEditingController();
  String _volUnit = 'SACA'; // SACA | TON
  final _volTonCtrl = TextEditingController();

  final _premiumCtrl = TextEditingController(); // pode ser negativo
  String _premiumUnit = 'USD_BU'; // USD_BU | USD_TON

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

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickExec() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _executadoEm,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => _executadoEm = DateTime(d.year, d.month, d.day));
  }

  void _submit() {
    final volInput = _parseNum(_volInputCtrl);
    final volTon = _parseNum(_volTonCtrl);
    final prem = _parseNum(_premiumCtrl); // pode ser negativo

    if (volInput == null || volTon == null || prem == null) return;
    if (volInput <= 0 || volTon <= 0) return;

    Navigator.pop(
      context,
      HedgePremiumCreate(
        executadoEm: _executadoEm,
        volumeInputValue: volInput,
        volumeInputUnit: _volUnit,
        volumeTon: volTon,
        premiumValue: prem,
        premiumUnit: _premiumUnit,
        baseLocal: _baseLocalCtrl.text.trim().isEmpty ? null : _baseLocalCtrl.text.trim(),
        observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contract;

    final volInput = _parseNum(_volInputCtrl);
    final volTon = _parseNum(_volTonCtrl);
    final prem = _parseNum(_premiumCtrl);

    // premium pode ser negativo, então basta ser numérico
    final can = (volInput != null && volInput > 0) && (volTon != null && volTon > 0) && (prem != null);

    return AlertDialog(
      title: const Text('Travar Prêmio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ContractBriefHeader(contract: c),
            const SizedBox(height: 12),

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
              subtitle: Text(_fmt(_executadoEm)),
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

class _ContractBriefHeader extends StatelessWidget {
  final ContractBrief contract;
  const _ContractBriefHeader({required this.contract});

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final c = contract;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('#${c.id} • ${c.produto}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Entrega: ${_fmt(c.dataEntrega)} • ${c.volumeTotalTon.toStringAsFixed(2)} ton'),
          const SizedBox(height: 2),
          Text('Tipo: ${c.tipoPrecificacao} • Status: ${c.status}'),
        ],
      ),
    );
  }
}
