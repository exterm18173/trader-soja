import 'package:flutter/material.dart';
import '../../../data/models/hedges/hedge_fx_create.dart';

class HedgeFxFormDialog extends StatefulWidget {
  const HedgeFxFormDialog({super.key});

  @override
  State<HedgeFxFormDialog> createState() => _HedgeFxFormDialogState();
}

class _HedgeFxFormDialogState extends State<HedgeFxFormDialog> {
  final _volumeTonCtrl = TextEditingController(); // ✅ NOVO
  final _usdCtrl = TextEditingController();
  final _brlPerUsdCtrl = TextEditingController();

  String _tipo = 'CURVA_SCRIPT'; // ✅ dropdown
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

    final payload = HedgeFxCreate(
      executadoEm: _executadoEm,
      volumeTon: volTon, // ✅ NOVO
      usdAmount: usd,
      brlPerUsd: brl,
      refMes: _refMes,
      tipo: _tipo,
      observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final volTon = _parseNum(_volumeTonCtrl);
    final usd = _parseNum(_usdCtrl);
    final brl = _parseNum(_brlPerUsdCtrl);

    final can = (volTon != null && volTon > 0) && (usd != null && usd > 0) && (brl != null && brl > 0);

    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: const Text('Novo hedge FX'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ NOVO: volume travado em ton
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

            // ✅ dropdown tipo (evita erro)
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
              subtitle: Text(fmt(_executadoEm)),
              trailing: IconButton(onPressed: _pickExec, icon: const Icon(Icons.date_range)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ref mês (opcional)'),
              subtitle: Text(_refMes == null ? '—' : fmt(_refMes!)),
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
