// filepath: c:\FlutterProjects\projet_mobile-voiture\lib\screens\contract_list_screen.dart
import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../services/contract_service.dart';
import 'contract_details_screen.dart';
import 'contract_edit_screen.dart';
import 'pdf_view_screen.dart';
import 'dart:io';
import '../services/bad_word_service.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../services/qr_service.dart';
import 'voiture_list_screen.dart';
import 'signature_capture_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../services/voiture_service.dart';

class ContractListScreen extends StatefulWidget {
  const ContractListScreen({super.key});

  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen> {
  final ContractService _service = ContractService();
  final VoitureService _voitureService = VoitureService();
  late Future<List<Contract>> _futureList;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _futureList = _service.listContracts();
    });
  }

  Future<void> _generateQrForContract(Contract c) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))),
    );

    try {
      final payload = jsonEncode({
        'id': c.id,
        'title': c.title,
        'buyer': c.buyerName,
        'seller': c.sellerName,
        'created': c.createdAt.toIso8601String(),
      });
      final Uint8List qrBytes = await QrService.generateQrFromString(payload);

      // Save to app documents
      try {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/contract_${c.id ?? DateTime.now().millisecondsSinceEpoch}_qr.png';
        final file = File(path);
        await file.writeAsBytes(qrBytes, flush: true);
        // close loading
        Navigator.pop(context);
        // Show dialog with QR image and path and a Share action
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('QR Code Generated'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(qrBytes, width: 200, height: 200, fit: BoxFit.contain),
                const SizedBox(height: 8),
                Text('Saved to: ${file.path}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await Share.shareXFiles([XFile(file.path)], text: 'QR for contract: ${c.title}');
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
                  }
                },
                child: const Text('Share'),
              ),
            ],
          ),
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR generated and saved')));
      } catch (e) {
        Navigator.pop(context);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save QR: $e')));
      }
    } catch (e) {
      // close loading and show error
      try { Navigator.pop(context); } catch (_) {}
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR generation failed: $e')));
    }
  }

  // Run bad-word analysis on the contract's title and terms before generating QR.
  // Shows the analysis and lets the user decide how to proceed.
  Future<void> _checkAndGenerateQr(Contract c) async {
    // Run analysis (best-effort)
    final analyses = <String, Map<String, dynamic>>{};
    try {
      if (c.title.isNotEmpty) analyses['Title'] = await BadWordService.analyze(c.title);
    } catch (_) {}
    try {
      if (c.terms.isNotEmpty) analyses['Terms'] = await BadWordService.analyze(c.terms);
    } catch (_) {}

    // Build a simple summary
    final hasBad = analyses.values.any((a) => (a['isBad'] ?? a['is-bad'] ?? false) == true || ((a['badWords'] ?? a['bad-words'] ?? []).isNotEmpty));
    if (!hasBad) {
      // no issues -> go straight to generate
      await _generateQrForContract(c);
      return;
    }

    // Build message for dialog
    final buffer = StringBuffer();
    for (final entry in analyses.entries) {
      final a = entry.value;
      final bad = (a['badWords'] ?? a['bad-words'] ?? []) as List? ?? [];
      final censored = a['censored'] ?? a['censoredContent'] ?? '';
      buffer.writeln('${entry.key}: ${censored.isNotEmpty ? censored : '[censored preview]'}');
      if (bad.isNotEmpty) buffer.writeln('Bad words: ${bad.join(', ')}');
      buffer.writeln('');
    }

    final action = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Content analysis before QR'),
      content: SingleChildScrollView(child: Text(buffer.toString())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, 'censor'), child: const Text('Censor & Generate')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, 'proceed'), child: const Text('Generate Anyway')),
      ],
    ));

    if (action == null || action == 'cancel') return;
    if (action == 'censor') {
      // apply censored variants if available, then generate
      if (analyses['Title'] != null && (analyses['Title']!['censored'] ?? analyses['Title']!['censoredContent'] ?? '').toString().isNotEmpty) {
        // temporarily create a copy with censored title/terms for QR payload
        final censoredTitle = analyses['Title']!['censored'] ?? analyses['Title']!['censoredContent'];
        final censoredTerms = analyses['Terms'] != null ? (analyses['Terms']!['censored'] ?? analyses['Terms']!['censoredContent']) : null;
        final tmp = c.copyWith(title: censoredTitle ?? c.title, terms: censoredTerms ?? c.terms);
        await _generateQrForContract(tmp);
        return;
      }
      // if no censored result, just proceed to generate
      await _generateQrForContract(c);
      return;
    }

    // proceed anyway
    await _generateQrForContract(c);
  }

  Future<void> _showCreateDialog() async {
    // Fetch voitures to allow the user to select an existing car
    List voitures = [];
    try {
      voitures = await _voitureService.getAllVoitures();
    } catch (_) {
      voitures = [];
    }
    final titleController = TextEditingController();
    final buyerController = TextEditingController();
    final sellerController = TextEditingController();
    final termsController = TextEditingController();
    final priceController = TextEditingController();
    final carMatriculeController = TextEditingController();
    final carIdController = TextEditingController();
    // Local holders for signatures captured inside the dialog
    Uint8List? buyerSig;
    Uint8List? sellerSig;
    DateTime? signingDate;
    DateTime? expirationDate;
    String? selectedMatricule = voitures.isNotEmpty ? (voitures.first.matricule as String?) : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Contract'),
        content: StatefulBuilder(builder: (ctx, setStateDialog) {
          return SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: buyerController, decoration: const InputDecoration(labelText: 'Buyer name')),
                TextField(controller: sellerController, decoration: const InputDecoration(labelText: 'Seller name')),
                if (voitures.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Text('Select car:'),
                    const SizedBox(width: 8),
                    Expanded(child: DropdownButton<String>(
                      value: selectedMatricule,
                      isExpanded: true,
                      items: voitures.map<DropdownMenuItem<String>>((v) => DropdownMenuItem(value: v.matricule, child: Text('${v.matricule} — ${v.marque} ${v.modele}'))).toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedMatricule = val;
                          carMatriculeController.text = val ?? '';
                        });
                      },
                    )),
                  ]),
                ] else ...[
                  TextField(controller: carMatriculeController, decoration: const InputDecoration(labelText: 'Car matricule (optional)')),
                ],
                const SizedBox(height: 6),
                TextField(controller: carIdController, decoration: const InputDecoration(labelText: 'Car ID (optional, numeric)'), keyboardType: TextInputType.number),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                TextField(controller: termsController, decoration: const InputDecoration(labelText: 'Terms'), maxLines: 3),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text('Signing date: ${signingDate != null ? signingDate!.toLocal().toString().split(' ')[0] : 'not set'}')),
                  TextButton(onPressed: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: signingDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setStateDialog(() => signingDate = picked);
                  }, child: const Text('Pick')),
                ]),
                Row(children: [
                  Expanded(child: Text('Expiration date: ${expirationDate != null ? expirationDate!.toLocal().toString().split(' ')[0] : 'not set'}')),
                  TextButton(onPressed: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: expirationDate ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setStateDialog(() => expirationDate = picked);
                  }, child: const Text('Pick')),
                ]),
                const SizedBox(height: 12),
                // Inline signature capture preview & buttons
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Buyer signature', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          buyerSig != null
                              ? Image.memory(buyerSig!, width: 140, height: 60, fit: BoxFit.contain)
                              : Container(width: 140, height: 60, color: Colors.grey[200], child: const Center(child: Text('No signature'))),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: () async {
                              final sig = await Navigator.push<Uint8List?>(context, MaterialPageRoute(builder: (_) => const SignatureCaptureScreen(title: 'Capture Buyer Signature')));
                              if (sig != null) setStateDialog(() => buyerSig = sig);
                            },
                            child: const Text('Capture Buyer'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seller signature', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          sellerSig != null
                              ? Image.memory(sellerSig!, width: 140, height: 60, fit: BoxFit.contain)
                              : Container(width: 140, height: 60, color: Colors.grey[200], child: const Center(child: Text('No signature'))),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: () async {
                              final sig = await Navigator.push<Uint8List?>(context, MaterialPageRoute(builder: (_) => const SignatureCaptureScreen(title: 'Capture Seller Signature')));
                              if (sig != null) setStateDialog(() => sellerSig = sig);
                            },
                            child: const Text('Capture Seller'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // Collect inputs
              final title = titleController.text.trim();
              final buyer = buyerController.text.trim();
              final seller = sellerController.text.trim();
              final terms = termsController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              final carMatricule = carMatriculeController.text.trim().isEmpty ? null : carMatriculeController.text.trim();
              final carId = int.tryParse(carIdController.text.trim());
              if (title.isEmpty || buyer.isEmpty || seller.isEmpty) return;

              // Show a blocking loading dialog while checking
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const AlertDialog(content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))),
              );

              try {
                // Fields to check
                final fields = <String, String>{
                  'Title': title,
                  'Buyer': buyer,
                  'Seller': seller,
                  'Terms': terms,
                };

                final flagged = <String, Map<String, dynamic>>{};

                // Check each non-empty field with the bad-word API. If the API fails, treat it as a best-effort
                // and continue with contract creation; inform the user that analysis couldn't complete.
                bool analysisFailed = false;
                for (final entry in fields.entries) {
                  if (entry.value.isEmpty) continue;
                  try {
                    final resp = await BadWordService.filterText(entry.value, censorCharacter: true);
                    final isBad = resp['is-bad'] ?? resp['isBad'] ?? false;
                    if (isBad == true) {
                      flagged[entry.key] = {'resp': resp, 'value': entry.value};
                    }
                  } catch (e) {
                    // mark analysis failure but continue; we'll let the user create the contract anyway
                    analysisFailed = true;
                  }
                }
                // Close loading dialog before potentially showing followups
                Navigator.pop(context); // close loading
                if (analysisFailed) {
                  // Non-blocking warning
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Warning: content analysis failed (network/API). Contract creation will continue.')));
                }

                 if (flagged.isNotEmpty) {
                   // Build a preview of censored fields
                   final buffer = StringBuffer();
                   for (final kv in flagged.entries) {
                     final resp = kv.value['resp'] as Map<String, dynamic>;
                     final censored = resp['censored'] ?? resp['censoredContent'] ?? '';
                     final badWords = resp['bad-words'] ?? resp['badWords'] ?? [];
                     buffer.writeln('${kv.key}: ${censored.isNotEmpty ? censored : '[censored]'}');
                     if ((badWords as List).isNotEmpty) buffer.writeln('Bad words: ${badWords.join(", ")}');
                     buffer.writeln('');
                   }

                   final action = await showDialog<String>(
                     context: context,
                     builder: (ctx) => AlertDialog(
                       title: const Text('Inappropriate content detected'),
                       content: SingleChildScrollView(child: Text(buffer.toString())),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
                         TextButton(onPressed: () => Navigator.pop(ctx, 'edit'), child: const Text('Edit')),
                         ElevatedButton(onPressed: () => Navigator.pop(ctx, 'censor'), child: const Text('Censor and create')),
                       ],
                     ),
                   );

                   if (action == null || action == 'cancel') return;
                   if (action == 'edit') return; // simply let user edit the dialog

                   if (action == 'censor') {
                     // Replace flagged fields with censored values from the API
                     for (final kv in flagged.entries) {
                       final key = kv.key;
                       final resp = kv.value['resp'] as Map<String, dynamic>;
                       final censored = resp['censored'] ?? resp['censoredContent'] ?? '';
                       if (key == 'Title') titleController.text = censored;
                       if (key == 'Buyer') buyerController.text = censored;
                       if (key == 'Seller') sellerController.text = censored;
                       if (key == 'Terms') termsController.text = censored;
                     }
                     // proceed to create with censored values below
                   }
                }

                // Final create (either uncensored if nothing flagged, or censored values if user accepted)
                final newId = await _service.createContract(
                  title: titleController.text.trim(),
                  terms: termsController.text.trim(),
                  price: double.tryParse(priceController.text.trim()) ?? 0.0,
                  buyerName: buyerController.text.trim(),
                  buyerContact: '',
                  sellerName: sellerController.text.trim(),
                  sellerContact: '',
                  carSnapshot: null,
                  signingDate: signingDate,
                  expirationDate: expirationDate,
                  carMatricule: carMatricule,
                  carId: carId,
                 );

                // Close the creation dialog
                Navigator.pop(context, true);

                // If signatures were captured inline in the dialog, attach them now
                try {
                  if (buyerSig != null) await _service.saveSignature(newId, isBuyer: true, signature: buyerSig!);
                  if (sellerSig != null) await _service.saveSignature(newId, isBuyer: false, signature: sellerSig!);
                } catch (_) {}

                // Offer to sign immediately (buyer or seller) after creation (optional extra)
                try {
                  final action = await showDialog<String?>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign contract now?'),
                      content: const Text('Would you like to sign the contract now as Buyer or Seller?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, 'later'), child: const Text('Later')),
                        TextButton(onPressed: () => Navigator.pop(ctx, 'seller'), child: const Text('Sign as Seller')),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx, 'buyer'), child: const Text('Sign as Buyer')),
                      ],
                    ),
                  );
                  if (action == 'buyer') {
                    final sig = await Navigator.push<Uint8List?>(context, MaterialPageRoute(builder: (_) => const SignatureCaptureScreen(title: 'Sign as Buyer')));
                    if (sig != null) await _service.saveSignature(newId, isBuyer: true, signature: sig);
                  } else if (action == 'seller') {
                    final sig = await Navigator.push<Uint8List?>(context, MaterialPageRoute(builder: (_) => const SignatureCaptureScreen(title: 'Sign as Seller')));
                    if (sig != null) await _service.saveSignature(newId, isBuyer: false, signature: sig);
                  }
                } catch (_) {}
              } catch (e) {
                // Ensure loading dialog is closed
                try { Navigator.pop(context); } catch (_) {}
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contracts'),
        actions: [
          IconButton(
            tooltip: 'Go to Cars',
            icon: const Icon(Icons.directions_car),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const VoitureListScreen()));
              _refresh();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Contract>>(
        future: _futureList,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final list = snap.data ?? [];
          if (list.isEmpty) return const Center(child: Text('No contracts yet'));
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final c = list[i];
                return ListTile(
                  title: Text(c.title),
                  subtitle: Text('${c.buyerName} ↔ ${c.sellerName} • ${c.status}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${c.price.toStringAsFixed(2)}'),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.qr_code),
                        tooltip: 'Generate QR',
                        onPressed: () async {
                          await _checkAndGenerateQr(c);
                          _refresh();
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
                    // If a PDF exists on disk open it directly for quick viewing, otherwise open details
                    if (c.pdfPath != null) {
                      final file = File(c.pdfPath!);
                      if (await file.exists()) {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewScreen(path: c.pdfPath!)));
                        return;
                      }
                    }
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => ContractDetailsScreen(contractId: c.id!)));
                    _refresh();
                  },
                  onLongPress: () async {
                    final action = await showModalBottomSheet<String>(context: context, builder: (ctx) {
                      return SafeArea(
                        child: Wrap(children: [
                          ListTile(leading: const Icon(Icons.edit), title: const Text('Edit'), onTap: () => Navigator.pop(ctx, 'edit')),
                          ListTile(leading: const Icon(Icons.qr_code), title: const Text('Generate QR'), onTap: () => Navigator.pop(ctx, 'qr')),
                          ListTile(leading: const Icon(Icons.picture_as_pdf), title: const Text('Generate PDF'), onTap: () => Navigator.pop(ctx, 'pdf')),
                           ListTile(leading: const Icon(Icons.open_in_new), title: const Text('Open PDF'), onTap: () => Navigator.pop(ctx, 'open')),
                           ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Delete', style: TextStyle(color: Colors.red)), onTap: () => Navigator.pop(ctx, 'delete')),
                           ListTile(leading: const Icon(Icons.close), title: const Text('Cancel'), onTap: () => Navigator.pop(ctx, 'cancel')),
                         ]),
                       );
                     });

                     if (action == null || action == 'cancel') return;
                     if (action == 'edit') {
                       final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => ContractEditScreen(contract: c)));
                       if (res == true) _refresh();
                     } else if (action == 'qr') {
                      await _checkAndGenerateQr(c);
                      _refresh();
                    } else if (action == 'pdf') {
                      final path = await _service.generatePdf(c.id!);
                      if (path != null && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generated')));
                      _refresh();
                    } else if (action == 'open') {
                      if (c.pdfPath == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No PDF available; generate first')));
                        return;
                      }
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewScreen(path: c.pdfPath!)));
                    } else if (action == 'delete') {
                      final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                        title: const Text('Delete contract?'),
                        content: const Text('This will permanently delete the contract.'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
                      ));
                      if (ok == true) {
                        await _service.deleteContract(c.id!);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract deleted')));
                        _refresh();
                      }
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
