import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/i18n_service.dart';
import 'package:kouming/services/share_service.dart';
import 'package:kouming/features/shop/fulfill_ceremony.dart';

/// ─── Wish Capsule Viewer ───
///
/// Displays user's wish capsules with timeline, countdown, and maturity animation.
/// When a capsule is ready (daysLeft <= 0), user can open it with a reveal animation
/// and trigger the fulfillment ceremony (fireworks).

class CapsuleTimeline extends StatelessWidget {
  final List<WishCapsule> capsules;
  final void Function(WishCapsule) onFulfill;

  const CapsuleTimeline({
    super.key,
    required this.capsules,
    required this.onFulfill,
  });

  @override
  Widget build(BuildContext context) {
    if (capsules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              const Text('\u{1F4ED}', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(I18n.t('capsule_empty'),
                  style: const TextStyle(
                      fontSize: 14,
                      color: KouMingTheme.dim,
                      fontFamily: 'ZCOOLXiaoWei')),
              const SizedBox(height: 4),
              Text(I18n.t('capsule_empty_hint'),
                  style: const TextStyle(fontSize: 11, color: KouMingTheme.dim)),
            ],
          ),
        ),
      );
    }

    final waiting = capsules
        .where((c) => c.status == CapsuleStatus.waiting && c.daysLeft > 0)
        .toList();
    final ready = capsules
        .where((c) => c.status == CapsuleStatus.waiting && c.daysLeft <= 0)
        .toList();
    final fulfilled = capsules
        .where((c) => c.status == CapsuleStatus.fulfilled)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ready.isNotEmpty) ...[
            _sectionHeader('\u{1F52E} ${I18n.t('capsule_title')}', KouMingTheme.gold),
            const SizedBox(height: 4),
            Text(I18n.t('pool_light_meaning'),
                style: TextStyle(
                  fontSize: 9,
                  color: KouMingTheme.purple.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                )),
            const SizedBox(height: 8),
            ...ready.map((c) => _CapsuleCard(
                  capsule: c,
                  isReady: true,
                  onFulfill: onFulfill,
                )),
            const SizedBox(height: 16),
          ],

          if (waiting.isNotEmpty) ...[
            _sectionHeader('\u23F3 ${I18n.t('capsule_title')}', KouMingTheme.purple),
            const SizedBox(height: 8),
            ...waiting.map((c) => _CapsuleCard(
                  capsule: c,
                  isReady: false,
                  onFulfill: onFulfill,
                )),
            const SizedBox(height: 16),
          ],

          if (fulfilled.isNotEmpty) ...[
            _sectionHeader('\u2728 ${I18n.t('capsule_fulfilled')}', KouMingTheme.spirit),
            const SizedBox(height: 8),
            ...fulfilled.map((c) => _CapsuleCard(
                  capsule: c,
                  isReady: false,
                  onFulfill: onFulfill,
                )),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, Color color) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            )),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            )),
      ],
    );
  }
}

class _CapsuleCard extends StatefulWidget {
  final WishCapsule capsule;
  final bool isReady;
  final void Function(WishCapsule) onFulfill;

  const _CapsuleCard({
    required this.capsule,
    required this.isReady,
    required this.onFulfill,
  });

  @override
  State<_CapsuleCard> createState() => _CapsuleCardState();
}

