import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/ai_service.dart';
import 'package:kouming/services/i18n_service.dart';
import 'package:kouming/services/share_service.dart';
import 'package:kouming/features/pool/oracle_flow.dart';
import 'package:kouming/features/pool/fishing_flow.dart';

class PoolPage extends StatefulWidget {
  final AppState state;
  final void Function(AppState) onStateChanged;
  final void Function(Wish, int) onWishCreated;
  final void Function(String) onLightWish;
  final VoidCallback onReadingRequested;
  final AiService aiService;
  final Future<bool> Function()? requireLogin;

  const PoolPage({
    super.key,
    required this.state,
    required this.onStateChanged,
    required this.onWishCreated,
    required this.onLightWish,
    required this.onReadingRequested,
    required this.aiService,
    this.requireLogin,
  });

  @override
  State<PoolPage> createState() => _PoolPageState();
}

class _PoolPageState extends State<PoolPage> with TickerProviderStateMixin {
  final _wishController = TextEditingController();
  late AnimationController _floatCtrl;
  late AnimationController _coinCtrl;
  late AnimationController _rippleCtrl;
  late AnimationController _lanternCtrl;
  bool _throwing = false;
  bool _fishing = false;
  Offset? _lanternPos;
  final SmartFisher _fisher = SmartFisher();
  final Set<String> _fishedWishIds = {};

  final Map<String, Offset> _positions = {};

  static DateTime _ago(int m) =>
      DateTime.now().subtract(Duration(minutes: m));

