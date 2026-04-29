import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Simple i18n service — loads locale JSON from assets and provides t() lookups.
///
/// Usage:
///   await I18n.init('zh');   // at app startup
///   I18n.t('pool_title');    // → '深渊'
///   I18n.t('pool_wishes_count', args: {'count': '42'}); // → '42 个愿望沉睡'
class I18n {
  static Map<String, dynamic> _strings = {};
  static String _locale = 'zh';

  static String get locale => _locale;

  /// Load locale file from assets/locales/{locale}.json
  static Future<void> init([String locale = 'zh']) async {
    _locale = locale;
    final paths = [
      'assets/locales/$locale.json',
      'assets/flutter_assets/assets/locales/$locale.json',
      'lib/locales/$locale.json',
    ];
    for (final path in paths) {
      try {
        final jsonStr = await rootBundle.loadString(path);
        _strings = json.decode(jsonStr) as Map<String, dynamic>;
        debugPrint('✅ I18n loaded from: $path (${_strings.length} keys)');
        return;
      } catch (e) {
        debugPrint('❌ I18n failed to load: $path - $e');
      }
    }
    // Last resort: empty
    _strings = {};
    debugPrint('⚠️ I18n: All paths failed, using empty strings');
  }

  /// Translate a key, optionally substituting {key} placeholders.
  static String t(String key, {Map<String, String>? args}) {
    var s = _strings[key]?.toString() ?? key;
    if (args != null) {
      args.forEach((k, v) {
        s = s.replaceAll('{$k}', v);
      });
    }
    return s;
  }

  /// Check if a key exists
  static bool has(String key) => _strings.containsKey(key);
}
