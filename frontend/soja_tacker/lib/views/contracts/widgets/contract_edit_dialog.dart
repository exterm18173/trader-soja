import 'package:flutter/material.dart';
import '../../../data/models/contracts/contract_read.dart';
import '../../../data/models/contracts/contract_update.dart';

class ContractEditDialog extends StatefulWidget {
  final String title;
  final ContractRead initial;

  const ContractEditDialog({
    super.key,
    required this.title,
    required this.initial,
  });

  @override
  State<ContractEditDialog> createState() => _ContractEditDialogState();
}

class _ContractEditDialogState extends State<ContractEditDialog> {
  late String _status = widget.initial.status;
  late DateTime _dataEntrega = widget.initial.dataEntrega;

  late String _volUnit = widget.initial.volumeInputUnit;
  final _volInputCtrl = TextEditingController();
  final _volTonCtrl = TextEditingController();

  final _precoFixoCtrl = TextEditingController();
  final _precoUnitCtrl = TextEditingController();

  final _freteTotalCtrl = TextEditingController();
  final _fretePerTonCtrl = TextEditingController();
  final _freteObsCtrl = TextEditingController();

  final _obsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _volInputCtrl.text = widget.initial.volumeInputValue.toStringAsFixed(4);
    _volTonCtrl.text = widget.initial.volumeTotalTon.toStringAsFixed(6);

    _precoFixoCtrl.text = (widget.initial.precoFixoBrlValue ?? '').toString();
    _precoUnitCtrl.text = (widget.initial.precoFixoBrlUnit ?? '');

    _freteTotalCtrl.text = widget.initial.freteBrlTotal?.toString() ?? '';
    _fretePerTonCtrl.text = widget.initial.freteBrlPerTon?.toString() ?? '';
    _freteObsCtrl.text = widget.initial.freteObs ?? '';

    _obsCtrl.text = widget.initial.observacao ?? '';
  }

  @override
  void dispose() {
    _volInputCtrl.dispose();
    _volTonCtrl.dispose();
    _precoFixoCtrl.dispose();
    _precoUnitCtrl.dispose();
    _freteTotalCtrl.dispose();
    _fretePerTonCtrl.dispose();
    _freteObsCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  double? _parseNum(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  String? _normStr(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickEntrega() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dataEntrega,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => _dataEntrega = d);
  }

  void _submit() {
    final volInput = _parseNum(_volInputCtrl);
    final volTon = _parseNum(_volTonCtrl);

    if (volInput == null || volTon == null) return;

    final freteTotal = _parseNum(_freteTotalCtrl);
    final fretePerTon = _parseNum(_fretePerTonCtrl);
    if (freteTotal != null && fretePerTon != null) return;

    final payload = ContractUpdate(
      status: _status,
      dataEntrega: _dataEntrega,
      volumeInputValue: volInput,
      volumeInputUnit: _volUnit,
      volumeTotalTon: volTon,

      // só manda se tiver valor (evita “forçar” em contratos CBOT)
      precoFixoBrlValue: _parseNum(_precoFixoCtrl),
      precoFixoBrlUnit: _normStr(_precoUnitCtrl.text),

      freteBrlTotal: freteTotal,
      freteBrlPerTon: fretePerTon,
      freteObs: _normStr(_freteObsCtrl.text),

      observacao: _normStr(_obsCtrl.text),
    );

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final freteTotal = _parseNum(_freteTotalCtrl);
    final fretePerTon = _parseNum(_fretePerTonCtrl);
    final freteOk = !(freteTotal != null && fretePerTon != null);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: const [
                DropdownMenuItem(value: 'ABERTO', child: Text('ABERTO')),
                DropdownMenuItem(value: 'PARCIAL', child: Text('PARCIAL')),
                DropdownMenuItem(value: 'FECHADO', child: Text('FECHADO')),
                DropdownMenuItem(value: 'CANCELADO', child: Text('CANCELADO')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'ABERTO'),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data entrega'),
              subtitle: Text(_fmtDate(_dataEntrega)),
              trailing: IconButton(
                onPressed: _pickEntrega,
                icon: const Icon(Icons.date_range),
              ),
            ),
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
            const SizedBox(height: 12),

            TextField(
              controller: _volTonCtrl,
              decoration: const InputDecoration(labelText: 'Volume total (ton)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _precoFixoCtrl,
                    decoration: const InputDecoration(labelText: 'Preço fixo (se aplicável)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _precoUnitCtrl,
                    decoration: const InputDecoration(labelText: 'Unidade preço (se aplicável)'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Frete (opcional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _freteTotalCtrl,
                    decoration: const InputDecoration(labelText: 'Frete total (BRL)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fretePerTonCtrl,
                    decoration: const InputDecoration(labelText: 'Frete por ton (BRL/ton)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (!freteOk) ...[
              const SizedBox(height: 8),
              const Text(
                'Informe apenas um: frete total OU frete por ton.',
                style: TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 8),

            TextField(
              controller: _freteObsCtrl,
              decoration: const InputDecoration(labelText: 'Obs frete (opcional)'),
              maxLines: 2,
            ),

            const SizedBox(height: 12),

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
        ElevatedButton(
          onPressed: freteOk ? _submit : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
