import 'package:flutter/material.dart';
import '../../../../data/models/contracts_mtm/contracts_mtm_response.dart';
import '../../../../data/models/hedges/hedge_cbot_create.dart';

class HedgeCbotCreateDialogMtm extends StatefulWidget {
  final ContractBrief contract;
  const HedgeCbotCreateDialogMtm({super.key, required this.contract});

  @override
  State<HedgeCbotCreateDialogMtm> createState() => _HedgeCbotCreateDialogMtmState();
}

class _HedgeCbotCreateDialogMtmState extends State<HedgeCbotCreateDialogMtm> {
  final _volInputCtrl = TextEditingController();
  String _volUnit = 'SACA';
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

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

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
    if (volInput <= 0 || volTon <= 0 || cbot <= 0) return;

    Navigator.pop(
      context,
      HedgeCbotCreate(
        executadoEm: _executadoEm,
        volumeInputValue: volInput,
        volumeInputUnit: _volUnit,
        volumeTon: volTon,
        cbotUsdPerBu: cbot,
        refMes: _refMes,
        symbol: _symbolCtrl.text.trim().isEmpty ? null : _symbolCtrl.text.trim(),
        observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contract;

    final volInput = _parseNum(_volInputCtrl);
    final volTon = _parseNum(_volTonCtrl);
    final cbot = _parseNum(_cbotCtrl);
    final can = (volInput != null && volInput > 0) && (volTon != null && volTon > 0) && (cbot != null && cbot > 0);

    return AlertDialog(
      title: const Text('Travar CBOT'),
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
                    decoration: const InputDecoration(labelText: 'Volume input'),
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

            TextField(controller: _symbolCtrl, decoration: const InputDecoration(labelText: 'Symbol (opcional)')),
            const SizedBox(height: 8),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Executado em'),
              subtitle: Text(_fmt(_executadoEm)),
              trailing: IconButton(onPressed: _pickExec, icon: const Icon(Icons.date_range)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ref mês (opcional)'),
              subtitle: Text(_refMes == null ? '—' : _fmt(_refMes!)),
              trailing: IconButton(onPressed: _pickRefMes, icon: const Icon(Icons.calendar_month)),
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
