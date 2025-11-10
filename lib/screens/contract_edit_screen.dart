// filepath: c:\FlutterProjects\projet_mobile-voiture\lib\screens\contract_edit_screen.dart
import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../services/contract_service.dart';

class ContractEditScreen extends StatefulWidget {
  final Contract contract;
  const ContractEditScreen({required this.contract, super.key});

  @override
  State<ContractEditScreen> createState() => _ContractEditScreenState();
}

class _ContractEditScreenState extends State<ContractEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _buyerController;
  late TextEditingController _sellerController;
  late TextEditingController _priceController;
  late TextEditingController _termsController;
  late TextEditingController _carMatriculeController;
  late TextEditingController _carIdController;
  final ContractService _service = ContractService();
  bool _saving = false;
  DateTime? _signingDate;
  DateTime? _expirationDate;

  @override
  void initState() {
    super.initState();
    final c = widget.contract;
    _titleController = TextEditingController(text: c.title);
    _buyerController = TextEditingController(text: c.buyerName);
    _sellerController = TextEditingController(text: c.sellerName);
    _priceController = TextEditingController(text: c.price.toString());
    _termsController = TextEditingController(text: c.terms);
    _carMatriculeController = TextEditingController(text: c.carMatricule ?? '');
    _carIdController = TextEditingController(text: c.carId != null ? c.carId.toString() : '');
    _signingDate = c.signingDate;
    _expirationDate = c.expirationDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _buyerController.dispose();
    _sellerController.dispose();
    _priceController.dispose();
    _termsController.dispose();
    _carMatriculeController.dispose();
    _carIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final updated = widget.contract.copyWith(
      title: _titleController.text.trim(),
      buyerName: _buyerController.text.trim(),
      sellerName: _sellerController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? widget.contract.price,
      terms: _termsController.text.trim(),
      carMatricule: _carMatriculeController.text.trim().isEmpty ? null : _carMatriculeController.text.trim(),
      carId: int.tryParse(_carIdController.text.trim()),
      signingDate: _signingDate,
      expirationDate: _expirationDate,
    );
    await _service.updateContract(updated);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Contract')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
              TextFormField(controller: _buyerController, decoration: const InputDecoration(labelText: 'Buyer name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
              TextFormField(controller: _sellerController, decoration: const InputDecoration(labelText: 'Seller name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
              TextFormField(controller: _carMatriculeController, decoration: const InputDecoration(labelText: 'Car matricule (optional)')),
              TextFormField(controller: _carIdController, decoration: const InputDecoration(labelText: 'Car ID (optional)'), keyboardType: TextInputType.number),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              TextFormField(controller: _termsController, decoration: const InputDecoration(labelText: 'Terms'), maxLines: 4),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('Signing date: ${_signingDate != null ? _signingDate!.toLocal().toString().split(' ')[0] : 'not set'}')),
                TextButton(onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: _signingDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _signingDate = picked);
                }, child: const Text('Pick')),
              ]),
              Row(children: [
                Expanded(child: Text('Expiration date: ${_expirationDate != null ? _expirationDate!.toLocal().toString().split(' ')[0] : 'not set'}')),
                TextButton(onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _expirationDate = picked);
                }, child: const Text('Pick')),
              ]),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator() : const Text('Save')),
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
