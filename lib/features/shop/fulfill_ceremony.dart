import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/i18n_service.dart';
import 'package:kouming/shared/compliance_helper.dart';

class FulfillCeremony extends StatefulWidget {
  final WishCapsule capsule;
  final VoidCallback onCeremonyComplete;
  const FulfillCeremony({super.key, required this.capsule, required this.onCeremonyComplete});
  static Future<void> show(
    BuildContext context, {
    required WishCapsule capsule,
    required VoidCallback onCeremonyComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FulfillCeremony(capsule: capsule, onCeremonyComplete: onCeremonyComplete),
    );
  }
  @override
  State<FulfillCeremony> createState() => _FulfillCeremonyState();
}

class _FulfillCeremonyState extends State<FulfillCeremony> with TickerProviderStateMixin {
  late AnimationController _glowCtrl, _fireworkCtrl;
  bool _showFireworks = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _fireworkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _fireworkCtrl.dispose();
    super.dispose();
  }

  Future<void> _startCeremony() async {
    final ok = await showComplianceDialog(context);
    if (!ok) return;
    _glowCtrl.forward().then((_) {
      if (mounted) {
        setState(() => _showFireworks = true);
        _fireworkCtrl.forward();
      }
    });
  }

  static const Map<String, String> _catLabelKeys = {
    'study': 'fulfill_cat_study',
    'health': 'fulfill_cat_health',
    'love': 'fulfill_cat_love',
    'money': 'fulfill_cat_money',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [KouMingTheme.deep, KouMingTheme.mid],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(children: [
        Column(children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KouMingTheme.gold.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            I18n.t('fulfill_title'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: KouMingTheme.gold, fontFamily: 'MaShanZheng'),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildContent()),
        ]),
        if (_showFireworks)
          Positioned.fill(child: IgnorePointer(child: _FireworksCanvas(animation: _fireworkCtrl))),
      ]),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (ctx, _) {
        final t = _glowCtrl.value;
        final glowAlpha = t * 0.5;
        final scale = 1.0 + t * 0.1;
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      KouMingTheme.gold.withValues(alpha: glowAlpha + 0.2),
                      KouMingTheme.lantern.withValues(alpha: glowAlpha),
                      KouMingTheme.purple.withValues(alpha: glowAlpha * 0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(color: KouMingTheme.gold.withValues(alpha: glowAlpha), blurRadius: 40),
                    BoxShadow(color: KouMingTheme.lantern.withValues(alpha: glowAlpha * 0.5), blurRadius: 60),
                  ],
                ),
                child: Center(
                  child: Text('灯', style: TextStyle(fontSize: 40 + t * 8, fontFamily: 'MaShanZheng', color: KouMingTheme.gold)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: KouMingTheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.2)),
              ),
              child: Text(
                '"${widget.capsule.wishText}"',
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: KouMingTheme.text, fontFamily: 'MaShanZheng'),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(_getCategoryLabel(widget.capsule.category), style: const TextStyle(fontSize: 13, color: KouMingTheme.dim)),
            const SizedBox(height: 20),
            if (!_showFireworks) ...[
              Text(I18n.t('fulfill_prompt'), style: const TextStyle(fontSize: 12, color: KouMingTheme.dim)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _startCeremony,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [KouMingTheme.lantern, KouMingTheme.gold]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: KouMingTheme.lantern.withValues(alpha: 0.3), blurRadius: 12)],
                  ),
                  child: Text(I18n.t('fulfill_btn'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(I18n.t('fulfill_done'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KouMingTheme.gold, fontFamily: 'MaShanZheng')),
              const SizedBox(height: 4),
              Text(I18n.t('fulfill_merit'), style: const TextStyle(fontSize: 13, color: KouMingTheme.purple)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  widget.onCeremonyComplete();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [KouMingTheme.gold, KouMingTheme.warm]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(I18n.t('fulfill_close'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                ),
              ),
            ],
          ]),
        );
      },
    );
  }

  String _getCategoryLabel(String cat) => I18n.t(_catLabelKeys[cat] ?? 'fulfill_cat_other');
}

class _FireworksCanvas extends StatelessWidget {
  final Animation<double> animation;
  const _FireworksCanvas({required this.animation});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (ctx, _) => CustomPaint(painter: _FireworksPainter(animation.value), size: Size.infinite),
    );
  }
}

class _FireworksPainter extends CustomPainter {
  final double t;
  static final _rng = Random(42);
  _FireworksPainter(this.t);

  static final List<_Burst> _bursts = [
    _Burst(0.25, 0.25, KouMingTheme.gold, 20, 0.0),
    _Burst(0.75, 0.20, KouMingTheme.lantern, 18, 0.15),
    _Burst(0.50, 0.35, KouMingTheme.purple, 22, 0.30),
    _Burst(0.30, 0.45, Colors.pink, 16, 0.45),
    _Burst(0.70, 0.40, KouMingTheme.warm, 18, 0.55),
  ];

  @override
  void paint(Canvas c, Size s) {
    for (final b in _bursts) {
      _drawBurst(c, s, b);
    }
  }

  void _drawBurst(Canvas c, Size s, _Burst b) {
    if (t < b.startT) return;
    final lt = ((t - b.startT) / (1.0 - b.startT)).clamp(0.0, 1.0);
    final cx = s.width * b.x;
    final cy = s.height * b.y;
    final maxR = s.width * 0.18;
    for (int i = 0; i < b.count; i++) {
      final angle = (i / b.count) * 2 * pi + _rng.nextDouble() * 0.3;
      final speed = 0.5 + _rng.nextDouble() * 0.5;
      final pt = (lt * 1.5 - 0.2 * speed).clamp(0.0, 1.0);
      if (pt <= 0) continue;
      final r = maxR * pt * speed;
      final fade = pt > 0.6 ? 1.0 - (pt - 0.6) / 0.4 : 1.0;
      c.drawCircle(
        Offset(cx + cos(angle) * r, cy + sin(angle) * r - pt * 20),
        2.5 * (1 - pt * 0.5),
        Paint()..color = b.color.withValues(alpha: fade * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => t != old.t;
}

class _Burst {
  final double x, y;
  final Color color;
  final int count;
  final double startT;
  _Burst(this.x, this.y, this.color, this.count, this.startT);
}
