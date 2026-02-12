import 'package:flutter/material.dart';

import '../../../../data/models/contracts_mtm/contracts_mtm_response.dart';
import '../../../../data/models/hedges/hedge_fx_create.dart';

class HedgeFxCreateDialogMtm extends StatefulWidget {
  final ContractBrief contract;
  const HedgeFxCreateDialogMtm({super.key, required this.contract});

  @override
  State<HedgeFxCreateDialogMtm> createState() => _HedgeFxCreateDialogMtmState();
}

class _HedgeFxCreateDialogMtmState extends State<HedgeFxCreateDialogMtm> {
  final _volumeTonCtrl = TextEditingController(); // volume travado em ton
  final _usdCtrl = TextEditingController();
  final _brlPerUsdCtrl = TextEditingController();

  String _tipo = 'CURVA_SCRIPT'; // CURVA_SCRIPT | MANUAL
  final _obsCtrl = TextEditingController();

  DateTime _executadoEm = DateTime.now();
  DateTime? _refMes;

  @override
  void dispose() {
    _volumeTonCtrl.dispose();
    _usdCtrl.dispose();
    _brlPerUsdCtrl.dispose();
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
    final volTon = _parseNum(_volumeTonCtrl);
    final usd = _parseNum(_usdCtrl);
    final brl = _parseNum(_brlPerUsdCtrl);

    if (volTon == null || usd == null || brl == null) return;
    if (volTon <= 0 || usd <= 0 || brl <= 0) return;

    Navigator.pop(
      context,
      HedgeFxCreate(
        executadoEm: _executadoEm,
        volumeTon: volTon,
        usdAmount: usd,
        brlPerUsd: brl,
        refMes: _refMes,
        tipo: _tipo,
        observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contract;

    final volTon = _parseNum(_volumeTonCtrl);
    final usd = _parseNum(_usdCtrl);
    final brl = _parseNum(_brlPerUsdCtrl);

    final can = (volTon != null && volTon > 0) && (usd != null && usd > 0) && (brl != null && brl > 0);

    return AlertDialog(
      title: const Text('Travar FX'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ContractBriefHeader(contract: c),
            const SizedBox(height: 12),

            TextField(
              controller: _volumeTonCtrl,
              decoration: const InputDecoration(labelText: 'Volume travado (ton)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _usdCtrl,
              decoration: const InputDecoration(labelText: 'USD amount'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _brlPerUsdCtrl,
              decoration: const InputDecoration(labelText: 'BRL por USD'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _tipo,
              items: const [
                DropdownMenuItem(value: 'CURVA_SCRIPT', child: Text('CURVA_SCRIPT')),
                DropdownMenuItem(value: 'MANUAL', child: Text('MANUAL')),
              ],
              onChanged: (v) => setState(() => _tipo = v ?? 'CURVA_SCRIPT'),
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),

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
