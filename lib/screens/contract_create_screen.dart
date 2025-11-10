import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/voiture.dart';
import '../services/contract_service.dart';
import 'signature_capture_screen.dart';

class ContractCreateScreen extends StatefulWidget {
  final Voiture? voiture; // optional prefill
  const ContractCreateScreen({super.key, this.voiture});

  @override
  State<ContractCreateScreen> createState() => _ContractCreateScreenState();
}

class _ContractCreateScreenState extends State<ContractCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ContractService _service = ContractService();

  late TextEditingController _titleController;
  late TextEditingController _buyerController;
  late TextEditingController _sellerController;
  late TextEditingController _priceController;
  late TextEditingController _termsController;
  late TextEditingController _carMatriculeController;
  late TextEditingController _carIdController;

  DateTime? _signingDate;
  DateTime? _expirationDate;
  Uint8List? _buyerSig;
  Uint8List? _sellerSig;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.voiture;
    _titleController = TextEditingController(text: v != null ? '${v.marque} ${v.modele} - Contract' : '');
    _buyerController = TextEditingController();
    _sellerController = TextEditingController();
    _priceController = TextEditingController();
    _termsController = TextEditingController();
    _carMatriculeController = TextEditingController(text: v?.matricule ?? '');
    _carIdController = TextEditingController();
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

  Future<void> _captureBuyerSig() async {
    final sig = await Navigator.push<Uint8List?>(context, MaterialPageRoute(builder: (_) => const SignatureCaptureScreen(title: 'Capture Buyer Signature')));
    if (sig != null) setState(() => _buyerSig = sig);
  }

  Future<void> _captureSellerSig() async {
    final sig = await Navigator.push<Uint8List?>(context, MaterialPageRoute(builder: (_) => const SignatureCaptureScreen(title: 'Capture Seller Signature')));
    if (sig != null) setState(() => _sellerSig = sig);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final title = _titleController.text.trim();
      final buyer = _buyerController.text.trim();
      final seller = _sellerController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final terms = _termsController.text.trim();
      final carMatricule = _carMatriculeController.text.trim().isEmpty ? null : _carMatriculeController.text.trim();
      final carId = int.tryParse(_carIdController.text.trim());

      final newId = await _service.createContract(
        title: title,
        terms: terms,
        price: price,
        buyerName: buyer,
        buyerContact: '',
        sellerName: seller,
        sellerContact: '',
        carSnapshot: carMatricule != null ? {'matricule': carMatricule, 'model': widget.voiture?.modele ?? ''} : null,
        signingDate: _signingDate,
        expirationDate: _expirationDate,
        carMatricule: carMatricule,
        carId: carId,
      );

      // Attach signatures if any
      try {
        if (_buyerSig != null) await _service.saveSignature(newId, isBuyer: true, signature: _buyerSig!);
        if (_sellerSig != null) await _service.saveSignature(newId, isBuyer: false, signature: _sellerSig!);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract created')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Contract')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 92), // leave room for bottom action bar
            children: [
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 8),
              // Car matricule and Car ID side-by-side
              Row(children: [
                Expanded(child: TextFormField(controller: _carMatriculeController, decoration: const InputDecoration(labelText: 'Car matricule'))),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextFormField(controller: _carIdController, decoration: const InputDecoration(labelText: 'Car ID'), keyboardType: TextInputType.number),
                ),
              ]),
              const SizedBox(height: 8),
              // Disabled field showing car model for clarity
              TextFormField(initialValue: widget.voiture?.modele ?? '-', decoration: const InputDecoration(labelText: 'Car model'), enabled: false),
              const SizedBox(height: 12),
              TextFormField(controller: _buyerController, decoration: const InputDecoration(labelText: 'Buyer name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
              TextFormField(controller: _sellerController, decoration: const InputDecoration(labelText: 'Seller name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              TextFormField(controller: _termsController, decoration: const InputDecoration(labelText: 'Terms'), maxLines: 4),
              const SizedBox(height: 12),
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
              // Signature previews with small capture buttons under each preview
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Buyer signature'),
                      const SizedBox(height: 6),
                      _buyerSig != null
                          ? Image.memory(_buyerSig!, width: 120, height: 48, fit: BoxFit.contain)
                          : Container(width: 120, height: 48, color: Colors.grey[200], child: const Center(child: Text('No signature'))),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: _captureBuyerSig,
                          child: const Icon(Icons.edit, size: 18),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(6), minimumSize: const Size(40, 34)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Seller signature'),
                      const SizedBox(height: 6),
                      _sellerSig != null
                          ? Image.memory(_sellerSig!, width: 120, height: 48, fit: BoxFit.contain)
                          : Container(width: 120, height: 48, color: Colors.grey[200], child: const Center(child: Text('No signature'))),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: _captureSellerSig,
                          child: const Icon(Icons.edit, size: 18),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(6), minimumSize: const Size(40, 34)),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              const SizedBox(height: 16),
              // spacer: action buttons are in the bottom bar for better visibility
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      // Persistent compact bottom action bar so buttons are always visible
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: _saving
                      ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth:2, color: Colors.white))
                      : const Text('Create', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
