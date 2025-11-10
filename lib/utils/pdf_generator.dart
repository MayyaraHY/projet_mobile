// filepath: c:\FlutterProjects\projet_mobile-voiture\lib\utils\pdf_generator.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/contract.dart';
import '../services/bad_word_service.dart';
import '../services/qr_service.dart';

class PdfGenerator {
  static String _sanitizeFileName(String input) {
    if (input.isEmpty) return '';
    // Replace spaces and disallowed characters with underscore and limit length
    final sanitized = input.replaceAll(RegExp(r"[^a-zA-Z0-9._-]"), '_');
    return sanitized.length > 64 ? sanitized.substring(0, 64) : sanitized;
  }

  static Future<String> generateContractPdf(Contract contract) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat.yMMMMd().add_jm();

    // Helper to embed signature image
    pw.Widget signatureWidget(Uint8List? sigBytes) {
      if (sigBytes == null) return pw.Text('Not signed');
      final image = pw.MemoryImage(sigBytes);
      return pw.Container(width: 200, height: 80, child: pw.Image(image, fit: pw.BoxFit.contain));
    }

    // Run bad-word analysis for title and terms so we can embed a short report in the PDF
    Map<String, dynamic>? titleAnalysis;
    Map<String, dynamic>? termsAnalysis;
    try {
      if (contract.title.isNotEmpty) titleAnalysis = await BadWordService.analyze(contract.title);
      if (contract.terms.isNotEmpty) termsAnalysis = await BadWordService.analyze(contract.terms);
    } catch (_) {
      // analysis is best-effort; failing it should not stop PDF generation
      titleAnalysis = null;
      termsAnalysis = null;
    }