  static final List<Wish> _pool = [
    Wish(id: 'p1', text: '考上理想的学校！', category: 'study', lights: 892, createdAt: _ago(2), blessings: ['加油！相信你一定能考上理想的学校！', '坚持就是胜利，祝你金榜题名！']),
    Wish(id: 'p2', text: '希望妈妈身体健康', category: 'health', lights: 1203, createdAt: _ago(5), fulfillText: '妈妈体检报告出来了，各项指标都正常！感谢大家的祝福！', blessings: ['祝阿姨身体健康，长命百岁！', '愿天下父母都健康长寿！']),
    Wish(id: 'p3', text: '今年能遇到对的人', category: 'love', lights: 674, createdAt: _ago(8), blessings: ['缘分天注定，祝你早日遇到那个TA！', '相信自己，你值得最好的爱情！']),
    Wish(id: 'p4', text: '实现财务自由', category: 'money', lights: 1547, createdAt: _ago(12), fulfillText: '经过三年的努力，终于攒够了人生的第一个100万！', blessings: ['祝你财源广进，早日实现财务自由！', '理财有道，财富自由指日可待！']),
    Wish(id: 'p5', text: '拿到心仪的offer', category: 'study', lights: 423, createdAt: _ago(15), blessings: ['面试顺利，offer拿到手软！', '你的努力终将有回报！']),
    Wish(id: 'p6', text: '世界和平', category: 'default', lights: 256, createdAt: _ago(25), blessings: ['愿世界和平，没有战争！', '大爱无疆，为你点赞！']),
    Wish(id: 'p7', text: '早日还清房贷', category: 'money', lights: 512, createdAt: _ago(30), fulfillText: '最后一笔房贷还清了！房子终于完全属于自己了！', blessings: ['无债一身轻，恭喜！', '早日摆脱房奴身份！']),
    Wish(id: 'p8', text: '他也能喜欢我就好了', category: 'love', lights: 741, createdAt: _ago(35), blessings: ['勇敢表白，不要错过缘分！', '双向奔赴的爱情最美好！']),
    Wish(id: 'p9', text: '逢考必过！', category: 'study', lights: 1023, createdAt: _ago(40), blessings: ['考试顺利，超常发挥！', '复习充分，必过无疑！']),
    Wish(id: 'p10', text: '狗狗手术顺利', category: 'health', lights: 668, createdAt: _ago(60), fulfillText: '狗狗手术很成功，现在已经能跑能跳了！谢谢大家的祝福！', blessings: ['祝狗狗早日康复！', '毛孩子一定会好起来的！']),
  ];

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _coinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _lanternCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _wishController.dispose();
    _floatCtrl.dispose();
    _coinCtrl.dispose();
    _rippleCtrl.dispose();
    _lanternCtrl.dispose();
    super.dispose();
  }

  Offset _bubbleAt(String id, int i, double w, double h) {
    return _positions.putIfAbsent(id, () {
      final seed = id.hashCode;
      final rng = Random(seed > 0 ? seed : -seed);
      const cols = 3;
      final col = i % cols;
      final row = i ~/ cols;
      final cw = w / cols;
      final rowCount = max((_pool.length + widget.state.myWishes.length) ~/ cols + 1, 4);
      final ch = h / rowCount;
      return Offset(
        cw * col + cw * 0.15 + rng.nextDouble() * cw * 0.45,
        ch * row + ch * 0.1 + rng.nextDouble() * ch * 0.4,
      );
    });
  }

  Future<void> _throwWish() async {
    if (_throwing) return;
    
    // 弹出许愿输入对话框
    final text = await _showWishInputDialog();
    if (text == null || text.isEmpty) return;

    // 弹出天数输入对话框
    final days = await _showDaysInputDialog();
    if (days == null || days < 1 || days > 365) return;

    setState(() => _throwing = true);

    final cat = WishCategory.fromText(text);
    final wish = Wish(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      category: cat.key,
      lights: 0,
      createdAt: DateTime.now(),
      isMine: true,
    );

    await _coinCtrl.forward(from: 0);

    if (mounted) setState(() => _throwing = false);
    _rippleCtrl.forward(from: 0);

    widget.onWishCreated(wish, days);
    
    // 投愿后询问是否算卦
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _showOraclePrompt(wish);
      });
    }
  }
  
  void _showOraclePrompt(Wish wish) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KouMingTheme.surface,
        title: Text('要算一卦吗？', style: TextStyle(color: KouMingTheme.gold, fontFamily: 'MaShanZheng')),
        content: Text('池灵可以为你解读这个愿望的运势', style: TextStyle(color: KouMingTheme.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('稍后再说', style: TextStyle(color: KouMingTheme.dim)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openOracle(wish);
            },
            child: Text('立即算卦', style: TextStyle(color: KouMingTheme.gold)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showWishInputDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KouMingTheme.surface,
        title: const Text('写下你的心愿', style: TextStyle(color: KouMingTheme.text, fontFamily: 'MaShanZheng')),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: KouMingTheme.text),
          decoration: InputDecoration(
            hintText: '例如：希望家人平安健康',
            hintStyle: const TextStyle(color: KouMingTheme.dim),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: KouMingTheme.dim),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: KouMingTheme.dim.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: KouMingTheme.gold),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: KouMingTheme.dim)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx, text);
              }
            },
            child: const Text('确定', style: TextStyle(color: KouMingTheme.gold)),
          ),
        ],
      ),
    );
  }

  Future<int?> _showDaysInputDialog() async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KouMingTheme.surface,
        title: const Text('设定实现天数', style: TextStyle(color: KouMingTheme.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '你希望这个愿望在多少天内实现？\n（1-365天）',
              style: TextStyle(fontSize: 12, color: KouMingTheme.dim),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: KouMingTheme.text),
              decoration: InputDecoration(
                hintText: '例如：30',
                hintStyle: const TextStyle(color: KouMingTheme.dim),
                suffixText: '天',
                suffixStyle: const TextStyle(color: KouMingTheme.dim),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KouMingTheme.dim),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: KouMingTheme.dim.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KouMingTheme.gold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: KouMingTheme.dim)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              final days = int.tryParse(text);
              if (days != null && days >= 1 && days <= 365) {
                Navigator.pop(ctx, days);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('请输入1-365之间的天数'),
                    backgroundColor: KouMingTheme.purple,
                  ),
                );
              }
            },
            child: const Text('确定', style: TextStyle(color: KouMingTheme.gold)),
          ),
        ],
      ),
    );
  }

  Future<void> _startFishing() async {
    if (_fishing) return;
    
    // 检查登录状态
    if (widget.requireLogin != null) {
      final loggedIn = await widget.requireLogin!();
      if (!loggedIn) return;
    }
    
    // 检查次数是否用完
    if (widget.state.fishLimit <= 0) {
      _showLimitReachedDialog('今日次数使用完毕', '请明天再来');
      return;
    }
    
    setState(() => _fishing = true);
  }

  Future<void> _onFishingComplete() async {
    if (!_fishing) return;

    final result = _fisher.fish(
      pool: _pool,
      userWishes: widget.state.myWishes,
      excludeIds: _fishedWishIds,
    );

    // 记录已捞过的愿望ID
    _fishedWishIds.add(result.wish.id);

    setState(() => _fishing = false);

    widget.onStateChanged(widget.state.copyWith(
      fishLimit: widget.state.fishLimit - 1,
      fishedCount: widget.state.fishedCount + 1,
    ));

    if (!mounted) return;
    bool hasBlessed = false;
    String? blessingText;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => FishedWishSheet(
        result: result,
        onBlessingComplete: () {
          hasBlessed = true;
        },
        onBlessingText: (text) {
          blessingText = text;
        },
      ),
    );
    
    // 如果没有写祝福，恢复捞愿次数
    if (!hasBlessed) {
      widget.onStateChanged(widget.state.copyWith(
        fishLimit: widget.state.fishLimit + 1,
        fishedCount: widget.state.fishedCount - 1,
      ));
      _fishedWishIds.remove(result.wish.id);
    } else {
      // 写了一条祝福，给被祝福的愿望增加祝福值
      final updatedExtraLights = Map<String, int>.from(widget.state.extraLights);
      updatedExtraLights[result.wish.id] = (updatedExtraLights[result.wish.id] ?? 0) + 1;
      
      // 更新_pool中对应愿望的blessingCount
      final wishIndex = _pool.indexWhere((w) => w.id == result.wish.id);
      if (wishIndex >= 0) {
        _pool[wishIndex] = _pool[wishIndex].copyWith(
          blessingCount: _pool[wishIndex].blessingCount + 1,
        );
      }
      
      // 写祝福增加对应心愿胶囊的blessingCount
      final updatedCapsules = List<WishCapsule>.from(widget.state.capsules);
      final capsuleIndex = updatedCapsules.indexWhere((c) => c.wishText == result.wish.text);
      if (capsuleIndex >= 0) {
        final capsule = updatedCapsules[capsuleIndex];
        final newBlessings = List<String>.from(capsule.blessings);
        if (blessingText != null) {
          newBlessings.add(blessingText!);
        }
        updatedCapsules[capsuleIndex] = capsule.copyWith(
          blessingCount: capsule.blessingCount + 1,
          blessings: newBlessings,
        );
      }
      
      // 更新_pool中对应愿望的blessings
      final poolWishIndex = _pool.indexWhere((w) => w.id == result.wish.id);
      if (poolWishIndex >= 0 && blessingText != null) {
        final wish = _pool[poolWishIndex];
        final newBlessings = List<String>.from(wish.blessings);
        newBlessings.add(blessingText!);
        _pool[poolWishIndex] = wish.copyWith(
          blessings: newBlessings,
        );
      }
      
      widget.onStateChanged(widget.state.copyWith(
        extraLights: updatedExtraLights,
        capsules: updatedCapsules,
      ));
    }
  }

  void _lightWithAnimation(Wish wish) {
    final pos = _positions[wish.id];
    if (pos != null) {
      setState(() => _lanternPos = pos);
      _lanternCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _lanternPos = null);
      });
    }
    widget.onLightWish(wish.id);
  }

  void _showLimitReachedDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KouMingTheme.surface,
        title: Text(title, style: const TextStyle(color: KouMingTheme.gold, fontFamily: 'MaShanZheng')),
        content: Text(message, style: const TextStyle(color: KouMingTheme.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了', style: TextStyle(color: KouMingTheme.gold)),
          ),
        ],
      ),
    );
  }

  void _showLightPicker() {
    final all = [...widget.state.myWishes, ..._pool];
    showModalBottomSheet(
      context: context,
      backgroundColor: KouMingTheme.deep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              I18n.t('pool_light_title'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: KouMingTheme.gold,
                fontFamily: 'MaShanZheng',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              I18n.t('pool_light_desc'),
              style: const TextStyle(fontSize: 11, color: KouMingTheme.dim),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: all.length,
                itemBuilder: (_, i) {
                  final w = all[i];
                  final isLit = widget.state.litWishes.contains(w.id);
                  final cat = WishCategory.values.firstWhere(
                    (c) => c.key == w.category,
                    orElse: () => WishCategory.other,
                  );
                  return ListTile(
                    leading: Text(
                      cat.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(
                      w.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: KouMingTheme.text),
                    ),
                    subtitle: Text(
                      '${w.lights} ${I18n.t('pool_lights')}',
                      style: const TextStyle(fontSize: 10, color: KouMingTheme.dim),
                    ),
                    trailing: isLit
                        ? const Icon(Icons.check_circle, color: KouMingTheme.lantern, size: 20)
                        : const Icon(Icons.circle_outlined, color: KouMingTheme.dim, size: 20),
                    onTap: isLit
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _lightWithAnimation(w);
                          },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(Wish wish) {
    // 弹窗功能已删除
  }

  void _openOracle(Wish wish) {
    OracleFlow.show(
      context,
      wish: wish,
      aiService: widget.aiService,
      freeOracleUsed: widget.state.freeOracleUsed,
      freeOracleCount: widget.state.levelBenefits.freeOracleCount,
      onFreeOracleUsed: () {
        widget.onStateChanged(
          widget.state.copyWith(
            freeOracleUsed: widget.state.freeOracleUsed + 1,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = [...widget.state.myWishes, ..._pool];
    final hot = List<Wish>.from(all)..sort((a, b) {
      final ea = widget.state.extraLights[a.id] ?? 0;
      final eb = widget.state.extraLights[b.id] ?? 0;
      return (b.lights + eb) - (a.lights + ea);
    });
    final top5 = hot.take(5).toList();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 1.5,
                colors: [KouMingTheme.mid, KouMingTheme.deep],
              ),
            ),
          ),
          ..._particles(),
          SafeArea(
            child: Column(
              children: [
                _header(),
                _hotRow(top5),
                Expanded(child: _bubblePool(all)),
              ],
            ),
          ),
          if (_throwing) _coinOverlay(),
          AnimatedBuilder(
            animation: _rippleCtrl,
            builder: (_, __) {
              if (!_rippleCtrl.isAnimating) return const SizedBox.shrink();
              return _rippleOverlay();
            },
          ),
          if (_fishing)
            FishingOverlay(onComplete: _onFishingComplete),
          if (_lanternPos != null)
            AnimatedBuilder(
              animation: _lanternCtrl,
              builder: (_, __) {
                final t = _lanternCtrl.value;
                return Positioned(
                  left: _lanternPos!.dx - 10,
                  top: _lanternPos!.dy - t * 120,
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: Column(
                      children: [
                        const Text('\u{1F3EE}',
                            style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: KouMingTheme.lantern
                                .withValues(alpha: (1 - t) * 0.35),
                            boxShadow: [
                              BoxShadow(
                                color: KouMingTheme.lantern
                                    .withValues(alpha: (1 - t) * 0.5),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _inputBar(),
          ),
        ],
      ),
    );
  }

  // ─── Sub-builders ───────────────────────────────

  List<Widget> _particles() {
    return List.generate(15, (i) {
      final r = Random(i * 7 + 3);
      return Positioned(
        left: r.nextDouble() * 400,
        top: r.nextDouble() * 800,
        child: AnimatedBuilder(
          animation: _floatCtrl,
          builder: (_, __) {
            final o = 0.08 + 0.08 * sin(_floatCtrl.value * pi * 2 + i);
            return RepaintBoundary(
              child: Icon(Icons.circle,
                  size: 1.5, color: KouMingTheme.dim.withValues(alpha: o)),
            );
          },
        ),
      );
    });
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text('\u{1F30A}', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(I18n.t('pool_title'),
                  style: const TextStyle(
                    fontFamily: 'MaShanZheng',
                    fontSize: 22,
                    color: KouMingTheme.gold,
                    letterSpacing: 3,
                  )),
              Text(
                I18n.t('pool_wishes_count', args: {'count': '${widget.state.totalWishes + _pool.length}'}),
                style: const TextStyle(fontSize: 10, color: KouMingTheme.dim),
              ),
            ],
          ),
          const Spacer(),
          // 显示已用次数 = 总次数 - 剩余次数
          _StatChip(
              label: I18n.t('pool_throw_label'),
              value: '${(widget.state.levelBenefits.dailyThrowLimit - widget.state.throwLimit).clamp(0, widget.state.levelBenefits.dailyThrowLimit)}',
              color: KouMingTheme.water),
          const SizedBox(width: 6),
          _StatChip(
              label: '捞愿',
              value: '${(widget.state.levelBenefits.dailyFishLimit - widget.state.fishLimit).clamp(0, widget.state.levelBenefits.dailyFishLimit)}',
              color: KouMingTheme.purple),
        ],
      ),
    );
  }

  Widget _hotRow(List<Wish> top5) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: top5.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final w = top5[i];
          final extra = widget.state.extraLights[w.id] ?? 0;
          final total = w.lights + extra;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: KouMingTheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: KouMingTheme.gold.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('\u{1F48C} $total',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: KouMingTheme.gold)),
                const SizedBox(height: 2),
                SizedBox(
                  width: 72,
                  child: Text(
                    '"${w.text}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: KouMingTheme.dim),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bubblePool(List<Wish> all) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      final h = c.maxHeight - 80;
      return Stack(
        children: all.asMap().entries.map((e) {
          final i = e.key;
          final wish = e.value;
          final extra = widget.state.extraLights[wish.id] ?? 0;
          final pos = _bubbleAt(wish.id, i, w, h);
          return _WishBubble(
            wish: wish,
            totalLights: wish.lights + extra,
            basePos: pos,
            floatAnim: _floatCtrl,
            idx: i,
            isLit: widget.state.litWishes.contains(wish.id),
            onTap: () {}, // 空函数，圆圈不可点击
          );
        }).toList(),
      );
    });
  }

  Widget _coinOverlay() {
    return AnimatedBuilder(
      animation: _coinCtrl,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_coinCtrl.value);
        final mq = MediaQuery.of(context);
        return Positioned(
          left: mq.size.width / 2 - 20,
          bottom: 80 + t * mq.size.height * 0.3,
          child: Opacity(
            opacity: 1 - t * 0.6,
            child: Transform.rotate(
              angle: t * pi * 4,
              child: const Text('\u{1FA99}', style: TextStyle(fontSize: 40)),
            ),
          ),
        );
      },
    );
  }

  Widget _rippleOverlay() {
    final t = _rippleCtrl.value;
    final mq = MediaQuery.of(context);
    final cx = mq.size.width / 2;
    final cy = mq.size.height * 0.35;
    return Stack(
      children: List.generate(3, (i) {
        final delay = i * 0.15;
        final rt = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
        final size = 30.0 + rt * 180;
        final opacity = (1 - rt) * 0.6;
        return Positioned(
          left: cx - size / 2,
          top: cy - size / 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: KouMingTheme.gold.withValues(alpha: opacity),
                width: max(2 - rt * 1.5, 0.5).toDouble(),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Input bar with action buttons only
  Widget _inputBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: KouMingTheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _ActionButton(
            emoji: '\u{1FA99}',
            label: I18n.t('pool_throw_label'),
            subtitle: I18n.t('pool_throw_hint'),
            meaning: I18n.t('pool_throw_meaning'),
            count: widget.state.throwLimit,
            onTap: _throwWish,
          ),
          const SizedBox(width: 6),
          _ActionButton(
            emoji: '\u{1F3A3}',
            label: '捞愿',
            subtitle: I18n.t('pool_fish_hint'),
            meaning: I18n.t('pool_fish_meaning'),
            count: widget.state.fishLimit,
            onTap: _startFishing,
          ),
        ],
      ),
    );
  }
}

// ─── Action Button with Explanation ─────────────────────────

class _ActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final String meaning;
  final int? count;
  final Future<void> Function()? onTap;
  final bool showMeaning;

  const _ActionButton({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.meaning,
    this.count,
    this.onTap,
    this.showMeaning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap != null ? () async => await onTap!() : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: KouMingTheme.gold.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: onTap != null
                  ? KouMingTheme.gold.withValues(alpha: 0.15)
                  : KouMingTheme.dim.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 3),
                  Text(label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: KouMingTheme.gold,
                      )),
                  if (count != null) ...[
                    const SizedBox(width: 3),
                    Text('×$count',
                        style: const TextStyle(
                          fontSize: 9,
                          color: KouMingTheme.dim,
                        )),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8,
                    color: KouMingTheme.dim,
                    height: 1.2,
                  )),
              if (showMeaning || onTap != null) ...[
                const SizedBox(height: 2),
                Text(meaning,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 7,
                      color: KouMingTheme.purple.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Wish Bubble ───────────────────────────────────────────

class _WishBubble extends StatelessWidget {
  final Wish wish;
  final int totalLights;
  final Offset basePos;
  final Animation<double> floatAnim;
  final int idx;
  final bool isLit;
  final VoidCallback onTap;

  const _WishBubble({
    required this.wish,
    required this.totalLights,
    required this.basePos,
    required this.floatAnim,
    required this.idx,
    required this.isLit,
    required this.onTap,
  });

  double get _size {
    final tier = GlowTier.fromLights(totalLights);
    return switch (tier) {
      GlowTier.miracle => 100.0,
      GlowTier.radiant => 85.0,
      GlowTier.bright => 72.0,
      GlowTier.faint => 60.0,
      _ => 52.0,
    };
  }

  Color get _catColor => switch (wish.category) {
    'study' => KouMingTheme.water,
    'health' => const Color(0xFF66BB6A),
    'love' => const Color(0xFFEF5350),
    'money' => KouMingTheme.gold,
    _ => KouMingTheme.purple,
  };

  double get _phaseX => idx * 0.7;
  double get _phaseY => idx * 1.1;

  /// 根据祝福数计算气泡大小
  /// 祝福数越多，气泡越大
  double get _blessingSize {
    final blessings = totalLights;
    if (blessings >= 1000) return 110.0;
    if (blessings >= 500) return 95.0;
    if (blessings >= 200) return 80.0;
    if (blessings >= 100) return 70.0;
    if (blessings >= 50) return 62.0;
    return 52.0;
  }

  /// 根据祝福数计算亮度
  /// 祝福数越多，越亮
  double get _blessingBrightness {
    final blessings = totalLights;
    if (blessings >= 1000) return 1.0;
    if (blessings >= 500) return 0.85;
    if (blessings >= 200) return 0.7;
    if (blessings >= 100) return 0.55;
    if (blessings >= 50) return 0.4;
    return 0.25;
  }

  /// 根据祝福数计算垂直位置偏移
  /// 祝福数越多，越靠下（视觉上位置越低，dy值越大）
  double get _verticalOffset {
    final blessings = totalLights;
    // 祝福数越多，越靠下（dy值越大，位置越低）
    // 注意：Stack中top值越大，位置越靠下
    if (blessings >= 1000) return 80.0;
    if (blessings >= 500) return 60.0;
    if (blessings >= 200) return 40.0;
    if (blessings >= 100) return 25.0;
    if (blessings >= 50) return 10.0;
    return -5.0;
  }

  /// 检查是否已还愿（有还愿文字表示已还愿）
  bool get _isFulfilled => wish.fulfillText != null && wish.fulfillText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: basePos.dx,
      top: basePos.dy + _verticalOffset,
      child: AnimatedBuilder(
        animation: floatAnim,
        builder: (_, __) {
          final t = floatAnim.value;
          final dx = sin(t * pi * 2 + _phaseX) * 5;
          final dy = cos(t * pi * 2 + _phaseY) * 4;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: RepaintBoundary(
              child: GestureDetector(
                onTap: () => _showBlessings(context),
                child: Container(
                  width: _blessingSize,
                  height: _blessingSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // 已还愿：白底黑字；未还愿：原样
                    color: _isFulfilled ? Colors.white : null,
                    gradient: _isFulfilled ? null : RadialGradient(
                      colors: [
                        _catColor.withValues(alpha: _blessingBrightness),
                        _catColor.withValues(alpha: _blessingBrightness * 0.3),
                      ],
                      center: Alignment.topLeft,
                    ),
                    border: Border.all(
                      color: isLit
                          ? KouMingTheme.lantern.withValues(alpha: _blessingBrightness + 0.2)
                          : _catColor.withValues(alpha: _blessingBrightness * 0.6),
                      width: isLit ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KouMingTheme.lantern.withValues(alpha: _blessingBrightness * 0.5),
                        blurRadius: 8 + _blessingBrightness * 20,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isFulfilled) ...[
                        // 已还愿扣章
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: KouMingTheme.gold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '已还愿',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          wish.text,
                          maxLines: _isFulfilled ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _blessingSize > 70 ? 9 : 7,
                            // 已还愿：黑字；未还愿：白字
                            color: _isFulfilled ? Colors.black : KouMingTheme.text,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      if (totalLights > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '\u{1F48C} $totalLights',
                          style: TextStyle(
                            fontSize: _blessingSize > 70 ? 9 : 7,
                            color: _isFulfilled ? Colors.black54 : KouMingTheme.lantern,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBlessings(BuildContext context) {
    final blessings = wish.blessings;
    if (blessings.isEmpty && wish.fulfillText == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KouMingTheme.surface,
        title: const Text('祝福与还愿', style: TextStyle(color: KouMingTheme.gold, fontFamily: 'MaShanZheng')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (wish.fulfillText != null && wish.fulfillText!.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KouMingTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('还愿文字', style: TextStyle(fontSize: 11, color: KouMingTheme.gold, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        wish.fulfillText!,
                        style: const TextStyle(color: KouMingTheme.text, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
              if (blessings.isNotEmpty) ...[
                const Text('收到的祝福', style: TextStyle(fontSize: 11, color: KouMingTheme.dim, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...blessings.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: KouMingTheme.deep.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    b,
                    style: const TextStyle(color: KouMingTheme.text, fontSize: 13, height: 1.4),
                  ),
                )),
              ],
              if (blessings.isEmpty && wish.fulfillText == null)
                const Text('还没有祝福或还愿文字', style: TextStyle(color: KouMingTheme.dim)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭', style: TextStyle(color: KouMingTheme.gold)),
          ),
        ],
      ),
    );
  }
}

// ─── Wish Detail Bottom Sheet ──────────────────────────────

class _WishDetailSheet extends StatelessWidget {
  final Wish wish;
  final int totalLights;
  final bool isLit;
  final VoidCallback onLight;
  final VoidCallback onOracle;
  final VoidCallback onShare;

  const _WishDetailSheet({
    required this.wish,
    required this.totalLights,
    required this.isLit,
    required this.onLight,
    required this.onOracle,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final cat = WishCategory.values.firstWhere(
      (c) => c.key == wish.category,
      orElse: () => WishCategory.other,
    );
    final tier = GlowTier.fromLights(totalLights);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KouMingTheme.dim.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category + time + tier
          Row(
            children: [
              Text(cat.label,
                  style: const TextStyle(fontSize: 10, color: KouMingTheme.dim)),
              const SizedBox(width: 8),
              Text(_timeAgo(wish.createdAt),
                  style: const TextStyle(fontSize: 9, color: KouMingTheme.dim)),
              if (tier.level > 0) ...[
                const Spacer(),
                Text('${tier.emoji} ${tier.label}',
                    style:
                        const TextStyle(fontSize: 9, color: KouMingTheme.gold)),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Wish text
          Text(
            '"${wish.text}"',
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: KouMingTheme.text,
              height: 1.4,
            ),
          ),
          if (wish.isMine)
            Text('  \u2014 ${I18n.t('pool_your_wish')}',
                style: const TextStyle(fontSize: 10, color: KouMingTheme.gold)),
          const SizedBox(height: 12),

          // Principle explanation card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KouMingTheme.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: KouMingTheme.purple.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Text('\u{1F4A1}', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    I18n.t('principle_body'),
                    style: const TextStyle(
                      fontSize: 9,
                      color: KouMingTheme.dim,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Text(
                I18n.t('pool_lantern_count', args: {'count': '$totalLights'}),
                style: const TextStyle(
                    fontSize: 13, color: KouMingTheme.lantern),
              ),
              const Spacer(),
              // Share button
              OutlinedButton.icon(
                onPressed: onShare,
                icon: const Text('\u{1F4E4}', style: TextStyle(fontSize: 12)),
                label: Text(I18n.t('pool_share_label')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KouMingTheme.gold,
                  side: BorderSide(color: KouMingTheme.gold.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
              // Light button
              OutlinedButton.icon(
                onPressed: isLit ? null : onLight,
                icon: const Text('\u{1F3EE}', style: TextStyle(fontSize: 14)),
                label: Text(isLit ? I18n.t('pool_lit') : I18n.t('pool_light_btn')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KouMingTheme.lantern,
                  side: BorderSide(
                    color: isLit
                        ? KouMingTheme.lantern
                        : KouMingTheme.lantern.withValues(alpha: 0.2),
                  ),
                  backgroundColor: KouMingTheme.lantern
                      .withValues(alpha: isLit ? 0.15 : 0.05),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              if (!wish.isMine) ...[
                const SizedBox(width: 6),
                TextButton(
                  onPressed: onOracle,
                  style: TextButton.styleFrom(
                    foregroundColor: KouMingTheme.purple,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(I18n.t('pool_oracle_label'), style: const TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Compliance notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: KouMingTheme.purple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              I18n.t('disclaimer_virtual_notice'),
              style: TextStyle(
                fontSize: 8,
                color: KouMingTheme.dim.withValues(alpha: 0.7),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return I18n.t('pool_time_minutes', args: {'n': '${d.inMinutes}'});
    if (d.inHours < 24) return I18n.t('pool_time_hours', args: {'n': '${d.inHours}'});
    return I18n.t('pool_time_days', args: {'n': '${d.inDays}'});
  }
}

// ─── Stat Chip ─────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          const SizedBox(width: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
