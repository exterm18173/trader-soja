// lib/views/fx/widgets/fx_manual_point_form_dialog.dart
import 'package:flutter/material.dart';

class FxManualPointFormDialog extends StatefulWidget {
  final String title;

  final int? initialSourceId;
  final DateTime? initialCapturedAt;
  final DateTime? initialRefMes;
  final double? initialFx;

  const FxManualPointFormDialog({
    super.key,
    required this.title,
    this.initialSourceId,
    this.initialCapturedAt,
    this.initialRefMes,
    this.initialFx,
  });

  @override
  State<FxManualPointFormDialog> createState() =>
      _FxManualPointFormDialogState();
}

class _FxManualPointFormDialogState extends State<FxManualPointFormDialog> {
  final _sourceCtrl = TextEditingController();
  final _fxCtrl = TextEditingController();

  DateTime _capturedAt = DateTime.now();
  DateTime _refMes = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    _sourceCtrl.text = widget.initialSourceId?.toString() ?? '';
    _fxCtrl.text = widget.initialFx?.toString() ?? '';

    _capturedAt = widget.initialCapturedAt ?? DateTime.now();
    _refMes =
        widget.initialRefMes ??
        DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _fxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCapturedAt() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _capturedAt,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    if (mounted) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_capturedAt),
      );
      if (t == null) return;

      setState(() {
        _capturedAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      });
    }
  }

  Future<void> _pickRefMes() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _refMes,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;

    // normaliza para "mês" => 1º dia
    setState(() {
      _refMes = DateTime(d.year, d.month, 1);
    });
  }

  void _submit() {
    final sourceId = int.tryParse(_sourceCtrl.text.trim());
    final fx = double.tryParse(_fxCtrl.text.replaceAll(',', '.'));

    if (sourceId == null || fx == null) return;

    Navigator.pop<Map<String, dynamic>>(context, {
      'sourceId': sourceId,
      'capturedAt': _capturedAt,
      'refMes': _refMes,
      'fx': fx,
    });
  }

  @override
  Widget build(BuildContext context) {
    final sourceId = int.tryParse(_sourceCtrl.text.trim());
    final fx = double.tryParse(_fxCtrl.text.replaceAll(',', '.'));
    final canSubmit = sourceId != null && fx != null;

    String fmtDt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    String fmtDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _sourceCtrl,
            decoration: const InputDecoration(labelText: 'Source ID (ex: 1)'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Captured At'),
            subtitle: Text(fmtDt(_capturedAt)),
            trailing: IconButton(
              onPressed: _pickCapturedAt,
              icon: const Icon(Icons.schedule),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ref Mês'),
            subtitle: Text(fmtDate(_refMes)),
            trailing: IconButton(
              onPressed: _pickRefMes,
              icon: const Icon(Icons.date_range),
            ),
          ),
          TextField(
            controller: _fxCtrl,
            decoration: const InputDecoration(labelText: 'FX (BRL por USD)'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: canSubmit ? _submit : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