    // Load car image if provided (support: file path, base64 data URI, raw bytes/list<int>, or http URL)
    pw.Widget? carImageWidget;
    try {
      if (contract.carSnapshot != null && contract.carSnapshot!['image'] != null) {
        final imageVal = contract.carSnapshot!['image'];
        Uint8List? bytes;

        if (imageVal is Uint8List) {
          bytes = imageVal;
        } else if (imageVal is List<int>) {
          bytes = Uint8List.fromList(imageVal.cast<int>());
        } else if (imageVal is String) {
          final s = imageVal.trim();
          if (s.startsWith('data:')) {
            final comma = s.indexOf(',');
            if (comma != -1 && comma + 1 < s.length) {
              final b64 = s.substring(comma + 1);
              try {
                bytes = base64Decode(b64);
              } catch (_) {}
            }
          } else if (s.startsWith('http://') || s.startsWith('https://')) {
            try {
              final resp = await http.get(Uri.parse(s));
              if (resp.statusCode >= 200 && resp.statusCode < 300) bytes = resp.bodyBytes;
            } catch (_) {}
          } else {
            // treat as local file path
            try {
              final f = File(s);
              if (await f.exists()) bytes = await f.readAsBytes();
            } catch (_) {}
          }
        }

        if (bytes != null && bytes.isNotEmpty) {
          carImageWidget = pw.Container(height: 160, child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover));
        }
      }
    } catch (_) {
      carImageWidget = null;
    }

    // Generate QR code for contract info (best-effort)
    pw.Widget? qrWidget;
    String? qrError;
    try {
      final payload = jsonEncode({
        'id': contract.id,
        'title': contract.title,
        'buyer': contract.buyerName,
        'seller': contract.sellerName,
        'created': contract.createdAt.toIso8601String(),
      });
      final qrBytes = await QrService.generateQrFromString(payload);
      qrWidget = pw.Container(
        width: 100,
        height: 100,
        child: pw.Image(pw.MemoryImage(qrBytes), fit: pw.BoxFit.contain),
      );

      // Save QR image to app documents for later use
      try {
        final dir = await getApplicationDocumentsDirectory();
        final safeName = _sanitizeFileName(contract.title) ;
        final qrPath = File('${dir.path}/contract_${contract.id ?? DateTime.now().millisecondsSinceEpoch}${safeName.isNotEmpty ? '_$safeName' : ''}_qr.png');
        await qrPath.writeAsBytes(qrBytes, flush: true);
      } catch (_) {}
    } catch (e) {
      qrWidget = null;
      try { qrError = e.toString(); } catch (_) { qrError = 'Unknown error'; }
    }

    pdf.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Header(level: 0, child: pw.Text('Contract: ${contract.title}', style: pw.TextStyle(fontSize: 20)))),
              if (qrWidget != null) qrWidget,
            ],
          ),
          if (carImageWidget != null) pw.SizedBox(height: 8),
          if (carImageWidget != null) carImageWidget,
          pw.SizedBox(height: 8),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Created: ${dateFmt.format(contract.createdAt)}'),
            pw.Text('Status: ${contract.status}'),
          ]),
          pw.SizedBox(height: 4),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Signing date: ${contract.signingDate != null ? dateFmt.format(contract.signingDate!) : 'N/A'}'),
            pw.Text('Expiration date: ${contract.expirationDate != null ? dateFmt.format(contract.expirationDate!) : 'N/A'}'),
          ]),
          pw.SizedBox(height: 4),
          pw.Text('Car matricule: ${contract.carMatricule ?? (contract.carSnapshot != null ? (contract.carSnapshot!['matricule'] ?? 'N/A') : 'N/A')}'),
           pw.SizedBox(height: 12),
          pw.Text('Buyer', style: pw.TextStyle(fontSize: 16, decoration: pw.TextDecoration.underline)),
          pw.Bullet(text: 'Name: ${contract.buyerName}'),
          pw.Bullet(text: 'Contact: ${contract.buyerContact}'),
          pw.SizedBox(height: 8),
          pw.Text('Seller', style: pw.TextStyle(fontSize: 16, decoration: pw.TextDecoration.underline)),
          pw.Bullet(text: 'Name: ${contract.sellerName}'),
          pw.Bullet(text: 'Contact: ${contract.sellerContact}'),
          pw.SizedBox(height: 8),
          pw.Text('Car Snapshot', style: pw.TextStyle(fontSize: 16, decoration: pw.TextDecoration.underline)),
          if (contract.carSnapshot != null)
            ...contract.carSnapshot!.entries.map((e) => pw.Text('${e.key}: ${e.value}')),
          pw.SizedBox(height: 8),
          pw.Text('Price: \$${contract.price.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 12),
          pw.Text('Terms', style: pw.TextStyle(fontSize: 16, decoration: pw.TextDecoration.underline)),
          pw.Text(contract.terms),
          pw.SizedBox(height: 12),
          // Bad-word analysis report
          pw.Text('Content Analysis', style: pw.TextStyle(fontSize: 16, decoration: pw.TextDecoration.underline)),
          if (titleAnalysis != null) pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Title Analysis:'),
              pw.Text('Is bad: ${titleAnalysis['isBad'] ?? titleAnalysis['is-bad'] ?? false}'),
              if (titleAnalysis['censored'] != null) pw.Text('Censored: ${titleAnalysis['censored']}'),
              if ((titleAnalysis['badWords'] ?? []).isNotEmpty) pw.Text('Bad words: ${(titleAnalysis['badWords'] ?? []).join(", ")}'),
            ],
          ),
          if (termsAnalysis != null) pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Terms Analysis:'),
              pw.Text('Is bad: ${termsAnalysis['isBad'] ?? termsAnalysis['is-bad'] ?? false}'),
              if (termsAnalysis['censored'] != null) pw.Text('Censored: ${termsAnalysis['censored']}'),
              if ((termsAnalysis['badWords'] ?? []).isNotEmpty) pw.Text('Bad words: ${(termsAnalysis['badWords'] ?? []).join(", ")}'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(children: [pw.Text('Buyer Signature'), signatureWidget(contract.signatureBuyer)]),
              pw.Column(children: [pw.Text('Seller Signature'), signatureWidget(contract.signatureSeller)]),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('Document generated on ${dateFmt.format(DateTime.now())}', style: pw.TextStyle(fontSize: 10)),
          if (qrWidget != null) pw.Text('Scan QR code to view contract details', style: pw.TextStyle(fontSize: 10)),
          if (qrError != null) pw.Padding(padding: const pw.EdgeInsets.only(top:6), child: pw.Text('QR generation error: ${qrError}', style: pw.TextStyle(fontSize: 9))),
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final safeName = _sanitizeFileName(contract.title);
    final fileName = 'contract_${contract.id ?? DateTime.now().millisecondsSinceEpoch}${safeName.isNotEmpty ? '_$safeName' : ''}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
