// lib/views/fx/widgets/fx_spot_tick_form_dialog.dart
import 'package:flutter/material.dart';

class FxSpotTickFormDialog extends StatefulWidget {
  final String title;

  const FxSpotTickFormDialog({super.key, required this.title});

  @override
  State<FxSpotTickFormDialog> createState() => _FxSpotTickFormDialogState();
}

class _FxSpotTickFormDialogState extends State<FxSpotTickFormDialog> {
  DateTime _ts = DateTime.now();
  final _priceCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController(text: 'B3');

  @override
  void dispose() {
    _priceCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _ts,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    if (mounted) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_ts),
      );
      if (t == null) return;

      setState(() {
        _ts = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      });
    }
  }

  void _submit() {
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
    final source = _sourceCtrl.text.trim().isEmpty
        ? 'B3'
        : _sourceCtrl.text.trim();

    if (price == null) return;

    Navigator.pop<Map<String, dynamic>>(context, {
      'ts': _ts,
      'price': price,
      'source': source,
    });
  }

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
    final canSubmit = price != null;

    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Timestamp'),
            subtitle: Text(fmt(_ts)),
            trailing: IconButton(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.schedule),
            ),
          ),
          TextField(
            controller: _priceCtrl,
            decoration: const InputDecoration(labelText: 'Preço (BRL por USD)'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _sourceCtrl,
            decoration: const InputDecoration(labelText: 'Source (ex: B3)'),
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
