import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Simple local profanity list to be used as a fallback and for word extraction.
final List<String> _localProfanity = [
  'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'damn', 'crap', 'f**k'
];

final List<String> _localProfanityPhrases = ['fuck you', 'go to hell', 'screw you'];

class BadWordService {
  // Runtime key support (kept for compatibility with SettingsScreen). Not used by PurgoMalum.
  static const String _apiKeyFileName = 'bad_word_api_key.txt';
  static const String _secureStorageKey = 'bad_word_api_key_secure';
  static final _secureStorage = FlutterSecureStorage();
  static String? _runtimeApiKey;

  static Future<void> loadRuntimeApiKey() async {
    try {
      final secure = await _secureStorage.read(key: _secureStorageKey);
      if (secure != null && secure.trim().isNotEmpty) {
        _runtimeApiKey = secure.trim();
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/$_apiKeyFileName');
      if (await f.exists()) {
        final content = await f.readAsString();
        if (content.trim().isNotEmpty) _runtimeApiKey = content.trim();
      }
    } catch (_) {}
  }

  static Future<void> setRuntimeApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      try { await _secureStorage.delete(key: _secureStorageKey); } catch (_) {}
      try {
        final dir = await getApplicationDocumentsDirectory();
        final f = File('${dir.path}/$_apiKeyFileName');
        if (await f.exists()) await f.delete();
      } catch (_) {}
      _runtimeApiKey = null;
      return;
    }
    final trimmed = key.trim();
    try { await _secureStorage.write(key: _secureStorageKey, value: trimmed); } catch (_) {}
    try { final dir = await getApplicationDocumentsDirectory(); final f = File('${dir.path}/$_apiKeyFileName'); await f.writeAsString(trimmed, flush: true); } catch (_) {}
    _runtimeApiKey = trimmed;
  }

  static String? get runtimeApiKey => _runtimeApiKey;

  // PurgoMalum free profanity service
  // Example JSON endpoint: https://www.purgomalum.com/service/json?text=your%20text
  static const String _purgomalumJson = 'https://www.purgomalum.com/service/json?text=';

  /// Call PurgoMalum to get a censored version of the text.
  /// Returns a map compatible with the old API shape: { 'is-bad': bool, 'censored': String, 'bad-words': List<String>, 'raw': Map }
  static Future<Map<String, dynamic>> filterText(String content, {bool? censorCharacter}) async {
    final result = <String, dynamic>{'is-bad': false, 'censored': content, 'bad-words': <String>[], 'raw': null};
    if (content.isEmpty) return result;

    try {
      final url = '$_purgomalumJson${Uri.encodeComponent(content)}';
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        // PurgoMalum JSON returns {"result":"censored text"}
        try {
          final Map<String, dynamic> jsonBody = jsonDecode(resp.body) as Map<String, dynamic>;
          final censored = (jsonBody['result'] ?? content).toString();
          result['censored'] = censored;
          result['raw'] = jsonBody;
          result['is-bad'] = censored != content;
          if (result['is-bad'] == true) {
            result['bad-words'] = _extractMaskedWords(content, censored);
          }
          return result;
        } catch (_) {
          // Fallback: if parse fails, try to treat resp.body as plain censored text
          final censored = resp.body ?? content;
          result['censored'] = censored;
          result['is-bad'] = censored != content;
          if (result['is-bad'] == true) result['bad-words'] = _extractMaskedWords(content, censored);
          return result;
        }
      }
    } catch (_) {
      // network or timeout — fall through to local detection
    }

    // Local fallback
    final local = _localDetect(content);
    if (local.isNotEmpty) {
      result['is-bad'] = true;
      result['bad-words'] = local;
      result['censored'] = _maskWordsLocally(content, local, censorCharacter == true ? '*' : '*');
    }
    return result;
  }

  static Future<List<String>> findBadWords(String content) async {
    if (content.isEmpty) return [];
    try {
      final resp = await filterText(content, censorCharacter: false);
      final bad = resp['bad-words'] ?? [];
      if (bad is List) return bad.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    } catch (_) {}
    return _localDetect(content);
  }

  static Future<bool> isBad(String content) async {
    if (content.isEmpty) return false;
    try {
      final resp = await filterText(content, censorCharacter: false);
      return resp['is-bad'] ?? false;
    } catch (_) {
      final local = _localDetect(content);
      return local.isNotEmpty;
    }
  }

  static Future<String> censorText(String content, {String censorCharacter = '*'}) async {
    if (content.isEmpty) return content;
    try {
      final resp = await filterText(content, censorCharacter: true);
      final censored = resp['censored'] ?? content;
      return censored.toString();
    } catch (_) {
      final local = _localDetect(content);
      if (local.isEmpty) return content;
      return _maskWordsLocally(content, local, censorCharacter);
    }
  }

  static Future<Map<String, dynamic>> analyze(String content, {bool censorCharacter = true}) async {
    final out = <String, dynamic>{'isBad': false, 'censored': null, 'badWords': <String>[], 'raw': null};
    if (content.isEmpty) return out;
    try {
      final resp = await filterText(content, censorCharacter: censorCharacter);
      out['raw'] = resp['raw'];
      out['isBad'] = resp['is-bad'] ?? false;
      out['censored'] = resp['censored'];
      out['badWords'] = (resp['bad-words'] ?? []).map((e) => e.toString()).toList();
      if ((out['isBad'] == false) || (out['badWords'] as List).isEmpty) {
        final local = _localDetect(content);
        if (local.isNotEmpty) {
          out['isBad'] = true;
          final existing = List<String>.from(out['badWords'] ?? []);
          for (final w in local) if (!existing.contains(w)) existing.add(w);
          out['badWords'] = existing;
          out['censored'] ??= _maskWordsLocally(content, local, '*');
        }
      }
    } catch (_) {
      final local = _localDetect(content);
      if (local.isNotEmpty) {
        out['isBad'] = true;
        out['badWords'] = local;
        out['censored'] = _maskWordsLocally(content, local, '*');
      }
    }
    return out;
  }

  // --- Helpers ---
  static List<String> _extractMaskedWords(String original, String censored) {
    final origTokens = original.split(RegExp(r"\s+"));
    final censTokens = censored.split(RegExp(r"\s+"));
    final found = <String>{};
    final len = origTokens.length < censTokens.length ? origTokens.length : censTokens.length;
    for (int i = 0; i < len; i++) {
      final o = origTokens[i];
      final c = censTokens[i];
      if (c.contains('*')) {
        // consider punctuation
        final w = o.replaceAll(RegExp(r"[^a-zA-Z0-9']"), '');
        if (w.isNotEmpty) found.add(w.toLowerCase());
      }
    }
    return found.toList();
  }

  static String _maskWordsLocally(String content, List<String> words, String censorChar) {
    var out = content;
    for (final w in words) {
      if (w.trim().isEmpty) continue;
      final pattern = RegExp(r'\b' + RegExp.escape(w) + r'\b', caseSensitive: false);
      final mask = List.filled(w.length, censorChar).join();
      out = out.replaceAll(pattern, mask);
    }
    return out;
  }

  static List<String> _localDetect(String content) {
    final found = <String>{};
    final lower = content.toLowerCase();
    for (final phrase in _localProfanityPhrases) {
      if (lower.contains(phrase)) found.add(phrase);
    }
    final tokens = lower.split(RegExp(r"[^a-zA-Z0-9']+"));
    for (final t in tokens) {
      if (t.isEmpty) continue;
      if (_localProfanity.contains(t)) found.add(t);
    }
    return found.toList();
  }
}
