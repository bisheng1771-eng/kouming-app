// M8 本地持久化存储服务 - SharedPreferences + JSON
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kouming/shared/models/kouming_models.dart';

class StorageService {
  static const _keyAppStatePrefix = 'kouming_app_state_';
  static const _keyPurchases = 'kouming_purchases';
  static const _keyCurrentUser = 'kouming_current_user';
  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    debugPrint('[Storage] initialized');
  }

  String _getStateKey(String nickname) => '$_keyAppStatePrefix$nickname';

  Future<void> saveAppState(AppState state) async {
    await init();
    final nickname = state.nickname;
    if (nickname.isEmpty) return; // 未登录不保存
    await _prefs!.setString(_getStateKey(nickname), jsonEncode(_stateToJson(state)));
    await _prefs!.setString(_keyCurrentUser, nickname);
  }

  Future<AppState?> loadAppState({String? nickname}) async {
    await init();
    // 如果指定了昵称，加载该昵称的数据
    if (nickname != null && nickname.isNotEmpty) {
      final raw = _prefs!.getString(_getStateKey(nickname));
      if (raw == null) return null;
      try {
        return _stateFromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e, stack) {
        debugPrint('[Storage] load failed for $nickname: $e');
        return null;
      }
    }
    // 否则加载当前用户的数据
    final currentUser = _prefs!.getString(_keyCurrentUser);
    if (currentUser == null || currentUser.isEmpty) return null;
    final raw = _prefs!.getString(_getStateKey(currentUser));
    if (raw == null) return null;
    try {
      return _stateFromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, stack) {
      debugPrint('[Storage] load failed: $e');
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

  /// 获取所有已注册的昵称列表
  Future<List<String>> getAllNicknames() async {
    await init();
    final keys = _prefs!.getKeys();
    return keys
        .where((k) => k.startsWith(_keyAppStatePrefix))
        .map((k) => k.substring(_keyAppStatePrefix.length))
        .toList();
  }

  Map<String, dynamic> _stateToJson(AppState s) => {
    'throwLimit': s.throwLimit, 'fishLimit': s.fishLimit, 'totalFished': s.totalFished,
    'myWishes': s.myWishes.map((w) => {'id': w.id, 'text': w.text, 'category': w.category, 'lights': w.lights, 'blessingCount': w.blessingCount, 'blessings': w.blessings, 'fulfillText': w.fulfillText, 'createdAt': w.createdAt.toIso8601String()}).toList(),
    'totalWishes': s.totalWishes, 'litWishes': s.litWishes.toList(), 'meritPoints': s.meritPoints,
    'freeReadingUsed': s.freeReadingUsed,
    'freeOracleUsed': s.freeOracleUsed,
    'freeFateDrawUsed': s.freeFateDrawUsed,
    'capsules': s.capsules.map((c) => {'id': c.id, 'wishText': c.wishText, 'createdAt': c.createdAt.toIso8601String(), 'dueDate': c.dueDate.toIso8601String(), 'category': c.category, 'status': c.status.name, 'blessingCount': c.blessingCount, 'blessings': c.blessings}).toList(),
    'fishedCount': s.fishedCount,
    'extraLights': s.extraLights.entries.map((e) => {'k': e.key, 'v': e.value}).toList(),
    'lastResetDate': s.lastResetDate,
    'badges': s.badges.map((b) => {'id': b.id, 'label': b.label, 'emoji': b.emoji, 'isMerit': b.isMerit, 'earned': b.earned}).toList(),
    'userId': s.userId,
    'nickname': s.nickname,
  };

  AppState _stateFromJson(Map<String, dynamic> j) => AppState(
    throwLimit: j['throwLimit'] as int? ?? 3, fishLimit: j['fishLimit'] as int? ?? 5, totalFished: j['totalFished'] as int? ?? 0,
    myWishes: (j['myWishes'] as List?)?.map((w) => Wish(id: w['id'] as String, text: w['text'] as String, category: w['category'] as String, lights: w['lights'] as int? ?? 0, blessingCount: w['blessingCount'] as int? ?? 0, blessings: (w['blessings'] as List?)?.cast<String>() ?? const [], fulfillText: w['fulfillText'] as String?, createdAt: DateTime.parse(w['createdAt'] as String))).toList() ?? [],
    totalWishes: j['totalWishes'] as int? ?? 8347,
    litWishes: Set<String>.from(j['litWishes'] as List? ?? []),
    meritPoints: j['meritPoints'] as int? ?? 0,
    freeReadingUsed: j['freeReadingUsed'] as bool? ?? false,
    freeOracleUsed: j['freeOracleUsed'] as int? ?? 0,
    freeFateDrawUsed: j['freeFateDrawUsed'] as int? ?? 0,
    capsules: (j['capsules'] as List?)?.map((c) {
      try {
        return WishCapsule(
          id: c['id'] as String? ?? '',
          wishText: c['wishText'] as String? ?? '',
          createdAt: DateTime.tryParse(c['createdAt'] as String? ?? '') ?? DateTime.now(),
          dueDate: DateTime.tryParse(c['dueDate'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 30)),
          category: c['category'] as String? ?? 'general',
          status: CapsuleStatus.values.firstWhere(
            (e) => e.name == c['status'],
            orElse: () => CapsuleStatus.waiting,
          ),
          blessingCount: c['blessingCount'] as int? ?? 0,
          blessings: (c['blessings'] as List?)?.cast<String>() ?? [],
        );
      } catch (e) {
        debugPrint('[Storage] Failed to parse capsule: $e');
        return null;
      }
    }).whereType<WishCapsule>().toList() ?? [],
    fishedCount: j['fishedCount'] as int? ?? 0,
    extraLights: Map.fromEntries((j['extraLights'] as List?)?.map((e) => MapEntry(e['k'] as String, e['v'] as int)) ?? []),
    lastResetDate: j['lastResetDate'] as String? ?? '',
    badges: (j['badges'] as List?)?.map((b) => KouBadge(id: b['id'] as String, label: b['label'] as String, emoji: b['emoji'] as String, isMerit: b['isMerit'] as bool? ?? false, earned: b['earned'] as bool? ?? false)).toList() ?? [],
    userId: j['userId'] as String? ?? '',
    nickname: j['nickname'] as String? ?? '',
  );
}
