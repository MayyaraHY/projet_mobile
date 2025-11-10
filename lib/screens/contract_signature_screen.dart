// filepath: c:\FlutterProjects\projet_mobile-voiture\lib\screens\contract_signature_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:projetmobile/services/contract_service.dart';

class ContractSignatureScreen extends StatefulWidget {
  final int contractId;
  final bool isBuyer;
  const ContractSignatureScreen({required this.contractId, required this.isBuyer, super.key});

  @override
  State<ContractSignatureScreen> createState() => _ContractSignatureScreenState();
}

class _ContractSignatureScreenState extends State<ContractSignatureScreen> {
  final SignatureController _controller = SignatureController(penStrokeWidth: 2, penColor: Colors.black);
  final ContractService _service = ContractService();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_controller.isEmpty) return;
    setState(() => _saving = true);
    final Uint8List? data = await _controller.toPngBytes();
    if (data != null) {
      await _service.saveSignature(widget.contractId, isBuyer: widget.isBuyer, signature: data);
    }
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final who = widget.isBuyer ? 'Buyer' : 'Seller';
    return Scaffold(
      appBar: AppBar(title: Text('Sign as $who')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: Signature(controller: _controller, backgroundColor: Colors.white),
            ),
          ),
          Row(
            children: [
              TextButton(onPressed: () => _controller.clear(), child: const Text('Clear')),
              const Spacer(),
              ElevatedButton(
                onPressed: _saving ? null : _saveSignature,
                child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Signature'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
