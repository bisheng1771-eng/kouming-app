import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/i18n_service.dart';
import 'package:kouming/services/share_service.dart';
import 'package:kouming/services/alipay_service.dart';
import 'package:kouming/services/supabase_service.dart';
import 'package:kouming/features/shop/fate_draw_flow.dart';
import 'package:kouming/features/shop/fulfill_ceremony.dart';
import 'package:kouming/shared/compliance_helper.dart';

/// ─── Offering Shop — three sections ───
/// 1. Offerings (Incense/Lotus/River Lamp) → merit + animation
/// 2. Fate Draw (¥6) → draw animation + result
/// 3. Fulfillment Rite (¥3.6) → fireworks celebration

class OfferingShop extends StatefulWidget {
  final AppState state;
  final void Function(AppState) onStateChanged;
  final Future<bool> Function()? requireLogin;

  const OfferingShop({
    super.key,
    required this.state,
    required this.onStateChanged,
    this.requireLogin,
  });

  @override
  State<OfferingShop> createState() => _OfferingShopState();
}

class _OfferingShopState extends State<OfferingShop>
    with TickerProviderStateMixin {
  String? _animatingOffering;
  late AnimationController _purchaseCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _glowCtrl;
  
  // 粒子列表
  final List<_Particle> _particles = [];
  // 功德跳动动画
  int? _meritDelta;
  bool _showMeritPopup = false;

  static const _offerings = <_ShopOffering>[
    _ShopOffering(
      emoji: '\u{1F56F}',  // 🕯️ 微光 - 蜡烛
      nameKey: 'shop_incense',
      descKey: 'shop_incense_desc',
      meaningKey: 'pool_throw_meaning',
      priceYuan: 1,
      meritReward: 5,
      section: _Section.offerings,
    ),
    _ShopOffering(
      emoji: '\u{1FAB7}',  // 🪷 花灯 - 莲花
      nameKey: 'shop_lotus',
      descKey: 'shop_lotus_desc',
      meaningKey: 'pool_light_meaning',
      priceYuan: 2,
      meritReward: 20,
      section: _Section.offerings,
    ),
    _ShopOffering(
      emoji: '\u{1F3EE}',  // 🏮 长明灯 - 孔明灯/灯笼
      nameKey: 'shop_river_lamp',
      descKey: 'shop_river_lamp_desc',
      meaningKey: 'pool_light_meaning',
      priceYuan: 3,
      meritReward: 30,
      section: _Section.offerings,
    ),
    _ShopOffering(
      emoji: '\u{1F4DC}',  // 📜 祈福签 - 卷轴
      nameKey: 'shop_fortune_draw',
      descKey: 'shop_fortune_desc',
      meaningKey: 'pool_oracle_hint',
      priceYuan: 6,
      meritReward: 0,
      section: _Section.fate,
    ),
    _ShopOffering(
      emoji: '\u{1F386}',
      nameKey: 'shop_fulfillment_rite',
      descKey: 'shop_fulfillment_desc',
      meaningKey: 'pool_light_meaning',
      priceYuan: 3.6,
      meritReward: 36,
      section: _Section.fulfill,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _purchaseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _purchaseCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _animatingOffering = null);
      }
    });
    
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _purchaseCtrl.dispose();
    _particleCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }
  
  /// 生成粒子效果
  void _spawnParticles(Offset position, Color color) {
    _particles.clear();
    final random = DateTime.now().millisecond;
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        x: position.dx,
        y: position.dy,
        vx: (i % 3 - 1) * 2.0 + (random % 10) / 10,
        vy: -3.0 - (i % 5) * 0.5,
        size: 3.0 + (i % 4) * 1.5,
        color: color,
        life: 1.0,
      ));
    }
    _particleCtrl.forward(from: 0);
  }

  Future<void> _onPurchase(_ShopOffering offering) async {
    if (_animatingOffering != null) return;

    // 记录点击
    final supabase = SupabaseService();
    await supabase.ensureLogin();
    await supabase.createClick(
      buttonName: offering.nameKey,
      nickname: widget.state.nickname,
    );

    // 检查登录状态
    if (widget.requireLogin != null) {
      final loggedIn = await widget.requireLogin!();
      if (!loggedIn) return;
    }

    // All paid items require compliance acknowledgment
    if (offering.priceYuan > 0) {
      final ok = await showComplianceDialog(context);
      if (!ok) return;
    }

    setState(() => _animatingOffering = offering.nameKey);
    _purchaseCtrl.forward(from: 0);

    final userId = supabase.userId ?? 'anonymous';

    // Map every offering to a product type for payment
    String productType;
    switch (offering.section) {
      case _Section.fate:
        productType = 'fate';
        break;
      case _Section.fulfill:
        productType = 'fulfill';
        break;
      case _Section.offerings:
        if (offering.nameKey == 'shop_incense') {
          productType = 'incense';
        } else if (offering.nameKey == 'shop_lotus') {
          productType = 'lotus';
        } else {
          productType = 'river';
        }
        break;
    }

    // Payment confirmation dialog (like FateDrawFlow/OracleFlow)
    final productName = AlipayService.getName(productType);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: KouMingTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('确认支付', style: const TextStyle(color: KouMingTheme.gold, fontFamily: 'MaShanZheng')),
        content: Text('即将支付 ¥${offering.priceYuan.toStringAsFixed(2)} 购买$productName', style: const TextStyle(color: KouMingTheme.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: KouMingTheme.dim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认支付', style: TextStyle(color: KouMingTheme.gold)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      setState(() => _animatingOffering = null);
      return;
    }

    // --- 还愿产品：弹还愿仪式动画 ---
    if (offering.section == _Section.fulfill) {
      final dueCapsules = widget.state.capsules.where((c) => c.canFulfill).toList();
      // 注意：保持动画状态直到弹窗出现，不要在此处清 _animatingOffering
      if (dueCapsules.isEmpty) {
        setState(() => _animatingOffering = null); // 没有胶囊时才清状态
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(I18n.t('snack_no_fulfill')), backgroundColor: KouMingTheme.purple),
          );
        }
        return;
      }
      // 直接弹出还愿仪式动画，等弹窗出现后再清动画状态
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() => _animatingOffering = null);
        FulfillCeremony.show(
          context,
          capsule: dueCapsules.first,
          onCeremonyComplete: () {
            // 用户确认付款后，记录支付并更新状态
            supabase.createPayment(productType: productType, amount: offering.priceYuan);
            final updated = dueCapsules.first.copyWith(s: CapsuleStatus.fulfilled);
            final newCapsules = widget.state.capsules.map(
              (c) => c.id == updated.id ? updated : c,
            ).toList();
            widget.onStateChanged(widget.state.copyWith(
              capsules: newCapsules,
              meritPoints: widget.state.meritPoints + 36,
            ));
          },
        );
      });
      return;
    }

    // --- 跳过支付宝，直接展示付费成功动效 ---
    // 展示成功提示 + 动效（无需真实支付）
    _showPaySuccessAnimation(offering, productType);
  }

  void _showPaySuccessAnimation(_ShopOffering offering, String productType) {
    // 通知用户付费成功
    if (offering.section == _Section.fate) {
      // 祈福签：直接展示抽签动画
      final recentWish = widget.state.myWishes.isNotEmpty ? widget.state.myWishes.first.text : null;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() => _animatingOffering = null);
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        FateDrawFlow.show(
          context,
          onDrawComplete: () {},
          onPaymentRequired: () {},
          wishText: recentWish,
          freeAvailable: true,
          onFreeUsed: () {},
        );
      });
      return;
    }

    // 三个法物（微光/花灯/长明灯）：显示功德增加动画
    if (offering.meritReward > 0) {
      _showMeritIncrease(offering.meritReward);
      widget.onStateChanged(widget.state.copyWith(meritPoints: widget.state.meritPoints + offering.meritReward));
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _animatingOffering = null);
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() { _showMeritPopup = false; _meritDelta = null; });
    });
  }

  /// 显示功德增加动画
  void _showMeritIncrease(int delta) {
    setState(() {
      _meritDelta = delta;
      _showMeritPopup = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final offeringItems = _offerings.where((o) => o.section == _Section.offerings).toList();
    final fateItems = _offerings.where((o) => o.section == _Section.fate).toList();
    final fulfillItems = _offerings.where((o) => o.section == _Section.fulfill).toList();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),

          // 所有法物并列展示
          ...offeringItems.map((o) => _buildOfferingCard(o)),
          ...fateItems.map((o) => _buildOfferingCard(o)),
          const SizedBox(height: 20),

          // 我的寻光路（从我的页面移过来）
          _buildSectionTitle('\u{1F3A2} 寻光路', '记录你的修行足迹'),
          const SizedBox(height: 8),
          _buildJourneyStats(),
          const SizedBox(height: 20),

          // 等级福利信息（从我的页面移过来）
          _buildMeritTierInfo(),

          // 分享功能已移至心愿胶囊
        ],
      ),
    ),
    
    // 粒子动画层
    if (_particles.isNotEmpty)
      AnimatedBuilder(
        animation: _particleCtrl,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ParticlePainter(
              particles: _particles,
              progress: _particleCtrl.value,
            ),
          );
        },
      ),
    
    // 功德增加弹出效果
    if (_showMeritPopup && _meritDelta != null)
      Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Opacity(
              opacity: value > 0.7 ? (1 - value) * 3.33 : value,
              child: Transform.translate(
                offset: Offset(0, -50 * value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [KouMingTheme.gold, KouMingTheme.warm],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: KouMingTheme.gold.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        '功德 +$_meritDelta',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                          fontFamily: 'MaShanZheng',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('✨', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text('法物商店',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: KouMingTheme.gold,
              fontFamily: 'MaShanZheng',
            )),
      ),
    );
  }

  Widget _buildMeritBadge() {
    final level = widget.state.meritLevel;
    final title = widget.state.levelBenefits.title;
    final color = level >= 10
        ? KouMingTheme.gold
        : level >= 5
            ? KouMingTheme.purple
            : KouMingTheme.water;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('Lv.$level $title',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          )),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: KouMingTheme.gold,
              letterSpacing: 1,
            )),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(fontSize: 10, color: KouMingTheme.dim)),
      ],
    );
  }

  Widget _buildOfferingCard(_ShopOffering offering) {
    final isAnimating = _animatingOffering == offering.nameKey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AnimatedBuilder(
        animation: _purchaseCtrl,
        builder: (context, child) {
          double scale = 1.0;
          double glowAlpha = 0.0;

          if (isAnimating) {
            final t = _purchaseCtrl.value;
            scale = t < 0.3
                ? 1.0 + t * 0.15
                : 1.045 - (t - 0.3) * 0.07;
            glowAlpha = t < 0.5 ? t * 2 : (1 - t) * 2;
          }

          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KouMingTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAnimating
                      ? KouMingTheme.gold.withValues(alpha: glowAlpha)
                      : KouMingTheme.gold.withValues(alpha: 0.08),
                ),
                boxShadow: isAnimating
                    ? [
                        BoxShadow(
                          color: KouMingTheme.gold.withValues(alpha: glowAlpha * 0.5),
                          blurRadius: 20,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Emoji
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: KouMingTheme.gold.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(offering.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(I18n.t(offering.nameKey),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: KouMingTheme.text)),
                        const SizedBox(height: 2),
                        Text(I18n.t(offering.descKey),
                            style: const TextStyle(
                                fontSize: 10, color: KouMingTheme.dim)),
                        // Meaning line (psychology principle)
                        if (offering.meaningKey.isNotEmpty)
                          Text(I18n.t(offering.meaningKey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8,
                                color: KouMingTheme.purple.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              )),
                        if (offering.meritReward > 0)
                          Text(I18n.t('shop_merit_reward', args: {'merit': '${offering.meritReward}'}),
                              style: const TextStyle(
                                  fontSize: 10, color: KouMingTheme.purple)),
                      ],
                    ),
                  ),
                  // Buy button
                  GestureDetector(
                    onTap: () => _onPurchase(offering),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [KouMingTheme.gold, KouMingTheme.warm],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        offering.priceYuan > 0 ? '\u00A5${offering.priceYuan}' : '供奉',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoCapsuleHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KouMingTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KouMingTheme.water.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Text('\u{1F4E6}', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              I18n.t('shop_no_capsule'),
              style: const TextStyle(fontSize: 11, color: KouMingTheme.dim),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeritTierInfo() {
    final currentLevel = widget.state.meritLevel;
    final benefits = widget.state.levelBenefits;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KouMingTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KouMingTheme.purple.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前等级
          Row(
            children: [
              const Text('等级福利',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KouMingTheme.purple,
                  )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: KouMingTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '当前: Lv.$currentLevel ${benefits.title}',
                  style: const TextStyle(fontSize: 10, color: KouMingTheme.gold, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 等级对应表 - 升级增加许愿和祈福签次数
          _tierRow('Lv.1', '寻光者', '许愿4次/捞愿6次', KouMingTheme.water, currentLevel == 1),
          _tierRow('Lv.2', '修行者', '许愿5次/捞愿7次/免费算卦1次', KouMingTheme.water, currentLevel == 2),
          _tierRow('Lv.3', '悟道者', '许愿6次/捞愿8次/免费算卦1次/祈福签1次', KouMingTheme.water, currentLevel == 3),
          _tierRow('Lv.4', '护法', '许愿7次/捞愿9次/免费算卦2次/祈福签1次', KouMingTheme.purple, currentLevel == 4),
          _tierRow('Lv.5', '长老', '许愿8次/捞愿10次/免费算卦2次/祈福签1次', KouMingTheme.purple, currentLevel == 5),
          _tierRow('Lv.6', '尊者', '许愿9次/捞愿11次/免费算卦3次/祈福签2次', KouMingTheme.purple, currentLevel == 6),
          _tierRow('Lv.7', '圣者', '许愿10次/捞愿12次/免费算卦3次/祈福签2次', KouMingTheme.lantern, currentLevel == 7),
          _tierRow('Lv.8', '半仙', '许愿11次/捞愿13次/免费算卦4次/祈福签2次', KouMingTheme.lantern, currentLevel == 8),
          _tierRow('Lv.9', '天命之人', '许愿12次/捞愿14次/免费算卦4次/祈福签3次', KouMingTheme.lantern, currentLevel == 9),
          _tierRow('Lv.10+', '化境', '许愿13次+/捞愿15次+/免费算卦5次+/祈福签3次+', KouMingTheme.gold, currentLevel >= 10),
        ],
      ),
    );
  }

  Widget _tierRow(String level, String title, String benefits, Color color, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isCurrent ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isCurrent ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Text(level, style: TextStyle(fontSize: 10, color: color, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 10, color: KouMingTheme.text.withValues(alpha: 0.9))),
          const Spacer(),
          Text(benefits, style: const TextStyle(fontSize: 9, color: KouMingTheme.dim)),
        ],
      ),
    );
  }

  Widget _buildJourneyStats() {
    final benefits = widget.state.levelBenefits;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KouMingTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KouMingTheme.water.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // 计算已用次数 = 总次数 - 剩余次数
          _journeyRow('\u{1F30A}', '今日许愿', '${(benefits.dailyThrowLimit - widget.state.throwLimit).clamp(0, benefits.dailyThrowLimit)}/${benefits.dailyThrowLimit}', '每日向宇宙发出信号'),
          const SizedBox(height: 8),
          _journeyRow('\u{1F3EE}', '今日捞愿', '${(benefits.dailyFishLimit - widget.state.fishLimit).clamp(0, benefits.dailyFishLimit)}/${benefits.dailyFishLimit}', '从池中捞起共鸣的心愿'),
          const SizedBox(height: 8),
          _journeyRow('\u2728', '今日免费算卦', '${widget.state.freeOracleUsed.clamp(0, benefits.freeOracleCount)}/${benefits.freeOracleCount}', '等级福利'),
          const SizedBox(height: 8),
          _journeyRow('\u{1F3B0}', '今日免费祈福签', '${widget.state.freeFateDrawUsed.clamp(0, benefits.freeFateDrawCount)}/${benefits.freeFateDrawCount}', '等级福利'),
        ],
      ),
    );
  }

  Widget _journeyRow(String emoji, String label, String value, String meaning) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: KouMingTheme.text)),
              Text(meaning, style: TextStyle(fontSize: 8, color: KouMingTheme.purple.withValues(alpha: 0.7), fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KouMingTheme.gold)),
      ],
    );
  }

  // 分享功能已删除
  // Widget _buildShareRow() { ... }
}

// ─── Data Classes ───

enum _Section { offerings, fate, fulfill }

class _ShopOffering {
  final String emoji;
  final String nameKey;
  final String descKey;
  final String meaningKey;
  final double priceYuan;
  final int meritReward;
  final _Section section;

  const _ShopOffering({
    required this.emoji,
    required this.nameKey,
    required this.descKey,
    required this.meaningKey,
    required this.priceYuan,
    required this.meritReward,
    required this.section,
  });
}

/// 粒子数据类
class _Particle {
  double x, y;
  double vx, vy;
  double size;
  Color color;
  double life;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
  });
}

/// 粒子绘制器
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final t = progress;
      final x = particle.x + particle.vx * t * 100;
      final y = particle.y + particle.vy * t * 100 + 0.5 * 9.8 * t * t * 50;
      final life = (1 - t).clamp(0.0, 1.0);
      
      if (life <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: life)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        particle.size * life,
        paint,
      );
      
      // 发光效果
      final glowPaint = Paint()
        ..color = particle.color.withValues(alpha: life * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size * life * 2,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
