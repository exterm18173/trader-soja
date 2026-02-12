// lib/views/contracts_mtm_dashboard/widgets/lock_dialogs.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/contracts_mtm/contracts_mtm_response.dart';

/// ----------------- INPUTS (retornos dos dialogs) -----------------

class LockCbotInput {
  final double coveragePct01; // 0..1
  final double lockedCentsPerBu;
  final String symbol;
  final DateTime? refMes; // YYYY-MM-01 (opcional)

  const LockCbotInput({
    required this.coveragePct01,
    required this.lockedCentsPerBu,
    required this.symbol,
    required this.refMes,
  });
}

class LockPremiumInput {
  final double coveragePct01;
  final double premiumValue;
  final String premiumUnit;

  const LockPremiumInput({
    required this.coveragePct01,
    required this.premiumValue,
    required this.premiumUnit,
  });
}

class LockFxInput {
  final double coveragePct01;
  final double brlPerUsd;
  final double? usdAmount; // opcional (se quiser travar parcial em USD)
  final String tipo; // ex: "spot" | "ndf" | "future" | "manual"

  const LockFxInput({
    required this.coveragePct01,
    required this.brlPerUsd,
    required this.usdAmount,
    required this.tipo,
  });
}

/// ----------------- helpers -----------------

double? _parseNum(String s) {
  final v = s.trim().replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(v);
}

double _clamp01(double v) => v.clamp(0.0, 1.0);

String _fmtMonth(DateTime d) => DateFormat('MM/yyyy').format(d);

Future<DateTime?> _pickMonth(BuildContext context, DateTime? initial) async {
  // picker simples: escolhe um dia, a gente normaliza pra YYYY-MM-01
  final now = DateTime.now();
  final init = initial ?? DateTime(now.year, now.month, 1);

  final picked = await showDatePicker(
    context: context,
    initialDate: init,
    firstDate: DateTime(2000, 1, 1),
    lastDate: DateTime(now.year + 10, 12, 31),
    helpText: 'Selecione um mês (qualquer dia do mês)',
  );

  if (picked == null) return null;
  return DateTime(picked.year, picked.month, 1);
}

/// ----------------- DIALOG: CBOT -----------------

class LockCbotDialog extends StatefulWidget {
  final ContractMtmRow row;
  const LockCbotDialog({super.key, required this.row});

  static Future<LockCbotInput?> show(BuildContext context, ContractMtmRow row) {
    return showDialog<LockCbotInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LockCbotDialog(row: row),
    );
  }

  @override
  State<LockCbotDialog> createState() => _LockCbotDialogState();
}

