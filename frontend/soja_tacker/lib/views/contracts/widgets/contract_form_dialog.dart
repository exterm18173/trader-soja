import 'package:flutter/material.dart';
import '../../../data/models/contracts/contract_create.dart';

class ContractFormDialog extends StatefulWidget {
  final String title;
  const ContractFormDialog({super.key, required this.title});

  @override
  State<ContractFormDialog> createState() => _ContractFormDialogState();
}

class _ContractFormDialogState extends State<ContractFormDialog> {
  final _produtoCtrl = TextEditingController(text: 'SOJA');

  // Melhor: dropdown (evita erro)
  String _tipo = 'CBOT_PREMIO'; // CBOT_PREMIO | FIXO_BRL
  String _volUnit = 'SACA';     // SACA | TON

  final _volInputCtrl = TextEditingController();
  final _volTonCtrl = TextEditingController();

  final _precoFixoCtrl = TextEditingController();
  final _precoUnitCtrl = TextEditingController(text: 'BRL/sc');

  // ✅ NOVO: frete
  final _freteTotalCtrl = TextEditingController();
  final _fretePerTonCtrl = TextEditingController();
  final _freteObsCtrl = TextEditingController();

  final _obsCtrl = TextEditingController();

  DateTime _dataEntrega = DateTime.now();

  @override
  void dispose() {
    _produtoCtrl.dispose();
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

  double? _parseNum(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _isFixoBrl => _tipo == 'FIXO_BRL';

  void _submit() {
    final produto = _produtoCtrl.text.trim().isEmpty ? 'SOJA' : _produtoCtrl.text.trim();
    final volInput = _parseNum(_volInputCtrl);
    final volTon = _parseNum(_volTonCtrl);

    final precoFixo = _parseNum(_precoFixoCtrl);
    final precoUnit = _precoUnitCtrl.text.trim().isEmpty ? null : _precoUnitCtrl.text.trim();

    final freteTotal = _parseNum(_freteTotalCtrl);
    final fretePerTon = _parseNum(_fretePerTonCtrl);
    final freteObs = _freteObsCtrl.text.trim().isEmpty ? null : _freteObsCtrl.text.trim();

    final obs = _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim();

    // validações mínimas
    if (volInput == null || volTon == null) return;

    // regra: FIXO_BRL exige preco + unit
    if (_isFixoBrl) {
      if (precoFixo == null || precoUnit == null) return;
    }

    // regra frete: não pode preencher os dois
    if (freteTotal != null && fretePerTon != null) return;

    final payload = ContractCreate(
      produto: produto,
      tipoPrecificacao: _tipo,
      volumeInputValue: volInput,
      volumeInputUnit: _volUnit,
      volumeTotalTon: volTon,
      dataEntrega: _dataEntrega,
      precoFixoBrlValue: _isFixoBrl ? precoFixo : null,
      precoFixoBrlUnit: _isFixoBrl ? precoUnit : null,

      // ✅ frete
      freteBrlTotal: freteTotal,
      freteBrlPerTon: fretePerTon,
      freteObs: freteObs,

      observacao: obs,
    );

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final volInput = _parseNum(_volInputCtrl);
    final volTon = _parseNum(_volTonCtrl);

    final precoFixo = _parseNum(_precoFixoCtrl);
    final precoUnitOk = _precoUnitCtrl.text.trim().isNotEmpty;

    final freteTotal = _parseNum(_freteTotalCtrl);
    final fretePerTon = _parseNum(_fretePerTonCtrl);

    final baseOk = volInput != null && volTon != null;
    final fixoOk = !_isFixoBrl || (precoFixo != null && precoUnitOk);
    final freteOk = !(freteTotal != null && fretePerTon != null);

    final can = baseOk && fixoOk && freteOk;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _produtoCtrl,
              decoration: const InputDecoration(labelText: 'Produto (ex: SOJA)'),
            ),
            const SizedBox(height: 12),

            // ✅ Tipo precificação (dropdown)
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              items: const [
                DropdownMenuItem(value: 'CBOT_PREMIO', child: Text('CBOT_PREMIO')),
                DropdownMenuItem(value: 'FIXO_BRL', child: Text('FIXO_BRL')),
              ],
              onChanged: (v) => setState(() => _tipo = v ?? 'CBOT_PREMIO'),
              decoration: const InputDecoration(labelText: 'Tipo precificação'),
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

                // ✅ Unidade (dropdown)
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
            const SizedBox(height: 8),

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

            // ✅ Preço fixo só faz sentido em FIXO_BRL
            if (_isFixoBrl) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _precoFixoCtrl,
                      decoration: const InputDecoration(labelText: 'Preço fixo (obrigatório)'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _precoUnitCtrl,
                      decoration: const InputDecoration(labelText: 'Unidade preço (obrigatório)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ✅ Frete (novo)
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
                    decoration: InputDecoration(
                      labelText: 'Frete total (BRL)',
                      helperText: freteTotal != null && fretePerTon != null ? 'Use apenas um' : null,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fretePerTonCtrl,
                    decoration: InputDecoration(
                      labelText: 'Frete por ton (BRL/ton)',
                      helperText: freteTotal != null && fretePerTon != null ? 'Use apenas um' : null,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
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

            if (!freteOk) ...[
              const SizedBox(height: 8),
              const Text(
                'Informe apenas um: frete total OU frete por ton.',
                style: TextStyle(color: Colors.red),
              ),
            ],
            if (!fixoOk) ...[
              const SizedBox(height: 8),
              const Text(
                'Para FIXO_BRL, informe preço fixo e unidade.',
                style: TextStyle(color: Colors.red),
              ),
            ],
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
