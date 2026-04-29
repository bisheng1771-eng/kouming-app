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

  const OfferingShop({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  @override
  State<OfferingShop> createState() => _OfferingShopState();
}

class _OfferingShopState extends State<OfferingShop>
    with TickerProviderStateMixin {
  String? _animatingOffering;
  late AnimationController _purchaseCtrl;

  static const _offerings = <_ShopOffering>[
    _ShopOffering(
      emoji: '\u{1F56F}',
      nameKey: 'shop_incense',
      descKey: 'shop_incense_desc',
      meaningKey: 'pool_throw_meaning',
      priceYuan: 1,
      meritReward: 5,
      section: _Section.offerings,
    ),
    _ShopOffering(
      emoji: '\u{1F338}',
      nameKey: 'shop_lotus',
      descKey: 'shop_lotus_desc',
      meaningKey: 'pool_light_meaning',
      priceYuan: 2,
      meritReward: 20,
      section: _Section.offerings,
    ),
    _ShopOffering(
      emoji: '\u{1F3EE}',
      nameKey: 'shop_river_lamp',
      descKey: 'shop_river_lamp_desc',
      meaningKey: 'pool_light_meaning',
      priceYuan: 3,
      meritReward: 30,
      section: _Section.offerings,
    ),
    _ShopOffering(
      emoji: '\u{1F3B4}',
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
  }

  @override
  void dispose() {
    _purchaseCtrl.dispose();
    super.dispose();
  }

  Future<void> _onPurchase(_ShopOffering offering) async {
    if (_animatingOffering != null) return;

    // Paid sections require compliance acknowledgment
    if (offering.section == _Section.fate || offering.section == _Section.fulfill) {
      final ok = await showComplianceDialog(context);
      if (!ok) return;
    }

    setState(() => _animatingOffering = offering.nameKey);
    _purchaseCtrl.forward(from: 0);

    // 获取用户ID
    final supabase = SupabaseService();
    final userId = supabase.userId ?? 'anonymous';

    // 根据产品类型调起支付宝支付
    String productType;
    if (offering.section == _Section.fate) {
      productType = 'fate';
    } else if (offering.section == _Section.fulfill) {
      productType = 'fulfill';
    } else {
      // 供奉品直接给奖励，不走支付
      productType = '';
    }

    // 需要支付的产品
    if (productType.isNotEmpty) {
      final result = await AlipayService.pay(
        product: productType,
        userId: userId,
      );

      if (result != 'success') {
        setState(() => _animatingOffering = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result == 'canceled' ? '支付已取消' : '支付失败，请重试'),
              backgroundColor: KouMingTheme.purple,
            ),
          );
        }
        return;
      }

      // 支付成功，记录到Supabase
      await supabase.createPayment(
        productType: productType,
        amount: offering.priceYuan,
      );
      
      // 支付成功，增加功德点奖励
      if (offering.meritReward > 0) {
        widget.onStateChanged(
          widget.state.copyWith(
            meritPoints: widget.state.meritPoints + offering.meritReward,
          ),
        );
      }
    }

    if (offering.meritReward > 0) {
      widget.onStateChanged(
        widget.state.copyWith(
          meritPoints: widget.state.meritPoints + offering.meritReward,
        ),
      );
    }

    if (offering.section == _Section.fate) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        // 获取用户最近的愿望作为AI解读的上下文
        final recentWish = widget.state.myWishes.isNotEmpty
            ? widget.state.myWishes.first.text
            : null;
        FateDrawFlow.show(
          context,
          onDrawComplete: () {},
          onPaymentRequired: () {},
          wishText: recentWish,
        );
      });
    } else if (offering.section == _Section.fulfill) {
      final dueCapsules = widget.state.capsules
          .where((c) => c.canFulfill)
          .toList();
      if (dueCapsules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(I18n.t('snack_no_fulfill')),
            backgroundColor: KouMingTheme.purple,
          ),
        );
        return;
      }
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        FulfillCeremony.show(
          context,
          capsule: dueCapsules.first,
          onCeremonyComplete: () {
            final updated = dueCapsules.first.copyWith(s: CapsuleStatus.fulfilled);
            final newCapsules = widget.state.capsules.map(
              (c) => c.id == updated.id ? updated : c,
            ).toList();
            widget.onStateChanged(
              widget.state.copyWith(
                capsules: newCapsules,
                meritPoints: widget.state.meritPoints + 36,
              ),
            );
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offeringItems = _offerings.where((o) => o.section == _Section.offerings).toList();
    final fateItems = _offerings.where((o) => o.section == _Section.fate).toList();
    final fulfillItems = _offerings.where((o) => o.section == _Section.fulfill).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),

          // Section 1: Offerings
          _buildSectionTitle('\u{1F56F} ${I18n.t('shop_offerings')}', I18n.t('shop_offerings_desc')),
          const SizedBox(height: 8),
          ...offeringItems.map((o) => _buildOfferingCard(o)),
          const SizedBox(height: 20),

          // Section 2: Fate Draw
          _buildSectionTitle('\u{1F3B4} ${I18n.t('shop_fate')}', I18n.t('shop_fate_desc')),
          const SizedBox(height: 8),
          ...fateItems.map((o) => _buildOfferingCard(o)),
          const SizedBox(height: 20),

          // Section 3: Fulfillment
          _buildSectionTitle('\u{1F386} ${I18n.t('shop_fulfill_section')}', I18n.t('shop_fulfill_section_desc')),
          const SizedBox(height: 8),
          if (widget.state.capsules.where((c) => c.canFulfill).isEmpty)
            _buildNoCapsuleHint()
          else
            ...fulfillItems.map((o) => _buildOfferingCard(o)),
          const SizedBox(height: 20),

          // Merit tier info
          _buildMeritTierInfo(),

          // Share row
          const SizedBox(height: 20),
          _buildShareRow(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KouMingTheme.gold.withValues(alpha: 0.12),
            KouMingTheme.purple.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Text('\u{1F3EE}', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(I18n.t('shop_title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: KouMingTheme.gold,
                      fontFamily: 'MaShanZheng',
                    )),
                const SizedBox(height: 2),
                Text(I18n.t('shop_level_merit', args: {
                  'level': '${widget.state.meritLevel}',
                  'merit': '${widget.state.meritPoints}',
                }),
                    style: const TextStyle(fontSize: 11, color: KouMingTheme.dim)),
              ],
            ),
          ),
          _buildMeritBadge(),
        ],
      ),
    );
  }

  Widget _buildMeritBadge() {
    final level = widget.state.meritLevel;
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
      child: Text('Lv.$level',
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
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onPurchase(offering),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [KouMingTheme.gold, KouMingTheme.warm],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '\u00A5${offering.priceYuan}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
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
          Text(I18n.t('shop_merit_tiers'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KouMingTheme.purple,
              )),
          const SizedBox(height: 8),
          _tierRow('\u{1F30A} ${I18n.t('shop_tier_seeker')}', 'Lv.1-4', KouMingTheme.water),
          _tierRow('\u{1F3EE} ${I18n.t('shop_tier_devotee')}', 'Lv.5-9', KouMingTheme.purple),
          _tierRow('\u{1F451} ${I18n.t('shop_tier_master')}', 'Lv.10-19', KouMingTheme.lantern),
          _tierRow('\u2728 ${I18n.t('shop_tier_sage')}', 'Lv.20+', KouMingTheme.gold),
        ],
      ),
    );
  }

  Widget _tierRow(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const Spacer(),
          Text(range, style: const TextStyle(fontSize: 10, color: KouMingTheme.dim)),
        ],
      ),
    );
  }

  Widget _buildShareRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KouMingTheme.gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Text('\u{1F4E4}', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(I18n.t('pool_share_label'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: KouMingTheme.gold,
                    )),
                Text(I18n.t('pool_share_hint'),
                    style: const TextStyle(fontSize: 9, color: KouMingTheme.dim)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => ShareService.showShareSheet(context, wishText: ''),
            style: OutlinedButton.styleFrom(
              foregroundColor: KouMingTheme.gold,
              side: BorderSide(color: KouMingTheme.gold.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(I18n.t('pool_share_label'), style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
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