class _CapsuleCardState extends State<_CapsuleCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Color get _categoryColor {
    switch (widget.capsule.category) {
      case 'study': return KouMingTheme.water;
      case 'health': return const Color(0xFF4CAF50);
      case 'love': return KouMingTheme.lantern;
      case 'money': return KouMingTheme.gold;
      default: return KouMingTheme.purple;
    }
  }

  String get _categoryEmoji {
    switch (widget.capsule.category) {
      case 'study': return '\u{1F4DA}';
      case 'health': return '\u{1FA7A}';
      case 'love': return '\u{1F49E}';
      case 'money': return '\u{1F4B0}';
      default: return '\u{1F30A}';
    }
  }

  double get _progress {
    final total = widget.capsule.dueDate.difference(widget.capsule.createdAt).inDays;
    final elapsed = DateTime.now().difference(widget.capsule.createdAt).inDays;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.capsule;
    final isFulfilled = c.status == CapsuleStatus.fulfilled;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KouMingTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isReady
              ? KouMingTheme.gold.withValues(alpha: 0.4)
              : isFulfilled
                  ? KouMingTheme.spirit.withValues(alpha: 0.2)
                  : _categoryColor.withValues(alpha: 0.12),
        ),
        boxShadow: widget.isReady
            ? [BoxShadow(color: KouMingTheme.gold.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 2)]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isFulfilled)
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => CustomPaint(
                      size: const Size(60, 60),
                      painter: _ProgressRingPainter(
                        progress: _progress,
                        color: _categoryColor,
                        isReady: widget.isReady,
                        pulse: widget.isReady ? _pulseCtrl.value : 0,
                      ),
                    ),
                  ),
                if (isFulfilled)
                  const Text('\u2728', style: TextStyle(fontSize: 28))
                else
                  AnimatedBuilder(
                    animation: _shimmerCtrl,
                    builder: (_, __) => CustomPaint(
                      size: const Size(36, 36),
                      painter: _CapsuleOrbPainter(
                        color: _categoryColor,
                        isReady: widget.isReady,
                        shimmer: _shimmerCtrl.value,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_categoryEmoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(c.wishText,
                          style: TextStyle(
                            fontSize: 12,
                            color: isFulfilled ? KouMingTheme.spirit : KouMingTheme.text,
                            decoration: isFulfilled ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isFulfilled)
                  Text(I18n.t('capsule_fulfilled'),
                      style: const TextStyle(fontSize: 10, color: KouMingTheme.spirit))
                else if (widget.isReady)
                  Text(I18n.t('capsule_fulfill_success'),
                      style: const TextStyle(fontSize: 10, color: KouMingTheme.gold, fontWeight: FontWeight.w600))
                else
                  Text(I18n.t('capsule_days_left', args: {'days': '${c.daysLeft}'}),
                      style: const TextStyle(fontSize: 10, color: KouMingTheme.dim)),
                const SizedBox(height: 6),
                if (!isFulfilled)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: _categoryColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isReady ? KouMingTheme.gold : _categoryColor,
                      ),
                      minHeight: 3,
                    ),
                  ),
              ],
            ),
          ),
          // Action buttons
          if (widget.isReady && !isFulfilled)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _OpenButton(
                isOpening: _isOpening,
                onTap: _openCapsule,
              ),
            ),
          if (isFulfilled)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () => ShareService.showShareSheet(context, wishText: c.wishText),
                child: const Text('\u{1F4E4}', style: TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openCapsule() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await FulfillCeremony.show(
      context,
      capsule: widget.capsule,
      onCeremonyComplete: () {},
    );

    if (!mounted) return;
    widget.onFulfill(widget.capsule);
    setState(() => _isOpening = false);
  }
}

class _OpenButton extends StatelessWidget {
  final bool isOpening;
  final VoidCallback onTap;

  const _OpenButton({required this.isOpening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isOpening ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isOpening ? null : const LinearGradient(colors: KouMingTheme.payGradient),
          color: isOpening ? KouMingTheme.gold.withValues(alpha: 0.3) : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isOpening ? null : [BoxShadow(color: KouMingTheme.gold.withValues(alpha: 0.3), blurRadius: 8)],
        ),
        child: Text(
          isOpening ? '\u23F3' : '\u{1F513}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isOpening ? KouMingTheme.dim : KouMingTheme.deep,
          ),
        ),
      ),
    );
  }
}

/// ─── Progress Ring Painter ───
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isReady;
  final double pulse;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.isReady,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);

    final progressColor = isReady
        ? Color.lerp(KouMingTheme.gold, Colors.white, pulse * 0.3)!
        : color;
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isReady ? 4 : 3
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    if (progress > 0.01) {
      final angle = -pi / 2 + sweepAngle;
      final dotX = center.dx + radius * cos(angle);
      final dotY = center.dy + radius * sin(angle);

      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.6 + (isReady ? pulse * 0.4 : 0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(dotX, dotY), isReady ? 5 : 3, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      progress != old.progress || pulse != old.pulse;
}

/// ─── Capsule Orb Painter ───
class _CapsuleOrbPainter extends CustomPainter {
  final Color color;
  final bool isReady;
  final double shimmer;

  _CapsuleOrbPainter({
    required this.color,
    required this.isReady,
    required this.shimmer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final glowPaint = Paint()
      ..color = (isReady ? KouMingTheme.gold : color).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius + 4, glowPaint);

    final orbPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: isReady
            ? [Colors.white, KouMingTheme.gold, KouMingTheme.warm]
            : [color.withValues(alpha: 0.3), color.withValues(alpha: 0.7), color],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, orbPaint);

    final shimmerAngle = shimmer * 2 * pi;
    final shimmerX = center.dx + radius * 0.4 * cos(shimmerAngle);
    final shimmerY = center.dy + radius * 0.4 * sin(shimmerAngle);
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: isReady ? 0.5 : 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(shimmerX, shimmerY), radius * 0.3, shimmerPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: isReady ? '\u{1F5DD}' : '\u{1F48A}',
        style: TextStyle(fontSize: radius * 0.8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CapsuleOrbPainter old) => shimmer != old.shimmer;
}
