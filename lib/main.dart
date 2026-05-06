import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/ai_service.dart';
import 'package:kouming/services/storage_service.dart';
import 'package:kouming/services/i18n_service.dart';
import 'package:kouming/services/supabase_service.dart';
import 'package:kouming/features/pool/pool_page.dart';
import 'package:kouming/features/profile/profile_page.dart';
import 'package:kouming/features/shop/offering_shop.dart';
import 'package:kouming/features/shop/fulfill_ceremony.dart';
// import 'package:kouming/features/shop/fate_draw_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load i18n
  await I18n.init('zh'); // TODO: detect system locale
  // Init Supabase (M10 云端)
  await SupabaseService.init();
  // System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  // Portrait only
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const KouMingApp());
}

class KouMingApp extends StatelessWidget {
  const KouMingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: I18n.t('app_name'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'MaShanZheng',
        scaffoldBackgroundColor: KouMingTheme.deep,
        colorScheme: ColorScheme.dark(
          primary: KouMingTheme.gold,
          secondary: KouMingTheme.purple,
          surface: KouMingTheme.surface,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final AiService _aiService = AiService();
  final StorageService _storage = StorageService();
  final SupabaseService _supabase = SupabaseService();
  bool _loading = true;
  AppState _state = const AppState();

  @override
  void initState() {
    super.initState();
    AiService.configure(
      apiKey: const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''), // Gemini API Key（优先）
      proxy: 'http://127.0.0.1:1', // Clash 代理
      fallbackApiKey: const String.fromEnvironment('DASHSCOPE_API_KEY', defaultValue: ''), // 阿里云百炼（备用，国内直连）
    );
    _init();
  }

  Future<void> _init() async {
    try {
      debugPrint('[Init] Step 1: Loading local state...');
      // 1. 加载本地状态（根据当前登录用户）
      AppState? saved;
      try {
        saved = await _storage.loadAppState();
        debugPrint('[Init] Local state loaded: ${saved != null ? 'yes' : 'no'}');
      } catch (e, stack) {
        debugPrint('[Init] Load local state failed: $e');
        debugPrint('[Init] Stack: $stack');
      }
      
      if (saved != null && saved.nickname.isNotEmpty) {
        // 已登录，加载用户数据
        _state = saved.checkDailyReset().evaluateBadges();
        debugPrint('[Init] User ${saved.nickname} logged in, loading data');
        
        // 应用等级福利
        _state = _state.copyWith(
          throwLimit: _state.levelBenefits.dailyThrowLimit,
          fishLimit: _state.levelBenefits.dailyFishLimit,
        );
        
        // 异步同步到云端
        _syncToCloud();
      } else {
        // 未登录，使用空状态
        debugPrint('[Init] No user logged in, using empty state');
        _state = const AppState().checkDailyReset();
      }
    } catch (e, stack) {
      debugPrint('[Init] CRITICAL ERROR: $e');
      debugPrint('[Init] Stack: $stack');
      _state = const AppState().checkDailyReset();
    }
    debugPrint('[Init] Step 5: Setting loading=false');
    if (mounted) {
      setState(() { _loading = false; });
    }
    debugPrint('[Init] Done!');
  }

  /// 后台同步到 Supabase（失败不影响主流程）
  Future<void> _syncToCloud() async {
    try {
      await _supabase.upsertUser(_state);
    } catch (e) {
      debugPrint('[Sync] Cloud sync failed: $e (ignored)');
    }
  }

  Future<void> _persist() async {
    _state = _state.evaluateBadges();
    await _storage.saveAppState(_state);
    // 本地保存成功后，异步写云端
    _syncToCloud();
  }

  Future<void> _lightWish(String wishId) async {
    // 检查登录状态
    if (!await requireLogin()) return;
    
    if (_state.litWishes.contains(wishId)) return;

    final myIndex = _state.myWishes.indexWhere((w) => w.id == wishId);

    setState(() {
      if (myIndex >= 0) {
        final old = _state.myWishes[myIndex];
        final updated = old.copyWith(lights: old.lights + 1);
        final newList = List<Wish>.from(_state.myWishes);
        newList[myIndex] = updated;
        _state = _state.copyWith(
          myWishes: newList,
          litWishes: {..._state.litWishes, wishId},
        );
      } else {
        final extra = Map<String, int>.from(_state.extraLights);
        extra[wishId] = (extra[wishId] ?? 0) + 1;
        _state = _state.copyWith(
          litWishes: {..._state.litWishes, wishId},
          extraLights: extra,
        );
      }
    });
    _persist();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(I18n.t('snack_lantern_lit')),
        backgroundColor: KouMingTheme.lantern,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static int _waitMonths(String category) {
    switch (category) {
      case 'study': return 10;
      case 'love': return 6;
      case 'money': return 8;
      default: return 3;
    }
  }

  void _throwWish(Wish wish, int days) async {
    // 检查登录状态
    if (!await requireLogin()) return;
    
    final now = DateTime.now();
    // 测试祝福数据
    final testBlessings = [
      '愿你心想事成，一切顺利！',
      '加油！相信你一定可以实现这个目标！',
      '祝福你啊，愿好运常伴你左右~',
      '看到你许的这个愿望，我也被感动了，祝你成功！',
      '坚持就是胜利，我会一直为你加油的！',
    ];
    final capsule = WishCapsule(
      id: 'cap_${wish.id}',
      wishText: wish.text,
      createdAt: now,
      dueDate: now.add(Duration(days: days)),
      category: wish.category,
      lights: wish.lights,
      blessingCount: 3 + (wish.text.hashCode % 3), // 3-5条祝福
      blessings: testBlessings.sublist(0, 3 + (wish.text.hashCode % 3)),
    );

    setState(() => _state = _state.copyWith(
      myWishes: [wish, ..._state.myWishes],
      throwLimit: _state.throwLimit - 1,
      totalWishes: _state.totalWishes + 1,
      capsules: [capsule, ..._state.capsules],
    ));
    await _persist();

    // 同时写云端（后台）
    _supabase.createWish(wish);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(I18n.t('snack_wish_sunk')),
          backgroundColor: KouMingTheme.water.withValues(alpha: 0.9),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 检查用户是否已登录，未登录则弹出登录对话框
  /// 返回 true 表示已登录或登录成功，false 表示用户取消登录
  Future<bool> requireLogin() async {
    if (_state.nickname.isNotEmpty) return true;
    
    final nicknameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: KouMingTheme.surface,
        title: const Text('设置昵称', style: TextStyle(color: KouMingTheme.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '输入你的昵称即可开始使用\n支持中文、英文、日语、韩语等各种语言',
              textAlign: TextAlign.center,
              style: TextStyle(color: KouMingTheme.dim, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nicknameController,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(color: KouMingTheme.text, fontSize: 16),
              decoration: InputDecoration(
                hintText: '例如：小明、KouMing、こうめい',
                hintStyle: TextStyle(color: KouMingTheme.dim.withValues(alpha: 0.5)),
                filled: true,
                fillColor: KouMingTheme.deep,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(color: KouMingTheme.dim)),
          ),
          ElevatedButton(
            onPressed: () {
              final nickname = nicknameController.text.trim();
              if (nickname.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KouMingTheme.gold,
              foregroundColor: KouMingTheme.deep,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('开始'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      final nickname = nicknameController.text.trim();
      // 创建新用户状态
      setState(() {
        _state = _state.copyWith(
          nickname: nickname,
          userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        );
      });
      await _persist();
      return true;
    }
    return false;
  }

  Future<void> _fulfillCapsule(WishCapsule capsule) async {
    // 检查登录状态
    if (!await requireLogin()) return;
    final idx = _state.capsules.indexWhere((c) => c.id == capsule.id);
    if (idx < 0) return;
    
    // 找到对应的 Wish（从 wishId 提取）
    final wishId = capsule.id.replaceFirst('cap_', '');
    final wishIdx = _state.myWishes.indexWhere((w) => w.id == wishId);
    
    // 调试输出
    debugPrint('=== 还愿调试 ===');
    debugPrint('capsule.id: ${capsule.id}');
    debugPrint('wishId: $wishId');
    debugPrint('myWishes count: ${_state.myWishes.length}');
    debugPrint('myWishes ids: ${_state.myWishes.map((w) => w.id).toList()}');
    debugPrint('wishIdx: $wishIdx');
    
    // 显示还愿仪式动画（传入还愿文字）
    await FulfillCeremony.show(
      context,
      capsule: capsule,
      fulfillText: capsule.fulfillText,
      onCeremonyComplete: () async {
        final updatedCapsules = List<WishCapsule>.from(_state.capsules);
        updatedCapsules[idx] = capsule.copyWith(s: CapsuleStatus.fulfilled);
        
        // 同时更新对应的 Wish，添加还愿文字
        final updatedWishes = List<Wish>.from(_state.myWishes);
        if (wishIdx >= 0) {
          updatedWishes[wishIdx] = _state.myWishes[wishIdx].copyWith(
            fulfillText: capsule.fulfillText,
          );
        }
        
        setState(() => _state = _state.copyWith(
          capsules: updatedCapsules,
          myWishes: updatedWishes,
          meritPoints: _state.meritPoints + 50, // 还愿+50祝福值
        ));
        await _persist();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: KouMingTheme.deep,
        body: Center(child: CircularProgressIndicator(color: KouMingTheme.gold)),
      );
    }
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          PoolPage(
            state: _state,
            onStateChanged: (s) => setState(() => _state = s),
            onWishCreated: _throwWish,
            onLightWish: _lightWish,
            onReadingRequested: () {},
            aiService: _aiService,
            requireLogin: requireLogin,
          ),
          OfferingShop(
            state: _state,
            onStateChanged: (s) => setState(() => _state = s),
            requireLogin: requireLogin,
          ),
          ProfilePage(
            state: _state,
            onStateChanged: (s) => setState(() => _state = s),
            onFulfillCapsule: _fulfillCapsule,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: KouMingTheme.surface,
        indicatorColor: KouMingTheme.gold.withValues(alpha: 0.1),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome, color: KouMingTheme.water, size: 24),
            selectedIcon: const Icon(Icons.auto_awesome, color: KouMingTheme.gold, size: 26),
            label: I18n.t('nav_pool'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.card_giftcard, color: KouMingTheme.purple, size: 24),
            selectedIcon: const Icon(Icons.card_giftcard, color: KouMingTheme.gold, size: 26),
            label: I18n.t('nav_shop'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person, color: Color(0xFFE8A850), size: 24),
            selectedIcon: const Icon(Icons.person, color: KouMingTheme.gold, size: 26),
            label: I18n.t('nav_profile'),
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
