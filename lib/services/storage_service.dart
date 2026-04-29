// M8 本地持久化存储服务 - SharedPreferences + JSON
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kouming/shared/models/kouming_models.dart';

class StorageService {
  static const _keyAppState = 'kouming_app_state';
  static const _keyPurchases = 'kouming_purchases';
  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    debugPrint('[Storage] initialized');
  }

  Future<void> saveAppState(AppState state) async {
    await init();
    await _prefs!.setString(_keyAppState, jsonEncode(_stateToJson(state)));
  }

  Future<AppState?> loadAppState() async {
    await init();
    final raw = _prefs!.getString(_keyAppState);
    if (raw == null) return null;
    try {
      return _stateFromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Storage] load failed: ');
      return null;
    }
  }

  Future<void> recordPurchase(String itemId, int priceYuan) async {
    await init();
    final list = _prefs!.getStringList(_keyPurchases) ?? [];
    list.add('||');
    await _prefs!.setStringList(_keyPurchases, list);
  }

  Future<void> clearAll() async { await init(); await _prefs!.clear(); }

  Map<String, dynamic> _stateToJson(AppState s) => {
    'throwLimit': s.throwLimit, 'fishLimit': s.fishLimit, 'totalFished': s.totalFished,
    'myWishes': s.myWishes.map((w) => {'id': w.id, 'text': w.text, 'category': w.category, 'lights': w.lights, 'createdAt': w.createdAt.toIso8601String()}).toList(),
    'totalWishes': s.totalWishes, 'litWishes': s.litWishes.toList(), 'meritPoints': s.meritPoints,
    'freeReadingUsed': s.freeReadingUsed,
    'capsules': s.capsules.map((c) => {'id': c.id, 'wishText': c.wishText, 'createdAt': c.createdAt.toIso8601String(), 'dueDate': c.dueDate.toIso8601String(), 'category': c.category, 'status': c.status.name}).toList(),
    'fishedCount': s.fishedCount,
    'extraLights': s.extraLights.entries.map((e) => {'k': e.key, 'v': e.value}).toList(),
    'lastResetDate': s.lastResetDate,
    'badges': s.badges.map((b) => {'id': b.id, 'label': b.label, 'emoji': b.emoji, 'isMerit': b.isMerit, 'earned': b.earned}).toList(),
  };

  AppState _stateFromJson(Map<String, dynamic> j) => AppState(
    throwLimit: j['throwLimit'] as int? ?? 3, fishLimit: j['fishLimit'] as int? ?? 5, totalFished: j['totalFished'] as int? ?? 0,
    myWishes: (j['myWishes'] as List?)?.map((w) => Wish(id: w['id'] as String, text: w['text'] as String, category: w['category'] as String, lights: w['lights'] as int? ?? 0, createdAt: DateTime.parse(w['createdAt'] as String))).toList() ?? [],
    totalWishes: j['totalWishes'] as int? ?? 8347,
    litWishes: Set<String>.from(j['litWishes'] as List? ?? []),
    meritPoints: j['meritPoints'] as int? ?? 0,
    freeReadingUsed: j['freeReadingUsed'] as bool? ?? false,
    capsules: (j['capsules'] as List?)?.map((c) => WishCapsule(id: c['id'] as String, wishText: c['wishText'] as String, createdAt: DateTime.parse(c['createdAt'] as String), dueDate: DateTime.parse(c['dueDate'] as String), category: c['category'] as String, status: CapsuleStatus.values.firstWhere((e) => e.name == c['status'], orElse: () => CapsuleStatus.waiting))).toList() ?? [],
    fishedCount: j['fishedCount'] as int? ?? 0,
    extraLights: Map.fromEntries((j['extraLights'] as List?)?.map((e) => MapEntry(e['k'] as String, e['v'] as int)) ?? []),
    lastResetDate: j['lastResetDate'] as String? ?? '',
    badges: (j['badges'] as List?)?.map((b) => KouBadge(id: b['id'] as String, label: b['label'] as String, emoji: b['emoji'] as String, isMerit: b['isMerit'] as bool? ?? false, earned: b['earned'] as bool? ?? false)).toList() ?? [],
  );
}