class _LockCbotDialogState extends State<LockCbotDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _coveragePctCtrl;
  late final TextEditingController _lockedCtrl;
  late final TextEditingController _symbolCtrl;

  DateTime? _refMes;

  @override
  void initState() {
    super.initState();
    final cbot = widget.row.locks.cbot;

    _coveragePctCtrl = TextEditingController(
      text: (cbot.coveragePct * 100).toStringAsFixed(0),
    );
    _lockedCtrl = TextEditingController(
      text: (cbot.lockedCentsPerBu ?? widget.row.quotes.cbotSystem?.centsPerBu ?? 0).toStringAsFixed(2),
    );
    _symbolCtrl = TextEditingController(text: cbot.symbol);

    _refMes = cbot.refMes;
  }

  @override
  void dispose() {
    _coveragePctCtrl.dispose();
    _lockedCtrl.dispose();
    _symbolCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final covPct = _parseNum(_coveragePctCtrl.text) ?? 0;
    final cov01 = _clamp01(covPct / 100.0);

    final locked = _parseNum(_lockedCtrl.text)!;
    final symbol = _symbolCtrl.text.trim().isEmpty ? 'ZS=F' : _symbolCtrl.text.trim();

    Navigator.of(context).pop(
      LockCbotInput(
        coveragePct01: cov01,
        lockedCentsPerBu: locked,
        symbol: symbol,
        refMes: _refMes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final id = widget.row.contract.id;

    return AlertDialog(
      title: Text('Travar CBOT — Contrato #$id'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoLine(
                icon: Icons.info_outline_rounded,
                text: 'Defina cobertura (%) e o preço travado em cents/bu.',
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _coveragePctCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cobertura (%)',
                  hintText: 'Ex: 100',
                  prefixIcon: Icon(Icons.percent_rounded),
                ),
                validator: (v) {
                  final n = _parseNum(v ?? '');
                  if (n == null) return 'Informe um número';
                  if (n < 0 || n > 100) return 'Use 0..100';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _lockedCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CBOT travado (cents/bu)',
                  hintText: 'Ex: 1245.50',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
                validator: (v) {
                  final n = _parseNum(v ?? '');
                  if (n == null) return 'Informe um número';
                  if (n <= 0) return 'Deve ser > 0';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _symbolCtrl,
                decoration: const InputDecoration(
                  labelText: 'Símbolo',
                  hintText: 'Ex: ZSH26.CBT',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
              const SizedBox(height: 10),

              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await _pickMonth(context, _refMes);
                  if (!mounted) return;
                  setState(() => _refMes = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Mês de referência (opcional)',
                    prefixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _refMes == null ? '—' : _fmtMonth(_refMes!),
                          style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (_refMes != null)
                        IconButton(
                          tooltip: 'Limpar',
                          onPressed: () => setState(() => _refMes = null),
                          icon: const Icon(Icons.clear_rounded),
                        ),
                      Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Confirmar'),
        ),
      ],
    );
  }
}

/// ----------------- DIALOG: PRÊMIO -----------------

class LockPremiumDialog extends StatefulWidget {
  final ContractMtmRow row;
  const LockPremiumDialog({super.key, required this.row});

  static Future<LockPremiumInput?> show(BuildContext context, ContractMtmRow row) {
    return showDialog<LockPremiumInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LockPremiumDialog(row: row),
    );
  }

  @override
  State<LockPremiumDialog> createState() => _LockPremiumDialogState();
}

class _LockPremiumDialogState extends State<LockPremiumDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _coveragePctCtrl;
  late final TextEditingController _premiumCtrl;

  String _unit = 'USD/bu';

  @override
  void initState() {
    super.initState();
    final prem = widget.row.locks.premium;

    _coveragePctCtrl = TextEditingController(text: (prem.coveragePct * 100).toStringAsFixed(0));
    _premiumCtrl = TextEditingController(text: (prem.premiumValue ?? 0).toStringAsFixed(2));
    _unit = prem.premiumUnit ?? 'USD/bu';
  }

  @override
  void dispose() {
    _coveragePctCtrl.dispose();
    _premiumCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final covPct = _parseNum(_coveragePctCtrl.text) ?? 0;
    final cov01 = _clamp01(covPct / 100.0);
    final premVal = _parseNum(_premiumCtrl.text)!;

    Navigator.of(context).pop(
      LockPremiumInput(
        coveragePct01: cov01,
        premiumValue: premVal,
        premiumUnit: _unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.row.contract.id;

    return AlertDialog(
      title: Text('Travar Prêmio — Contrato #$id'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _InfoLine(
                icon: Icons.info_outline_rounded,
                text: 'Defina cobertura (%) e valor do prêmio.',
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _coveragePctCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cobertura (%)',
                  prefixIcon: Icon(Icons.percent_rounded),
                ),
                validator: (v) {
                  final n = _parseNum(v ?? '');
                  if (n == null) return 'Informe um número';
                  if (n < 0 || n > 100) return 'Use 0..100';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _premiumCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prêmio travado',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
                validator: (v) {
                  final n = _parseNum(v ?? '');
                  if (n == null) return 'Informe um número';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _unit,
                items: const [
                  DropdownMenuItem(value: 'USD/bu', child: Text('USD/bu')),
                  DropdownMenuItem(value: 'USD/sc', child: Text('USD/sc')),
                  DropdownMenuItem(value: 'BRL/sc', child: Text('BRL/sc')),
                ],
                onChanged: (v) => setState(() => _unit = v ?? 'USD/bu'),
                decoration: const InputDecoration(
                  labelText: 'Unidade',
                  prefixIcon: Icon(Icons.straighten_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Confirmar'),
        ),
      ],
    );
  }
}

/// ----------------- DIALOG: FX -----------------

class LockFxDialog extends StatefulWidget {
  final ContractMtmRow row;
  const LockFxDialog({super.key, required this.row});

  static Future<LockFxInput?> show(BuildContext context, ContractMtmRow row) {
    return showDialog<LockFxInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LockFxDialog(row: row),
    );
  }

  @override
  State<LockFxDialog> createState() => _LockFxDialogState();
}

class _LockFxDialogState extends State<LockFxDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _coveragePctCtrl;
  late final TextEditingController _brlPerUsdCtrl;
  late final TextEditingController _usdAmountCtrl;

  bool _useUsdAmount = false;
  String _tipo = 'spot';

  @override
  void initState() {
    super.initState();
    final fx = widget.row.locks.fx;

    _coveragePctCtrl = TextEditingController(text: (fx.coveragePct * 100).toStringAsFixed(0));
    _brlPerUsdCtrl = TextEditingController(text: (fx.brlPerUsd ?? widget.row.quotes.fxSystem?.brlPerUsd ?? 0).toStringAsFixed(4));
    _usdAmountCtrl = TextEditingController(text: (fx.usdAmount ?? 0).toStringAsFixed(2));

    _tipo = (fx.tipo ?? 'spot').toLowerCase();
    _useUsdAmount = (fx.usdAmount ?? 0) > 0;
  }

  @override
  void dispose() {
    _coveragePctCtrl.dispose();
    _brlPerUsdCtrl.dispose();
    _usdAmountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final covPct = _parseNum(_coveragePctCtrl.text) ?? 0;
    final cov01 = _clamp01(covPct / 100.0);
    final brlPerUsd = _parseNum(_brlPerUsdCtrl.text)!;

    final usdAmount = _useUsdAmount ? _parseNum(_usdAmountCtrl.text) : null;

    Navigator.of(context).pop(
      LockFxInput(
        coveragePct01: cov01,
        brlPerUsd: brlPerUsd,
        usdAmount: usdAmount,
        tipo: _tipo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final id = widget.row.contract.id;

    return AlertDialog(
      title: Text('Travar FX — Contrato #$id'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoLine(
                icon: Icons.info_outline_rounded,
                text: 'Travamento FX: informe cobertura (%) e BRL/USD. Opcional: travar por montante em USD.',
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _coveragePctCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cobertura (%)',
                  prefixIcon: Icon(Icons.percent_rounded),
                ),
                validator: (v) {
                  final n = _parseNum(v ?? '');
                  if (n == null) return 'Informe um número';
                  if (n < 0 || n > 100) return 'Use 0..100';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _brlPerUsdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'BRL por USD (ex: 5,1234)',
                  prefixIcon: Icon(Icons.currency_exchange_rounded),
                ),
                validator: (v) {
                  final n = _parseNum(v ?? '');
                  if (n == null) return 'Informe um número';
                  if (n <= 0) return 'Deve ser > 0';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _tipo,
                items: const [
                  DropdownMenuItem(value: 'spot', child: Text('spot')),
                  DropdownMenuItem(value: 'ndf', child: Text('ndf')),
                  DropdownMenuItem(value: 'future', child: Text('future')),
                  DropdownMenuItem(value: 'manual', child: Text('manual')),
                ],
                onChanged: (v) => setState(() => _tipo = (v ?? 'spot')),
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
              ),
              const SizedBox(height: 10),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _useUsdAmount,
                onChanged: (v) => setState(() => _useUsdAmount = v),
                title: Text(
                  'Informar montante em USD (opcional)',
                  style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Se ligado, você pode travar uma parte específica em USD.'),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: !_useUsdAmount
                    ? const SizedBox.shrink()
                    : TextFormField(
                        key: const ValueKey('usdAmount'),
                        controller: _usdAmountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'USD amount',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        validator: (v) {
                          if (!_useUsdAmount) return null;
                          final n = _parseNum(v ?? '');
                          if (n == null) return 'Informe um número';
                          if (n <= 0) return 'Deve ser > 0';
                          return null;
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Confirmar'),
        ),
      ],
    );
  }
}

/// ----------------- UI helpers -----------------

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
