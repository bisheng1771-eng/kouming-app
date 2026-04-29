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
import 'package:kouming/features/shop/fate_draw_flow.dart';

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
      apiKey: 'AQ.Ab8RN6Kso2wGSnOV8DtHo6VcUtlu4od8bRkA69fk-QX-pkI6Tw',
      proxy: null, // 直连，不使用代理
    );
    _init();
  }

  Future<void> _init() async {
    // 1. 匿名登录（云端）
    await _supabase.ensureLogin();
    // 2. 加载本地状态（优先，快速离线可用）
    final saved = await _storage.loadAppState();
    if (saved != null) {
      _state = saved.checkDailyReset().evaluateBadges();
    } else {
      _state = const AppState().checkDailyReset().evaluateBadges();
    }
    // 3. 异步同步到云端（后台，不阻塞 UI）
    _syncToCloud();
    setState(() { _loading = false; });
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

  void _lightWish(String wishId) {
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
          meritPoints: _state.meritPoints + 1,
        );
      } else {
        final extra = Map<String, int>.from(_state.extraLights);
        extra[wishId] = (extra[wishId] ?? 0) + 1;
        _state = _state.copyWith(
          litWishes: {..._state.litWishes, wishId},
          meritPoints: _state.meritPoints + 1,
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

  void _throwWish(Wish wish) async {
    final now = DateTime.now();
    final capsule = WishCapsule(
      id: 'cap_${wish.id}',
      wishText: wish.text,
      createdAt: now,
      dueDate: DateTime(
        now.year,
        now.month + _waitMonths(wish.category),
        now.day,
      ),
      category: wish.category,
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

  void _fulfillCapsule(WishCapsule capsule) {
    final idx = _state.capsules.indexWhere((c) => c.id == capsule.id);
    if (idx < 0) return;
    final updated = List<WishCapsule>.from(_state.capsules);
    updated[idx] = capsule.copyWith(s: CapsuleStatus.fulfilled);
    setState(() => _state = _state.copyWith(
      capsules: updated,
      meritPoints: _state.meritPoints + 36,
    ));
    _persist();
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
            freeReadingUsed: _state.freeReadingUsed,
            onFreeReadingUsed: (used) {
              setState(() => _state = _state.copyWith(freeReadingUsed: used));
            },
          ),
          FateDrawFlow(
            onDrawComplete: () {},
            onPaymentRequired: () {},
          ),
          OfferingShop(
            state: _state,
            onStateChanged: (s) => setState(() => _state = s),
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
            icon: const Text('\u{1F4AD}', style: TextStyle(fontSize: 22)),
            selectedIcon:
                const Text('\u{1F4AD}', style: TextStyle(fontSize: 24, color: KouMingTheme.gold)),
            label: I18n.t('nav_pool'),
          ),
          NavigationDestination(
            icon: const Text('\u{1F3B4}', style: TextStyle(fontSize: 22)),
            selectedIcon:
                const Text('\u{1F3B4}', style: TextStyle(fontSize: 24, color: KouMingTheme.gold)),
            label: I18n.t('nav_fate'),
          ),
          NavigationDestination(
            icon: const Text('\u{1F56F}', style: TextStyle(fontSize: 22)),
            selectedIcon:
                const Text('\u{1F56F}', style: TextStyle(fontSize: 24, color: KouMingTheme.gold)),
            label: I18n.t('nav_shop'),
          ),
          NavigationDestination(
            icon: const Text('\u{1F464}', style: TextStyle(fontSize: 22)),
            selectedIcon:
                const Text('\u{1F464}', style: TextStyle(fontSize: 24, color: KouMingTheme.gold)),
            label: I18n.t('nav_profile'),
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
