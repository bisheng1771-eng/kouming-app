import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/i18n_service.dart';

class FulfillCeremony extends StatefulWidget {
  final WishCapsule capsule;
  final VoidCallback onCeremonyComplete;
  final String? fulfillText;
  const FulfillCeremony({super.key, required this.capsule, required this.onCeremonyComplete, this.fulfillText});

  static Future<void> show(
    BuildContext context, {
    required WishCapsule capsule,
    required VoidCallback onCeremonyComplete,
    String? fulfillText,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => FulfillCeremony(capsule: capsule, onCeremonyComplete: onCeremonyComplete, fulfillText: fulfillText),
    );
  }

  @override
  State<FulfillCeremony> createState() => _FulfillCeremonyState();
}

class _FulfillCeremonyState extends State<FulfillCeremony> with TickerProviderStateMixin {
  late AnimationController _phaseCtrl;
  late AnimationController _lanternCtrl;
  late AnimationController _fireworkCtrl;
  late AnimationController _sparkleCtrl;
  bool _showLanterns = false;
  bool _showFireworks = false;
  bool _showSparkles = false;

  @override
  void initState() {
    super.initState();
    _phaseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000));
    _lanternCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));
    _fireworkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000));
    _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000));

    _phaseCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() {
          _showLanterns = true;
          _showFireworks = true;
          _showSparkles = true;
        });
        _lanternCtrl.forward();
        _fireworkCtrl.forward();
        _sparkleCtrl.forward();
      }
    });

    // 直接启动动画
    _phaseCtrl.forward();
  }

  @override
  void dispose() {
    _phaseCtrl.dispose();
    _lanternCtrl.dispose();
    _fireworkCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  static const Map<String, String> _catLabelKeys = {
    'study': 'fulfill_cat_study',
    'health': 'fulfill_cat_health',
    'love': 'fulfill_cat_love',
    'money': 'fulfill_cat_money',
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [KouMingTheme.deep, KouMingTheme.mid],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Stack(children: [
          // Background effects
          if (_showSparkles)
            Positioned.fill(child: IgnorePointer(child: _SparkleCanvas(animation: _sparkleCtrl))),
          if (_showLanterns)
            Positioned.fill(child: IgnorePointer(child: _LanternCanvas(animation: _lanternCtrl))),
          if (_showFireworks)
            Positioned.fill(child: IgnorePointer(child: _FireworksCanvas(animation: _fireworkCtrl))),

          // Main content
          SingleChildScrollView(
            child: Column(children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  I18n.t('fulfill_title'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: KouMingTheme.gold, fontFamily: 'MaShanZheng'),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _phaseCtrl,
                builder: (ctx, _) => _buildCeremonyPhase(),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildCeremonyPhase() {
    final t = _phaseCtrl.value;
    final phase1End = 0.3;
    final glowAlpha = t < phase1End ? t / phase1End * 0.6 : 0.6;
    final glowRadius = 30.0 + t * 60;
    final pulseScale = 1.0 + sin(t * pi * 2) * 0.03 * (1 - t);
    final textRise = t > phase1End ? (t - phase1End) / (1 - phase1End) * 80.0 : 0.0;
    final textOpacity = t > phase1End ? 1.0 - (t - phase1End) / (1 - phase1End) * 0.7 : 1.0;

    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Central lantern glow
        Transform.scale(
          scale: pulseScale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120 + glowRadius,
                height: 120 + glowRadius,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      KouMingTheme.lantern.withValues(alpha: glowAlpha * 0.3),
                      KouMingTheme.gold.withValues(alpha: glowAlpha * 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: KouMingTheme.gold.withValues(alpha: glowAlpha * 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: KouMingTheme.gold.withValues(alpha: glowAlpha * 0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      KouMingTheme.gold.withValues(alpha: glowAlpha + 0.3),
                      KouMingTheme.lantern.withValues(alpha: glowAlpha),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: KouMingTheme.gold.withValues(alpha: glowAlpha),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '🏮',
                    style: TextStyle(fontSize: 32 + t * 6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Transform.translate(
          offset: Offset(0, -textRise),
          child: Opacity(
            opacity: textOpacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    KouMingTheme.gold.withValues(alpha: 0.15),
                    KouMingTheme.surface.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: KouMingTheme.gold.withValues(alpha: 0.3 + glowAlpha * 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: KouMingTheme.gold.withValues(alpha: glowAlpha * 0.2),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Text(
                '"${widget.capsule.wishText}"',
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: KouMingTheme.text,
                  fontFamily: 'MaShanZheng',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getCategoryLabel(widget.capsule.category),
          style: const TextStyle(fontSize: 13, color: KouMingTheme.dim),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                KouMingTheme.gold.withValues(alpha: 0.2),
                KouMingTheme.lantern.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.4)),
          ),
          child: Text(
            I18n.t('fulfill_done'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: KouMingTheme.gold,
              fontFamily: 'MaShanZheng',
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          I18n.t('fulfill_merit'),
          style: const TextStyle(fontSize: 14, color: KouMingTheme.purple),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            widget.onCeremonyComplete();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [KouMingTheme.gold, KouMingTheme.warm],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: KouMingTheme.gold.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Text(
              '完成，关闭',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
          ),
        ),
      ]),
    );
  }

  String _getCategoryLabel(String cat) => I18n.t(_catLabelKeys[cat] ?? 'fulfill_cat_other');
}

// ============================================================
// Fireworks Canvas
// ============================================================
class _FireworksCanvas extends StatelessWidget {
  final Animation<double> animation;
  const _FireworksCanvas({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (ctx, _) => CustomPaint(
        painter: _FireworksPainter(animation.value),
        size: Size.infinite,
      ),
    );
  }
}

class _FireworksPainter extends CustomPainter {
  final double t;
  static final _rng = Random(42);

  _FireworksPainter(this.t);

  static final List<_Shell> _shells = [
    _Shell(0.50, 0.30, KouMingTheme.gold, 40, 0.05, 0.12),
    _Shell(0.22, 0.25, KouMingTheme.lantern, 30, 0.18, 0.10),
    _Shell(0.78, 0.28, KouMingTheme.purple, 28, 0.22, 0.11),
    _Shell(0.35, 0.18, Colors.pink.shade200, 24, 0.30, 0.09),
    _Shell(0.65, 0.16, KouMingTheme.warm, 22, 0.35, 0.10),
    _Shell(0.40, 0.40, KouMingTheme.water, 20, 0.42, 0.11),
    _Shell(0.60, 0.42, KouMingTheme.lantern, 25, 0.48, 0.10),
    _Shell(0.30, 0.22, Colors.amber, 35, 0.55, 0.13),
    _Shell(0.70, 0.24, KouMingTheme.gold, 32, 0.60, 0.12),
    _Shell(0.50, 0.35, Colors.orange.shade300, 18, 0.65, 0.08),
    _Shell(0.25, 0.38, KouMingTheme.purple, 16, 0.70, 0.09),
    _Shell(0.75, 0.32, KouMingTheme.warm, 20, 0.72, 0.10),
  ];

  @override
  void paint(Canvas c, Size s) {
    for (final shell in _shells) _drawShell(c, s, shell);
  }

  void _drawShell(Canvas c, Size s, _Shell shell) {
    if (t < shell.startT) return;
    final localT = ((t - shell.startT) / shell.duration).clamp(0.0, 1.0);
    final cx = s.width * shell.x;
    final cy = s.height * shell.y;
    final maxR = s.width * 0.16;

    if (localT < 0.12) {
      final riseHeight = -s.height * 0.25 * (1 - localT / 0.12);
      final riseOpacity = (1 - localT / 0.12);
      for (int i = 0; i < 8; i++) {
        final trailY = riseHeight * (i / 8);
        c.drawCircle(
          Offset(cx + _rng.nextDouble() * 4 - 2, cy + trailY + _rng.nextDouble() * 4 - 2),
          2.0 * (1 - i / 8),
          Paint()..color = KouMingTheme.gold.withValues(alpha: riseOpacity * 0.6 * (1 - i / 10)),
        );
      }
      c.drawCircle(
        Offset(cx, cy + riseHeight),
        3.5,
        Paint()..color = KouMingTheme.gold.withValues(alpha: riseOpacity),
      );
      return;
    }

    final explodeT = ((localT - 0.12) / 0.88).clamp(0.0, 1.0);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < shell.count; i++) {
      final angle = (i / shell.count) * 2 * pi + _rng.nextDouble() * 0.4;
      final speed = 0.6 + _rng.nextDouble() * 0.4;
      final r = maxR * explodeT * speed;
      final fade = explodeT > 0.7 ? 1.0 - (explodeT - 0.7) / 0.3 : 1.0;
      if (fade <= 0) continue;
      final px = cx + cos(angle) * r;
      final py = cy + sin(angle) * r - explodeT * 15;
      if (i % 3 == 0) {
        final sz = 3.0 * (1 - explodeT * 0.5);
        paint.color = shell.color.withValues(alpha: fade * 0.95);
        c.drawRect(Rect.fromCenter(center: Offset(px, py), width: sz * 2, height: sz * 0.5), paint);
        c.drawRect(Rect.fromCenter(center: Offset(px, py), width: sz * 0.5, height: sz * 2), paint);
      } else {
        final sz = 2.5 * (1 - explodeT * 0.5);
        paint.color = shell.color.withValues(alpha: fade * 0.85);
        c.drawCircle(Offset(px, py), sz, paint);
      }
    }
    if (explodeT < 0.08) {
      final flashAlpha = (1 - explodeT / 0.08);
      c.drawCircle(
        Offset(cx, cy),
        8 + explodeT * 40,
        Paint()..color = Colors.white.withValues(alpha: flashAlpha * 0.8)..style = PaintingStyle.stroke..strokeWidth = 2 * flashAlpha,
      );
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => t != old.t;
}

class _Shell {
  final double x, y, startT, duration;
  final Color color;
  final int count;
  _Shell(this.x, this.y, this.color, this.count, this.startT, this.duration);
}

// ============================================================
// Rising Lanterns Canvas
// ============================================================
class _LanternCanvas extends StatelessWidget {
  final Animation<double> animation;
  const _LanternCanvas({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (ctx, _) => CustomPaint(
        painter: _LanternPainter(animation.value),
        size: Size.infinite,
      ),
    );
  }
}

class _LanternPainter extends CustomPainter {
  final double t;
  static final _rng = Random(99);

  _LanternPainter(this.t);

  static final _lanternData = List.generate(12, (i) {
    return _Lantern(
      x: 0.08 + _rng.nextDouble() * 0.84,
      startY: 0.65 + _rng.nextDouble() * 0.3,
      speed: 0.4 + _rng.nextDouble() * 0.6,
      sway: (_rng.nextDouble() - 0.5) * 0.04,
      size: 3.5 + _rng.nextDouble() * 4,
      delay: _rng.nextDouble() * 0.3,
    );
  });

  @override
  void paint(Canvas c, Size s) {
    for (final lantern in _lanternData) _drawLantern(c, s, lantern);
  }

  void _drawLantern(Canvas c, Size s, _Lantern l) {
    if (t < l.delay) return;
    final lt = ((t - l.delay) / (1.0 - l.delay)).clamp(0.0, 1.0);
    final cx = s.width * (l.x + sin(lt * 8 + l.x * 10) * l.sway);
    final rise = lt * s.height * 1.2;
    final cy = s.height * l.startY - rise;
    final glowAlpha = (lt < 0.15 ? lt / 0.15 : (lt > 0.85 ? (1 - lt) / 0.15 : 1.0)) * 0.3;
    c.drawCircle(
      Offset(cx, cy),
      l.size * 2.5,
      Paint()..color = KouMingTheme.lantern.withValues(alpha: glowAlpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final lanternColor = iToColor(_rng.nextInt(6));
    c.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: l.size, height: l.size * 1.4),
      Paint()..color = lanternColor.withValues(alpha: 0.85),
    );
    c.drawRect(
      Rect.fromCenter(center: Offset(cx, cy - l.size * 0.75), width: l.size * 0.7, height: 1.5),
      Paint()..color = KouMingTheme.gold.withValues(alpha: 0.9),
    );
    c.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + l.size * 0.75), width: l.size * 0.7, height: 1.5),
      Paint()..color = KouMingTheme.gold.withValues(alpha: 0.9),
    );
  }

  Color iToColor(int i) {
    switch (i) {
      case 0: return KouMingTheme.lantern;
      case 1: return KouMingTheme.gold;
      case 2: return Colors.pink.shade300;
      case 3: return KouMingTheme.warm;
      case 4: return Colors.amber.shade300;
      default: return KouMingTheme.purple;
    }
  }

  @override
  bool shouldRepaint(_LanternPainter old) => t != old.t;
}

class _Lantern {
  final double x, startY, speed, sway, size, delay;
  _Lantern({required this.x, required this.startY, required this.speed, required this.sway, required this.size, required this.delay});
}

// ============================================================
// Sparkle Canvas
// ============================================================
class _SparkleCanvas extends StatelessWidget {
  final Animation<double> animation;
  const _SparkleCanvas({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (ctx, _) => CustomPaint(
        painter: _SparklePainter(animation.value),
        size: Size.infinite,
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double t;
  static final _rng = Random(77);

  _SparklePainter(this.t);

  static final _sparkleColors = [
    KouMingTheme.gold,
    KouMingTheme.lantern,
    KouMingTheme.purple,
    Colors.amber.shade200,
    Colors.pink.shade200,
    Colors.white70,
  ];

  static final _sparkles = List.generate(50, (i) {
    return _Sparkle(
      x: _rng.nextDouble(),
      startY: 0.3 + _rng.nextDouble() * 0.7,
      riseSpeed: 0.2 + _rng.nextDouble() * 0.5,
      swayAmp: (_rng.nextDouble() - 0.5) * 0.03,
      size: 0.8 + _rng.nextDouble() * 2.5,
      delay: _rng.nextDouble() * 0.6,
      color: _sparkleColors[_rng.nextInt(_sparkleColors.length)],
    );
  });

  @override
  void paint(Canvas c, Size s) {
    for (final sparkle in _sparkles) {
      if (t < sparkle.delay) continue;
      final lt = ((t - sparkle.delay) / (1.0 - sparkle.delay)).clamp(0.0, 1.0);
      final px = s.width * (sparkle.x + sin(lt * 12 + sparkle.x * 5) * sparkle.swayAmp);
      final py = s.height * (sparkle.startY - lt * sparkle.riseSpeed * 1.2);
      final alpha = (lt < 0.2 ? lt / 0.2 : (lt > 0.8 ? (1 - lt) / 0.2 : 1.0)).clamp(0.0, 0.7);
      final size = sparkle.size * (0.5 + sin(lt * 8) * 0.5);
      c.drawCircle(
        Offset(px, py),
        size,
        Paint()..color = sparkle.color.withValues(alpha: alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => t != old.t;
}

class _Sparkle {
  final double x, startY, riseSpeed, swayAmp, size, delay;
  final Color color;
  _Sparkle({required this.x, required this.startY, required this.riseSpeed, required this.swayAmp, required this.size, required this.delay, required this.color});
}
