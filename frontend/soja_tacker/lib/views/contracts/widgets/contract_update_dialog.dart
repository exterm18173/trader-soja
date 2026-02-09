// lib/views/contracts/widgets/contract_update_dialog.dart
import 'package:flutter/material.dart';
import '../../../data/models/contracts/contract_read.dart';
import '../../../data/models/contracts/contract_update.dart';

class ContractUpdateDialog extends StatefulWidget {
  final ContractRead contract;
  const ContractUpdateDialog({super.key, required this.contract});

  @override
  State<ContractUpdateDialog> createState() => _ContractUpdateDialogState();
}

class _ContractUpdateDialogState extends State<ContractUpdateDialog> {
  final _statusCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  DateTime? _dataEntrega;

  @override
  void initState() {
    super.initState();
    _statusCtrl.text = widget.contract.status;
    _obsCtrl.text = widget.contract.observacao ?? '';
    _dataEntrega = widget.contract.dataEntrega;
  }

  @override
  void dispose() {
    _statusCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEntrega() async {
    final initial = _dataEntrega ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => _dataEntrega = d);
  }

  void _submit() {
    final status = _statusCtrl.text.trim().isEmpty ? null : _statusCtrl.text.trim();
    final obs = _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim();

    Navigator.pop(
      context,
      ContractUpdate(
        status: status,
        dataEntrega: _dataEntrega,
        observacao: obs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: Text('Editar contrato #${widget.contract.id}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _statusCtrl,
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data entrega'),
            subtitle: Text(_dataEntrega == null ? '—' : fmt(_dataEntrega!)),
            trailing: IconButton(onPressed: _pickEntrega, icon: const Icon(Icons.date_range)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _obsCtrl,
            decoration: const InputDecoration(labelText: 'Observação'),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}
