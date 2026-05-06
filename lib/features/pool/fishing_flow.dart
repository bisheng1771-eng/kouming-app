import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/i18n_service.dart';
import 'package:kouming/services/share_service.dart';

/// ─── Smart Fishing Flow ───
///
/// 70% semantic match (category → keyword → popularity)
/// 30% random surprise
///
/// Animation: 3 phases — cast (0-0.3), wait (0.3-0.7), catch (0.7-1.0)

enum FishMatchType { semantic, surprise }

class FishResult {
  final Wish wish;
  final FishMatchType matchType;
  final String matchReason;

  const FishResult({
    required this.wish,
    required this.matchType,
    required this.matchReason,
  });
}

// ─── Smart Fishing Engine ──────────────────────────────────

class SmartFisher {
  final Random _rng = Random();

  FishResult fish({
    required List<Wish> pool,
    required List<Wish> userWishes,
    Set<String>? excludeIds,
  }) {
    if (pool.isEmpty) {
      throw StateError('Pool is empty — nothing to fish');
    }

    // 过滤掉已捞过的愿望
    var availablePool = pool;
    if (excludeIds != null && excludeIds.isNotEmpty) {
      availablePool = pool.where((w) => !excludeIds.contains(w.id)).toList();
      // 如果全部捞过了，重置并重新使用所有愿望
      if (availablePool.isEmpty) {
        availablePool = pool;
      }
    }

    // 随机打乱池子顺序，确保每次捞取不同
    final shuffled = List<Wish>.from(availablePool)..shuffle(_rng);
    
    final isSemantic = _rng.nextDouble() < 0.7;

    if (isSemantic && userWishes.isNotEmpty) {
      return _semanticMatch(shuffled, userWishes);
    }

    final wish = shuffled[_rng.nextInt(shuffled.length)];
    return FishResult(
      wish: wish,
      matchType: FishMatchType.surprise,
      matchReason: I18n.t('pool_fish_meaning'),
    );
  }

  FishResult _semanticMatch(List<Wish> pool, List<Wish> userWishes) {
    final userCats = userWishes.map((w) => w.category).toSet();

    final sameCategory =
        pool.where((w) => userCats.contains(w.category)).toList();
    if (sameCategory.isNotEmpty) {
      // 从同类愿望中随机选一个，而不是总是选第一个
      final wish = sameCategory[_rng.nextInt(sameCategory.length)];
      return FishResult(
        wish: wish,
        matchType: FishMatchType.semantic,
        matchReason: I18n.t('pool_fish_meaning'),
      );
    }

    final userWords = userWishes
        .expand((w) => w.text.toLowerCase().split(RegExp(r'\s+')))
        .where((w) => w.length > 3)
        .toSet();

    Wish? bestMatch;
    int bestScore = 0;
    for (final pw in pool) {
      final poolWords = pw.text
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 3)
          .toSet();
      final overlap = userWords.intersection(poolWords).length;
      if (overlap > bestScore) {
        bestScore = overlap;
        bestMatch = pw;
      }
    }

    if (bestMatch != null && bestScore > 0) {
      return FishResult(
        wish: bestMatch,
        matchType: FishMatchType.semantic,
        matchReason: I18n.t('pool_fish_meaning'),
      );
    }

    final sorted = List<Wish>.from(pool)
      ..sort((a, b) => b.lights.compareTo(a.lights));
    return FishResult(
      wish: sorted.first,
      matchType: FishMatchType.semantic,
      matchReason: I18n.t('pool_fish_meaning'),
    );
  }
}

// ─── Fishing Animation Overlay ─────────────────────────────

class FishingOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  const FishingOverlay({super.key, required this.onComplete});

  @override
  State<FishingOverlay> createState() => _FishingOverlayState();
}

