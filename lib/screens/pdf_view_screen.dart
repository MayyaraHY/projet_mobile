// filepath: c:\FlutterProjects\projet_mobile-voiture\lib\screens\pdf_view_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/bad_word_service.dart';
import '../services/contract_service.dart';
import '../models/contract.dart';
import 'contract_edit_screen.dart';

class PdfViewScreen extends StatelessWidget {
  final String path;
  const PdfViewScreen({required this.path, super.key});

  Future<Uint8List> _readBytes() async {
    final f = File(path);
    return await f.readAsBytes();
  }

  // Try to extract a contract id from the filename if it follows contract_{id}.pdf
  int? _extractContractId() {
    try {
      final file = File(path);
      final name = file.uri.pathSegments.last;
      final reg = RegExp(r'contract_(\d+)\.pdf');
      final m = reg.firstMatch(name);
      if (m != null) return int.parse(m.group(1)!);
    } catch (_) {}
    return null;
  }

  Future<void> _analyzeAndMaybeCensor(BuildContext context) async {
    final id = _extractContractId();
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF not linked to a contract (filename mismatch)')));
      return;
    }

    final service = ContractService();
    showDialog(context: context, barrierDismissible: false, builder: (_) => const AlertDialog(content: SizedBox(height:80, child: Center(child: CircularProgressIndicator()))));
    try {
      final Contract? c = await service.getContract(id);
      Navigator.pop(context);
      if (c == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract not found')));
        return;
      }

      final titleResp = c.title.isNotEmpty ? await BadWordService.analyze(c.title) : null;
      final termsResp = c.terms.isNotEmpty ? await BadWordService.analyze(c.terms) : null;

      final findings = <String, Map<String, dynamic>>{};
      if (titleResp != null && (titleResp['isBad'] ?? titleResp['is-bad'] ?? false)) findings['Title'] = titleResp;
      if (termsResp != null && (termsResp['isBad'] ?? termsResp['is-bad'] ?? false)) findings['Terms'] = termsResp;

      if (findings.isEmpty) {
        await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Analysis Complete'), content: const Text('No bad words found.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
        return;
      }

      // Build a readable summary
      final buffer = StringBuffer();
      findings.forEach((key, resp) {
        final cens = resp['censored'] ?? resp['censoredContent'] ?? '';
        final bad = resp['badWords'] ?? resp['bad-words'] ?? [];
        buffer.writeln('$key: ${cens.isNotEmpty ? cens : '[censored]'}');
        if (bad is List && bad.isNotEmpty) buffer.writeln('Bad words: ${bad.join(', ')}');
        buffer.writeln('');
      });

      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Inappropriate content detected'),
          content: SingleChildScrollView(child: Text(buffer.toString())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'edit'), child: const Text('Open Contract')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, 'censor'), child: const Text('Censor and Save')),
          ],
        ),
      );

      if (action == 'censor') {
        String newTitle = c.title;
        String newTerms = c.terms;
        if (titleResp != null) newTitle = titleResp['censored'] ?? titleResp['censoredContent'] ?? newTitle;
        if (termsResp != null) newTerms = termsResp['censored'] ?? termsResp['censoredContent'] ?? newTerms;
        final updated = c.copyWith(title: newTitle, terms: newTerms);
        await service.updateContract(updated);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract updated with censored content')));

        // Regenerate the PDF and reopen the viewer with the new PDF
        final newPdfPath = await service.generatePdf(updated.id!);
        if (!context.mounted) return;
        if (newPdfPath != null && newPdfPath.isNotEmpty) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PdfViewScreen(path: newPdfPath)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generation failed or returned empty path')));
        }
      } else if (action == 'edit') {
        // Open the contract edit screen
        if (context.mounted) {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => ContractEditScreen(contract: c)));
        }
      }
    } catch (e) {
      try { Navigator.pop(context); } catch (_) {}
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Preview'), actions: [
        IconButton(onPressed: () => _analyzeAndMaybeCensor(context), icon: const Icon(Icons.analytics), tooltip: 'Analyze content (bad words)'),
      ]),
      body: FutureBuilder<Uint8List>(
        future: _readBytes(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError || snap.data == null) return const Center(child: Text('Unable to load PDF'));
          final bytes = snap.data!;
          return PdfPreview(
            build: (format) async => bytes,
            allowPrinting: true,
            allowSharing: true,
          );
        },
      ),
    );
  }
}
