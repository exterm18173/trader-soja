import 'package:flutter/material.dart';
import '../../../data/models/contracts/contract_create.dart';

class ContractFormDialog extends StatefulWidget {
  final String title;
  const ContractFormDialog({super.key, required this.title});

  @override
  State<ContractFormDialog> createState() => _ContractFormDialogState();
}

class _ContractFormDialogState extends State<ContractFormDialog> {
  // regra padrão: 1 saca (60kg) = 0.06 ton
  static const double _tonPerSaca = 0.06;

  final _produtoCtrl = TextEditingController(text: 'SOJA');

  String _tipo = 'CBOT_PREMIO'; // CBOT_PREMIO | FIXO_BRL
  String _volUnit = 'SACA'; // SACA | TON

  final _volInputCtrl = TextEditingController();
  final _volTonCtrl = TextEditingController();

  final _precoFixoCtrl = TextEditingController();
  final _precoUnitCtrl = TextEditingController(text: 'BRL/sc');

  // ✅ Frete
  final _freteTotalCtrl = TextEditingController();
  final _fretePerTonCtrl = TextEditingController();
  final _freteObsCtrl = TextEditingController();

  final _obsCtrl = TextEditingController();

  DateTime _dataEntrega = DateTime.now();

  @override
  void initState() {
    super.initState();
    // ao digitar volume input, recalcula ton
    _volInputCtrl.addListener(_recalcTonFromInput);
  }

  @override
  void dispose() {
    _volInputCtrl.removeListener(_recalcTonFromInput);

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

  bool get _isFixoBrl => _tipo == 'FIXO_BRL';

  // ---------- helpers ----------
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

  // ---------- cálculo ton ----------
  void _recalcTonFromInput() {
    final input = _parseNum(_volInputCtrl);
    if (input == null) {
      if (_volTonCtrl.text.isNotEmpty) {
        _volTonCtrl.text = '';
        setState(() {});
      }
      return;
    }

    final ton = (_volUnit == 'SACA') ? (input * _tonPerSaca) : input;
    final newText = ton.toStringAsFixed(6);

    if (_volTonCtrl.text != newText) {
      _volTonCtrl.text = newText;
      setState(() {});
    }
  }

  // ---------- UI actions ----------
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
    final produto = _produtoCtrl.text.trim().isEmpty ? 'SOJA' : _produtoCtrl.text.trim().toUpperCase();

    final volInput = _parseNum(_volInputCtrl);
    if (volInput == null || volInput <= 0) return;

    final volTon = _parseNum(_volTonCtrl);
    if (volTon == null || volTon <= 0) return;

    final precoFixo = _parseNum(_precoFixoCtrl);
    final precoUnit = _normStr(_precoUnitCtrl.text);

    final freteTotal = _parseNum(_freteTotalCtrl);
    final fretePerTon = _parseNum(_fretePerTonCtrl);
    final freteObs = _normStr(_freteObsCtrl.text);

    final obs = _normStr(_obsCtrl.text);

    // regra: FIXO_BRL exige preco + unit
    if (_isFixoBrl) {
      if (precoFixo == null || precoFixo <= 0 || precoUnit == null) return;
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
      freteBrlTotal: freteTotal,
      freteBrlPerTon: fretePerTon,
      freteObs: freteObs,
      observacao: obs,
    );

    Navigator.pop(context, payload);
  }