class _FishingOverlayState extends State<FishingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _ctrl.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final mq = MediaQuery.of(context);
        final cx = mq.size.width / 2;
        final waterY = mq.size.height * 0.4;

        return Stack(
          children: [
            Container(color: KouMingTheme.deep.withValues(alpha: 0.5)),
            if (t < 0.7)
              Positioned(
                left: cx - 1,
                top: waterY * 0.3,
                child: Container(
                  width: 1.5,
                  height: (waterY * 0.7) * (t < 0.3 ? (t / 0.3) : 1.0),
                  color: KouMingTheme.dim.withValues(alpha: 0.4),
                ),
              ),
            if (t < 0.7)
              Positioned(
                left: cx - 10,
                top: waterY * 0.3 + (waterY * 0.7) * (t < 0.3 ? (t / 0.3) : 1.0) - 12,
                child: Opacity(
                  opacity: t < 0.3 ? 1.0 : (0.6 + 0.2 * sin(t * pi * 8)),
                  child: const Text('\u{1FA9D}', style: TextStyle(fontSize: 20)),
                ),
              ),
            if (t > 0.3 && t < 0.7)
              ...List.generate(3, (i) {
                final rt = ((t - 0.3 - i * 0.08) / 0.3).clamp(0.0, 1.0);
                if (rt <= 0) return const SizedBox.shrink();
                final size = 20.0 + rt * 100;
                return Positioned(
                  left: cx - size / 2,
                  top: waterY - size / 2,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: KouMingTheme.gold.withValues(alpha: (1 - rt) * 0.35),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              }),
            if (t >= 0.7)
              Positioned(
                left: cx - 45,
                top: waterY - ((t - 0.7) / 0.3) * waterY * 0.4,
                child: Opacity(
                  opacity: ((t - 0.7) / 0.15).clamp(0.0, 1.0),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          KouMingTheme.gold.withValues(alpha: 0.35),
                          KouMingTheme.purple.withValues(alpha: 0.12),
                        ],
                      ),
                      border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.5), width: 2),
                      boxShadow: [
                        BoxShadow(color: KouMingTheme.gold.withValues(alpha: 0.25), blurRadius: 24),
                      ],
                    ),
                    child: const Center(child: Text('\u2728', style: TextStyle(fontSize: 32))),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: waterY + 60,
              child: Text(
                t < 0.3
                    ? '\u{1F3A3} ${I18n.t('pool_fish_label')}...'
                    : t < 0.7
                        ? '\u{1F30A} ...'
                        : '\u2728 !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'MaShanZheng',
                  fontSize: 18,
                  color: KouMingTheme.gold.withValues(alpha: 0.85),
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Fished Wish Bottom Sheet ──────────────────────────────

class FishedWishSheet extends StatefulWidget {
  final FishResult result;
  final VoidCallback? onBlessingComplete;
  final void Function(String blessingText)? onBlessingText; // 返回祝福文字

  const FishedWishSheet({
    super.key,
    required this.result,
    this.onBlessingComplete,
    this.onBlessingText,
  });

  @override
  State<FishedWishSheet> createState() => _FishedWishSheetState();
}

class _FishedWishSheetState extends State<FishedWishSheet> {
  bool _hasBlessed = false;
  final List<Map<String, String>> _blessings = [
    {'nickname': '小星星', 'text': '愿你心想事成，前程似锦！'},
    {'nickname': '追梦人', 'text': '加油！相信你一定可以实现！'},
    {'nickname': '月光', 'text': '祝福你，愿一切安好。'},
  ];

  Future<void> _showBlessingDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KouMingTheme.surface,
        title: const Text('写下你的祝福', style: TextStyle(color: KouMingTheme.text, fontFamily: 'MaShanZheng')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '为这份心愿写下真诚的祝福（至少10字）',
              style: TextStyle(fontSize: 11, color: KouMingTheme.dim),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: KouMingTheme.text),
              decoration: InputDecoration(
                hintText: '例如：愿你心想事成，一切顺利！',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: KouMingTheme.dim)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.length >= 10) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('祝福需要至少10个字哦'),
                    backgroundColor: KouMingTheme.purple,
                  ),
                );
              }
            },
            child: const Text('发送祝福', style: TextStyle(color: KouMingTheme.gold)),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      final blessingText = controller.text.trim();
      setState(() {
        _hasBlessed = true;
        // 将新祝福添加到列表最前面
        _blessings.insert(0, {
          'nickname': '我',
          'text': blessingText,
        });
      });
      widget.onBlessingComplete?.call();
      widget.onBlessingText?.call(blessingText);
      // 不自动关闭弹窗，让用户看到新祝福后手动点击空白处关闭
    }
  }

  @override
  Widget build(BuildContext context) {
    final wish = widget.result.wish;
    final cat = WishCategory.values.firstWhere(
      (c) => c.key == wish.category,
      orElse: () => WishCategory.other,
    );
    final result = widget.result;

    return Container(
      decoration: const BoxDecoration(
        color: KouMingTheme.deep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

          // Match badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.result.matchType == FishMatchType.semantic
                      ? KouMingTheme.water.withValues(alpha: 0.12)
                      : KouMingTheme.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.result.matchType == FishMatchType.semantic
                        ? KouMingTheme.water.withValues(alpha: 0.25)
                        : KouMingTheme.gold.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.result.matchType == FishMatchType.semantic ? '\u{1F517}' : '\u{1F3B2}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.result.matchType == FishMatchType.semantic
                          ? '祝福'
                          : '\u{1F3B2}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.result.matchType == FishMatchType.semantic
                            ? KouMingTheme.water
                            : KouMingTheme.gold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(cat.label, style: const TextStyle(fontSize: 10, color: KouMingTheme.dim)),
            ],
          ),
          const SizedBox(height: 8),

          // Meaning (psychology principle)
          Text(
            widget.result.matchReason,
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: KouMingTheme.spirit.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),

          // Wish text
          Text(
            '"${wish.text}"',
            style: const TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: KouMingTheme.text,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${wish.lights} 条祝福',
            style: const TextStyle(fontSize: 11, color: KouMingTheme.lantern),
          ),
          const SizedBox(height: 12),
          
          // 祝福列表
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KouMingTheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最新祝福 (${_blessings.length})',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: KouMingTheme.gold.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                ..._blessings.asMap().entries.map((entry) {
                  final index = entry.key;
                  final blessing = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < _blessings.length - 1 ? 6 : 0),
                    child: _buildBlessingItem(blessing['nickname']!, blessing['text']!),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Blessing button only
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _hasBlessed ? null : _showBlessingDialog,
              icon: const Text('\u{1F48C}', style: TextStyle(fontSize: 14)),
              label: Text(
                _hasBlessed ? '已祝福' : '写祝福',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KouMingTheme.lantern,
                foregroundColor: Colors.white,
                disabledBackgroundColor: KouMingTheme.lantern.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.white54,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBlessingItem(String nickname, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: KouMingTheme.gold.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              nickname[0],
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: KouMingTheme.gold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nickname,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: KouMingTheme.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: TextStyle(
                  fontSize: 9,
                  color: KouMingTheme.dim.withValues(alpha: 0.8),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
