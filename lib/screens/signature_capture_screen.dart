import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureCaptureScreen extends StatefulWidget {
  final String title;
  const SignatureCaptureScreen({super.key, required this.title});

  @override
  State<SignatureCaptureScreen> createState() => _SignatureCaptureScreenState();
}

class _SignatureCaptureScreenState extends State<SignatureCaptureScreen> {
  final SignatureController _controller = SignatureController(penStrokeWidth: 2, penColor: Colors.black);
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isEmpty) return;
    setState(() => _saving = true);
    final Uint8List? data = await _controller.toPngBytes();
    setState(() => _saving = false);
    if (data != null) Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: Signature(controller: _controller, backgroundColor: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                TextButton(onPressed: () => _controller.clear(), child: const Text('Clear')),
                const Spacer(),
                ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Save')),
              ],
            ),
          )
        ],
      ),
    );
  }
}

