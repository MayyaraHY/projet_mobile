// filepath: c:\FlutterProjects\projet_mobile-voiture\lib\screens\contract_details_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../services/contract_service.dart';
import 'contract_signature_screen.dart';
import 'contract_edit_screen.dart';
import '../services/bad_word_service.dart';
import '../services/voiture_service.dart';
import 'voiture_details_screen.dart';
import 'pdf_view_screen.dart';

class ContractDetailsScreen extends StatefulWidget {
  final int contractId;
  const ContractDetailsScreen({required this.contractId, super.key});

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  final ContractService _service = ContractService();
  late Future<Contract?> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getContract(widget.contractId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getContract(widget.contractId);
    });
  }

  Widget _signaturePreview(Uint8List? bytes) {
    if (bytes == null) return const Text('Not signed');
    return Image.memory(bytes, width: 200, height: 80, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contract Details')),
      body: FutureBuilder<Contract?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final c = snap.data;
          if (c == null) return const Center(child: Text('Contract not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Status: ${c.status}'),
                const Divider(),
                Text('Buyer: ${c.buyerName}\nContact: ${c.buyerContact}'),
                const SizedBox(height: 8),
                Text('Seller: ${c.sellerName}\nContact: ${c.sellerContact}'),
                const Divider(),
                if (c.carSnapshot != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: c.carSnapshot!.entries.map((e) => Text('${e.key}: ${e.value}')).toList(),
                  ),
                const Divider(),
                Text('Price: \$${c.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Terms', style: Theme.of(context).textTheme.titleMedium),
                Text(c.terms),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => ContractSignatureScreen(contractId: c.id!, isBuyer: true)));
                        _refresh();
                      },
                      child: const Text('Sign as Buyer'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => ContractSignatureScreen(contractId: c.id!, isBuyer: false)));
                        _refresh();
                      },
                      child: const Text('Sign as Seller'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final path = await _service.generatePdf(c.id!);
                        if (path != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generated')));
                        }
                        _refresh();
                      },
                      child: const Text('Generate PDF'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Edit
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ContractEditScreen(contract: c)));
                        if (result == true) _refresh();
                      },
                      child: const Text('Edit'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                          title: const Text('Delete contract?'),
                          content: const Text('This will permanently delete the contract.'),
                          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
                        ));
                        if (ok == true) {
                          await _service.deleteContract(c.id!);
                          if (mounted) Navigator.pop(context, true);
                        }
                      },
                      child: const Text('Delete'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Analyze the contract title and terms using the BadWordService
                        final Contract? current = await _service.getContract(c.id!);
                        if (current == null) return;

                        // Show loading
                        if (!mounted) return;
                        showDialog(context: context, barrierDismissible: false, builder: (_) => const AlertDialog(content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))));

                        try {
                          final Map<String, dynamic>? titleResp = current.title.isNotEmpty
                              ? await BadWordService.filterText(current.title, censorCharacter: true)
                              : null;
                          final Map<String, dynamic>? termsResp = current.terms.isNotEmpty
                              ? await BadWordService.filterText(current.terms, censorCharacter: true)
                              : null;

                          if (!mounted) return;
                          Navigator.pop(context); // close loading

                          // Collect findings
                          final findings = <String, Map<String, dynamic>>{};
                          if (titleResp != null) findings['Title'] = titleResp;
                          if (termsResp != null) findings['Terms'] = termsResp;

                          // Check if any is marked bad
                          final bad = <String, Map<String, dynamic>>{};
                          findings.forEach((key, resp) {
                            final isBad = resp['is-bad'] ?? resp['isBad'] ?? false;
                            if (isBad == true) bad[key] = resp;
                          });

                          if (bad.isEmpty) {
                            if (!mounted) return;
                            await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Analysis Complete'), content: const Text('No bad words found.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
                            return;
                          }

                          // Build message with censored preview and bad-words list
                          final buffer = StringBuffer();
                          bad.forEach((key, resp) {
                            final censored = resp['censored'] ?? resp['censoredContent'] ?? '';
                            final badWords = resp['bad-words'] ?? resp['badWords'] ?? [];
                            buffer.writeln('$key: ${censored.isNotEmpty ? censored : '[censored]'}');
                            if ((badWords as List).isNotEmpty) buffer.writeln('Bad words: ${badWords.join(', ')}');
                            buffer.writeln('');
                          });

                          if (!mounted) return;
                          final action = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Inappropriate content detected'),
                              content: SingleChildScrollView(child: Text(buffer.toString())),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, 'edit'), child: const Text('Edit')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, 'censor'), child: const Text('Censor and Save')),
                              ],
                            ),
                          );

                          if (action == null || action == 'cancel') return;
                          if (action == 'edit') {
                            // Open edit screen to let user edit content
                            if (!mounted) return;
                            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => ContractEditScreen(contract: current)));
                            if (res == true) _refresh();
                            return;
                          }

                          if (action == 'censor') {
                            // Build censored values using API responses (if provided); fallback to simple mask
                            String newTitle = current.title;
                            String newTerms = current.terms;
                            if (titleResp != null) {
                              newTitle = (titleResp['censored'] ?? titleResp['censoredContent'] ?? newTitle) as String;
                            }
                            if (termsResp != null) {
                              newTerms = (termsResp['censored'] ?? termsResp['censoredContent'] ?? newTerms) as String;
                            }

                            final updated = current.copyWith(title: newTitle, terms: newTerms);
                            await _service.updateContract(updated);
                            // Regenerate PDF using the updated contract and open it for preview
                            try {
                              final pdfPath = await _service.generatePdf(updated.id!);
                              if (!mounted) return;
                              if (pdfPath != null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract updated and PDF generated')));
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewScreen(path: pdfPath)));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract updated')));
                              }
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF generation failed: $e')));
                            }
                            _refresh();
                          }
                        } catch (e) {
                          if (mounted) Navigator.pop(context); // close loading
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis error: $e')));
                        }
                      },
                      child: const Text('Analyze'),
                    ),
                    if (c.carSnapshot != null || c.carId != null)
                      ElevatedButton(
                        onPressed: () async {
                          // Try to open the car details screen using matricule from snapshot or via id mapping
                          String? matricule;
                          if (c.carSnapshot != null && c.carSnapshot!['matricule'] != null) {
                            matricule = c.carSnapshot!['matricule'].toString();
                          }
                          if (matricule == null && c.carId != null) {
                            // carId might be an integer PK; if you store matricule as id, attempt string
                            matricule = c.carId.toString();
                          }

                          if (matricule != null) {
                            try {
                              final voiture = await VoitureService().getVoitureByMatricule(matricule);
                              if (voiture != null) {
                                if (!mounted) return;
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => VoitureDetailsScreen(voiture: voiture)));
                                _refresh();
                                return;
                              }
                            } catch (e) {
                              // ignore and fall back to not found
                            }
                          }

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Car not found')));
                        },
                        child: const Text('View Car'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Buyer signature:'),
                _signaturePreview(c.signatureBuyer),
                const SizedBox(height: 8),
                Text('Seller signature:'),
                _signaturePreview(c.signatureSeller),
                const SizedBox(height: 12),
                if (c.pdfPath != null) Text('PDF: ${c.pdfPath}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
