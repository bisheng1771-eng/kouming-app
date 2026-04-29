// M10 Supabase 后端服务
// 负责：匿名登录、云端数据同步、支付记录
// Schema 对齐: users / wishes / fortune_slips / payments

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kouming/shared/models/kouming_models.dart';

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  /// 当前用户 ID
  String? get userId => _client.auth.currentUser?.id;
  bool get isLoggedIn => _client.auth.currentUser != null;

  /// 初始化 Supabase
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://ibffrwevphkkbcfgaift.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImliZmZyd2V2cGhra2JjZmdhaWZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMDI3MTEsImV4cCI6MjA5MjY3ODcxMX0.hWJw5bnMTYfnox2BAk4_0DFDmMi-b2H4mTemZSwWwEA',
    );
    debugPrint('[Supabase] Initialized ✅');
  }

  /// 匿名登录
  Future<bool> signInAnonymously() async {
    try {
      final res = await _client.auth.signInAnonymously();
      debugPrint('[Supabase] Anonymous login: ${res.user?.id}');
      return res.user != null;
    } catch (e) {
      debugPrint('[Supabase] Anonymous login failed: $e');
      return false;
    }
  }

  /// 确保已登录
  Future<void> ensureLogin() async {
    if (!isLoggedIn) {
      await signInAnonymously();
    }
  }

  // ============================================================
  // 用户
  // ============================================================

  /// 创建或更新用户记录
  Future<void> upsertUser(AppState state) async {
    if (userId == null) return;
    try {
      await _client.from('users').upsert({
        'id': userId,
        'total_wishes': state.totalWishes,
        'total_lanterns': _calcTotalLanterns(state),
        'merit': state.meritPoints,
        'merit_level': state.meritLevel,
        'title': _titleForLevel(state.meritLevel),
        'last_active': DateTime.now().toIso8601String(),
      });
      debugPrint('[Supabase] User upserted ✅');
    } catch (e) {
      debugPrint('[Supabase] User upsert failed: $e');
    }
  }

  int _calcTotalLanterns(AppState state) {
    int total = 0;
    for (final w in state.myWishes) {
      total += w.lights;
    }
    total += state.extraLights.values.fold(0, (a, b) => a + b);
    return total;
  }

  String _titleForLevel(int level) {
    if (level >= 20) return '天命之人';
    if (level >= 10) return '觉者';
    if (level >= 5)  return '修行者';
    if (level >= 3)  return '点灯人';
    return '虔诚信众';
  }

  /// 获取云端用户数据
  Future<Map<String, dynamic>?> getUser() async {
    if (userId == null) return null;
    try {
      return await _client.from('users').select().eq('id', userId!).single();
    } catch (e) {
      debugPrint('[Supabase] Get user failed: $e');
      return null;
    }
  }

  // ============================================================
  // 愿望
  // ============================================================

  /// 发布愿望到云端
  Future<void> createWish(Wish wish) async {
    try {
      await _client.from('wishes').insert({
        'id': wish.id,
        'user_id': userId,
        'text': wish.text,
        'category': wish.category,
        'status': 'active',
        'read_count': 0,
        'created_at': wish.createdAt.toIso8601String(),
      });
      debugPrint('[Supabase] Wish created: ${wish.id}');
    } catch (e) {
      debugPrint('[Supabase] Create wish failed: $e');
    }
  }

  /// 获取云端愿望列表（热门排行 / 随机捞愿）
  Future<List<Map<String, dynamic>>> getWishes({
    String? category,
    int limit = 100,
    String? excludeUserId,
  }) async {
    try {
      var q = _client.from('wishes').select().eq('status', 'active');
      if (category != null) q = q.eq('category', category);
      if (excludeUserId != null) q = q.neq('user_id', excludeUserId);
      final res = await q.order('created_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('[Supabase] Get wishes failed: $e');
      return [];
    }
  }

  /// 点灯（更新灯数）
  Future<void> lightWish(String wishId, int lights) async {
    try {
      await _client.from('wishes').update({'read_count': lights}).eq('id', wishId);
      debugPrint('[Supabase] Wish lit: $wishId x$lights');
    } catch (e) {
      debugPrint('[Supabase] Light wish failed: $e');
    }
  }

  // ============================================================
  // 算卦记录 (fortune_slips)
  // ============================================================

  /// 创建算卦记录
  Future<void> createFortuneSlip({
    required String hexagramName,
    required String category,
    required String readingText,
    required String adviceText,
    required int similarCount,
    required double fulfillRate,
    required bool isFree,
  }) async {
    try {
      await _client.from('fortune_slips').insert({
        'user_id': userId,
        'hexagram_name': hexagramName,
        'category': category,
        'reading_text': readingText,
        'advice_text': adviceText,
        'similar_count': similarCount,
        'fulfill_rate': fulfillRate,
        'is_free': isFree,
        'paid': !isFree,
        'price': isFree ? 0 : 6,
      });
      debugPrint('[Supabase] Fortune slip recorded ✅');
    } catch (e) {
      debugPrint('[Supabase] Create fortune slip failed: $e');
    }
  }

  /// 获取相似愿望统计
  Future<Map<String, int>> getFortuneStats(String wishText) async {
    try {
      final keyword = wishText.length > 8 ? wishText.substring(0, 8) : wishText;
      final res = await _client.from('fortune_slips')
          .select('id')
          .ilike('reading_text', '%$keyword%');
      final total = List.from(res).length;
      return {'total': total, 'returned': (total * 0.2).round()};
    } catch (e) {
      return {'total': 0, 'returned': 0};
    }
  }

  // ============================================================
  // 支付记录 (payments)
  // ============================================================

  /// 创建支付记录
  Future<void> createPayment({
    required String productType,
    required double amount,
  }) async {
    try {
      await _client.from('payments').insert({
        'user_id': userId,
        'product_type': productType,
        'amount': amount,
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('[Supabase] Create payment failed: $e');
    }
  }

  /// 查询支付状态
  Future<String?> getPaymentStatus(String orderId) async {
    try {
      final res = await _client.from('payments')
          .select('status').eq('id', orderId).single();
      return res['status'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // 全局统计
  // ============================================================

  /// 获取全局统计
  Future<Map<String, int>> getGlobalStats() async {
    try {
      final res = await _client.from('global_stats').select().single();
      return {
        'total_wishes': res['total_wishes'] ?? 0,
        'total_lanterns': res['total_lanterns'] ?? 0,
        'total_fulfillments': res['total_fulfillments'] ?? 0,
      };
    } catch (e) {
      return {'total_wishes': 0, 'total_lanterns': 0, 'total_fulfillments': 0};
    }
  }

  // ============================================================
  // 同步
  // ============================================================

  /// 从云端拉取用户数据
  Future<AppState> fetchAppState() async {
    final userData = await getUser();
    if (userData == null) return const AppState();

    return AppState(
      throwLimit: 3,
      fishLimit: 3,
      totalFished: 0,
      myWishes: [],
      totalWishes: userData['total_wishes'] ?? 0,
      litWishes: {},
      meritPoints: userData['merit'] ?? 0,
      freeReadingUsed: false,
    );
  }
}
