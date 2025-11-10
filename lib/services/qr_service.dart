import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QrService {
  // Embedded RapidAPI key for QRCode-Monkey (per user request).
  // WARNING: embedding secrets in source code is insecure for production.
  static const String _host = 'qrcode-monkey.p.rapidapi.com';
  static const String _endpoint = 'https://qrcode-monkey.p.rapidapi.com/qr/uploadImage';
  static const String _apiKey = '0fcb87abeamshacb3f2183fa53a6p12f6e3jsnadb8c82c601e';

  // Secure storage key and legacy filename for runtime override
  static const String _secureStorageKey = 'qrcode_monkey_rapidapi_key';
  static const String _legacyApiKeyFile = 'qrcode_monkey_rapidapi_key.txt';
  static final _secureStorage = FlutterSecureStorage();
  static String? _runtimeApiKey;

  /// Load runtime API key from secure storage or legacy file (best-effort).
  static Future<void> loadRuntimeApiKey() async {
    try {
      final secure = await _secureStorage.read(key: _secureStorageKey);
      if (secure != null && secure.trim().isNotEmpty) {
        _runtimeApiKey = secure.trim();
        return;
      }

      // fallback to legacy file in application documents
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/$_legacyApiKeyFile');
      if (await f.exists()) {
        final content = await f.readAsString();
        if (content.trim().isNotEmpty) _runtimeApiKey = content.trim();
      }
    } catch (_) {
      // ignore errors
    }
  }

  /// Save the runtime API key to secure storage (and legacy file for compatibility).
  static Future<void> setRuntimeApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      try { await _secureStorage.delete(key: _secureStorageKey); } catch (_) {}
      try {
        final dir = await getApplicationDocumentsDirectory();
        final f = File('${dir.path}/$_legacyApiKeyFile');
        if (await f.exists()) await f.delete();
      } catch (_) {}
      _runtimeApiKey = null;
      return;
    }
    final trimmed = key.trim();
    try { await _secureStorage.write(key: _secureStorageKey, value: trimmed); } catch (_) {}
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/$_legacyApiKeyFile');
      await f.writeAsString(trimmed, flush: true);
    } catch (_) {}
    _runtimeApiKey = trimmed;
  }

  static String? _effectiveApiKey() {
    if (_runtimeApiKey != null && _runtimeApiKey!.isNotEmpty) return _runtimeApiKey;
    if (_apiKey.isNotEmpty) return _apiKey;
    return null;
  }

  /// Return the runtime API key (may be null).
  static String? get runtimeApiKey => _runtimeApiKey;

  /// Generate a QR image for [data] using the RapidAPI QRCode-Monkey endpoint.
  /// Returns image bytes (PNG) on success, or throws on failure.
  static Future<Uint8List> generateQrFromString(String data, {String? apiKeyOverride}) async {
    // Prefer a free public QR provider that doesn't require keys (fast, reliable): api.qrserver.com
    // Build GET URL with encoded data and size
    const int size = 300;
    final freeUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=${size}x$size&format=png&data=${Uri.encodeComponent(data)}';
    try {
      final freeResp = await http.get(Uri.parse(freeUrl)).timeout(const Duration(seconds: 10));
      if (freeResp.statusCode >= 200 && freeResp.statusCode < 300) {
        final ct = (freeResp.headers['content-type'] ?? '').toLowerCase();
        if (ct.contains('image') || freeResp.bodyBytes.isNotEmpty) return freeResp.bodyBytes;
      }
    } catch (_) {
      // ignore and continue to try RapidAPI/local
    }

    // Next try RapidAPI endpoint if a key is configured (runtime override or embedded)
    final key = apiKeyOverride?.trim().isNotEmpty == true ? apiKeyOverride!.trim() : _effectiveApiKey();
    if (key != null && key.isNotEmpty) {
      final headers = {
        'Content-Type': 'application/json',
        'x-rapidapi-host': _host,
        'x-rapidapi-key': key,
      };
      final body = jsonEncode({'data': data, 'size': size});
      try {
        final resp = await http.post(Uri.parse(_endpoint), headers: headers, body: body).timeout(const Duration(seconds: 15));
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final contentType = (resp.headers['content-type'] ?? '').toLowerCase();
          if (contentType.contains('application/json')) {
            final jsonBody = jsonDecode(resp.body);
            if (jsonBody is Map) {
              final candidates = ['image', 'imageBase64', 'base64', 'data', 'qr', 'image_data'];
              for (final k in candidates) {
                if (jsonBody[k] != null && jsonBody[k] is String) {
                  final img = jsonBody[k] as String;
                  try { return base64Decode(img); } catch (_) {}
                }
              }
            }
            // if JSON didn't contain image, fallthrough to local
          }
          if (contentType.contains('image') || resp.bodyBytes.isNotEmpty) return resp.bodyBytes;
        }
      } catch (_) {
        // ignore and fall back to local
      }
    }

    // All providers failed
    throw Exception('QR generation failed: all providers (free API and RapidAPI) failed.');
  }
}