  // ---------- small widgets ----------
  Widget _sectionTitle(BuildContext context, String title, {IconData? icon}) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  InputDecoration _dec(String label, {String? hint, String? helper, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      suffixIcon: suffixIcon,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // validações para botão salvar
    final volInput = _parseNum(_volInputCtrl);
    final volTon = _parseNum(_volTonCtrl);

    final precoFixo = _parseNum(_precoFixoCtrl);
    final precoUnitOk = _precoUnitCtrl.text.trim().isNotEmpty;

    final freteTotal = _parseNum(_freteTotalCtrl);
    final fretePerTon = _parseNum(_fretePerTonCtrl);

    final baseOk = (volInput != null && volInput > 0) && (volTon != null && volTon > 0);
    final fixoOk = !_isFixoBrl || ((precoFixo != null && precoFixo > 0) && precoUnitOk);
    final freteOk = !(freteTotal != null && fretePerTon != null);

    final can = baseOk && fixoOk && freteOk;

    // layout: dialog mais “moderno” com bordas, seções e campos densos
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // header
              Row(
                children: [
                  const Icon(Icons.description_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ====== Básico ======
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _sectionTitle(context, 'Dados do contrato', icon: Icons.tune),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _produtoCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: _dec('Produto', hint: 'SOJA'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _tipo,
                              items: const [
                                DropdownMenuItem(value: 'CBOT_PREMIO', child: Text('CBOT_PREMIO')),
                                DropdownMenuItem(value: 'FIXO_BRL', child: Text('FIXO_BRL')),
                              ],
                              onChanged: (v) => setState(() => _tipo = v ?? 'CBOT_PREMIO'),
                              decoration: _dec('Tipo de precificação'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Data entrega em card leve
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Data de entrega', style: Theme.of(context).textTheme.labelLarge),
                                  const SizedBox(height: 2),
                                  Text(_fmtDate(_dataEntrega)),
                                ],
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: _pickEntrega,
                              icon: const Icon(Icons.date_range),
                              label: const Text('Selecionar'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ====== Volume ======
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _sectionTitle(context, 'Volume', icon: Icons.scale_outlined),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _volInputCtrl,
                              decoration: _dec('Volume (input)', hint: 'Ex: 1000', helper: 'Digite o volume'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 160,
                            child: DropdownButtonFormField<String>(
                              initialValue: _volUnit,
                              items: const [
                                DropdownMenuItem(value: 'SACA', child: Text('SACA')),
                                DropdownMenuItem(value: 'TON', child: Text('TON')),
                              ],
                              onChanged: (v) {
                                setState(() => _volUnit = v ?? 'SACA');
                                _recalcTonFromInput();
                              },
                              decoration: _dec('Unidade'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _volTonCtrl,
                        readOnly: true,
                        decoration: _dec(
                          'Volume total (ton)',
                          helper: _volUnit == 'SACA'
                              ? 'Calculado: sacas × 0.06'
                              : 'Calculado: igual ao volume em TON',
                          suffixIcon: const Icon(Icons.lock_outline),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),

                      const SizedBox(height: 16),

                      // ====== Preço FIXO ======
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: !_isFixoBrl
                            ? const SizedBox.shrink()
                            : Column(
                                key: const ValueKey('fixo'),
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _sectionTitle(context, 'Preço fixo', icon: Icons.payments_outlined),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _precoFixoCtrl,
                                          decoration: _dec('Preço fixo (obrigatório)', hint: 'Ex: 135.50'),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: _precoUnitCtrl,
                                          decoration: _dec('Unidade preço (obrigatório)', hint: 'BRL/sc'),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!fixoOk) ...[
                                    const SizedBox(height: 8),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Para FIXO_BRL, informe preço fixo e unidade.',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                ],
                              ),
                      ),

                      // ====== Frete ======
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _sectionTitle(context, 'Frete (opcional)', icon: Icons.local_shipping_outlined),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _freteTotalCtrl,
                              decoration: _dec(
                                'Frete total (BRL)',
                                hint: 'Ex: 2500',
                                helper: freteTotal != null && fretePerTon != null ? 'Use apenas um' : null,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _fretePerTonCtrl,
                              decoration: _dec(
                                'Frete por ton (BRL/ton)',
                                hint: 'Ex: 35',
                                helper: freteTotal != null && fretePerTon != null ? 'Use apenas um' : null,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _freteObsCtrl,
                        decoration: _dec('Obs frete', hint: 'Opcional'),
                        maxLines: 2,
                      ),

                      if (!freteOk) ...[
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Informe apenas um: frete total OU frete por ton.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ====== Observação ======
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _sectionTitle(context, 'Observação', icon: Icons.notes_outlined),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _obsCtrl,
                        decoration: _dec('Observação (opcional)', hint: 'Ex: contrato para março...'),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 6),

                      // resumo pequeno (UX)
                      if (baseOk)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Resumo: ${_volInputCtrl.text.trim()} $_volUnit → ${_volTonCtrl.text.trim()} ton',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // actions
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: can ? _submit : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
