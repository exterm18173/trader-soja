// lib/views/rates/widgets/interest_rate_form_dialog.dart
import 'package:flutter/material.dart';

class InterestRateFormDialog extends StatefulWidget {
  final String title;
  final DateTime? initialDate;
  final double? initialCdi;
  final double? initialSofr;

  const InterestRateFormDialog({
    super.key,
    required this.title,
    this.initialDate,
    this.initialCdi,
    this.initialSofr,
  });

  @override
  State<InterestRateFormDialog> createState() => _InterestRateFormDialogState();
}

class _InterestRateFormDialogState extends State<InterestRateFormDialog> {
  late DateTime _date;
  final _cdiCtrl = TextEditingController();
  final _sofrCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _cdiCtrl.text = widget.initialCdi?.toString() ?? '';
    _sofrCtrl.text = widget.initialSofr?.toString() ?? '';
  }

  @override
  void dispose() {
    _cdiCtrl.dispose();
    _sofrCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final cdi = double.tryParse(_cdiCtrl.text.replaceAll(',', '.'));
    final sofr = double.tryParse(_sofrCtrl.text.replaceAll(',', '.'));
    if (cdi == null || sofr == null) return;

    Navigator.pop<Map<String, dynamic>>(context, {
      'rateDate': _date,
      'cdiAnnual': cdi,
      'sofrAnnual': sofr,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cdi = double.tryParse(_cdiCtrl.text.replaceAll(',', '.'));
    final sofr = double.tryParse(_sofrCtrl.text.replaceAll(',', '.'));
    final canSubmit = cdi != null && sofr != null;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data'),
            subtitle: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
            trailing: IconButton(
              onPressed: _pickDate,
              icon: const Icon(Icons.date_range),
            ),
          ),
          TextField(
            controller: _cdiCtrl,
            decoration: const InputDecoration(labelText: 'CDI anual (%)'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _sofrCtrl,
            decoration: const InputDecoration(labelText: 'SOFR anual (%)'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: canSubmit ? _submit : null, child: const Text('Salvar')),
      ],
    );
  }
}
