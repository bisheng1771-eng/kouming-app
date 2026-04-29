import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/i18n_service.dart';
import 'package:kouming/services/ai_service.dart';

class FateDrawFlow extends StatefulWidget {
  final VoidCallback onDrawComplete;
  final VoidCallback onPaymentRequired;
  final String? wishText; // 用户当前愿望，用于AI个性化解读
  const FateDrawFlow({super.key, required this.onDrawComplete, required this.onPaymentRequired, this.wishText});
  static Future<void> show(BuildContext context, {required VoidCallback onDrawComplete, required VoidCallback onPaymentRequired, String? wishText}) {
    return showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => FateDrawFlow(onDrawComplete: onDrawComplete, onPaymentRequired: onPaymentRequired, wishText: wishText));
  }
  @override State<FateDrawFlow> createState() => _FateDrawFlowState();
}

class _FateDrawFlowState extends State<FateDrawFlow> with TickerProviderStateMixin {
  late AnimationController _shakeCtrl, _flyCtrl, _flipCtrl;
  _Phase _phase = _Phase.idle;
  FortuneSlip? _result;
  bool _isGenerating = false;
  String? _aiReading;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _flyCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _flyCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _phase = _Phase.reveal);
        _flipCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _flyCtrl.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  FortuneSlip _drawFortune() {
    final rng = Random();
    final roll = rng.nextDouble();
    final level = roll < 0.05
        ? FortuneLevel.supreme
        : roll < 0.25
            ? FortuneLevel.great
            : roll < 0.60
                ? FortuneLevel.medium
                : roll < 0.85
                    ? FortuneLevel.low
                    : FortuneLevel.bad;
    return _fortunePool[level]![rng.nextInt(_fortunePool[level]!.length)];
  }

  void _startDraw() async {
    _result = _drawFortune();
    setState(() => _phase = _Phase.shaking);
    
    // 同时调用AI生成个性化解读
    _generateAIReading();
    
    _shakeCtrl.forward().then((_) {
      setState(() => _phase = _Phase.flying);
      _flyCtrl.forward(from: 0);
    });
  }

  Future<void> _generateAIReading() async {
    setState(() => _isGenerating = true);
    try {
      final aiService = AiService();
      // 使用用户实际愿望内容生成个性化解读
      final wishContent = widget.wishText ?? '天命签祈福';
      final reading = await aiService.generateReading(
        wishContent,
        'default',
      );
      setState(() {
        _aiReading = reading.body;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [KouMingTheme.deep, KouMingTheme.mid],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
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
        const SizedBox(height: 12),
        Text(
          I18n.t('fate_title'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: KouMingTheme.gold, fontFamily: 'MaShanZheng'),
        ),
        const SizedBox(height: 20),
        Expanded(child: _buildContent()),
      ]),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case _Phase.idle:
        return _buildIdle();
      case _Phase.shaking:
        return _buildShaking();
      case _Phase.flying:
        return _buildFlying();
      case _Phase.reveal:
        return _buildReveal();
    }
  }

  Widget _buildIdle() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [KouMingTheme.warm, KouMingTheme.gold]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KouMingTheme.gold, width: 2),
            boxShadow: [BoxShadow(color: KouMingTheme.gold.withValues(alpha: 0.2), blurRadius: 20)],
          ),
          child: const Center(child: Text('竹', style: TextStyle(fontSize: 48, fontFamily: 'MaShanZheng'))),
        ),
        const SizedBox(height: 24),
        Text(I18n.t('fate_shake_hint'), style: const TextStyle(fontSize: 13, color: KouMingTheme.dim)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _startDraw,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [KouMingTheme.gold, KouMingTheme.warm]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: KouMingTheme.gold.withValues(alpha: 0.3), blurRadius: 12)],
            ),
            child: Text(I18n.t('fate_draw_btn'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          ),
        ),
      ]),
    );
  }

  Widget _buildShaking() {
    return Center(
      child: AnimatedBuilder(
        animation: _shakeCtrl,
        builder: (ctx, child) {
          final t = _shakeCtrl.value;
          final angle = sin(t * 8 * pi) * 0.15 * (1 - t);
          final offsetX = sin(t * 12 * pi) * 8 * (1 - t);
          return Transform.translate(
            offset: Offset(offsetX, 0),
            child: Transform.rotate(angle: angle, child: child),
          );
        },
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [KouMingTheme.warm, KouMingTheme.gold]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KouMingTheme.gold, width: 2),
            boxShadow: [BoxShadow(color: KouMingTheme.gold.withValues(alpha: 0.4), blurRadius: 30)],
          ),
          child: const Center(child: Text('竹', style: TextStyle(fontSize: 48, fontFamily: 'MaShanZheng'))),
        ),
      ),
    );
  }

  Widget _buildFlying() {
    return AnimatedBuilder(
      animation: _flyCtrl,
      builder: (ctx, _) {
        final t = _flyCtrl.value;
        final y = 80 - Curves.easeOut.transform(t) * 160;
        final scale = 0.6 + Curves.easeOut.transform(t) * 0.4;
        final opacity = 0.5 + t * 0.5;
        return Center(
          child: Transform.translate(
            offset: Offset(0, y),
            child: Transform.scale(
              scale: scale,
              child: Opacity(opacity: opacity, child: _buildStickCard(back: true)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStickCard({required bool back}) {
    final stickColor = back ? const Color(0xFF8B0000) : _levelColor(_result!.level);
    return Container(
      width: 80,
      height: 180,
      decoration: BoxDecoration(
        gradient: back
            ? const LinearGradient(colors: [Color(0xFF8B0000), Color(0xFFB22222)])
            : LinearGradient(colors: [_levelColor(_result!.level).withValues(alpha: 0.3), KouMingTheme.surface]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: back ? KouMingTheme.lantern : _levelColor(_result!.level), width: 2),
        boxShadow: [BoxShadow(color: stickColor.withValues(alpha: 0.4), blurRadius: 20)],
      ),
      child: back
          ? const Center(child: Text('签', style: TextStyle(fontSize: 36, color: KouMingTheme.gold, fontFamily: 'MaShanZheng')))
          : _buildFortuneContent(),
    );
  }

  Widget _buildFortuneContent() {
    if (_result == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_result!.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(_result!.title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _levelColor(_result!.level), fontFamily: 'MaShanZheng'),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(_levelLabel(_result!.level), style: TextStyle(fontSize: 11, color: _levelColor(_result!.level))),
      ]),
    );
  }

  Widget _buildReveal() {
    if (_result == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _flipCtrl,
      builder: (ctx, _) {
        final t = _flipCtrl.value;
        final angle = t < 0.5 ? t * pi : (t - 1) * pi;
        final showFront = t >= 0.5;
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
              child: showFront ? _buildFullResultCard() : _buildStickCard(back: true),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildFullResultCard() {
    final color = _levelColor(_result!.level);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), KouMingTheme.surface]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 24)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(_levelLabel(_result!.level), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 16),
        Text(_result!.emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(_result!.title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, fontFamily: 'MaShanZheng')),
        const SizedBox(height: 8),
        Text(_result!.description,
            style: const TextStyle(fontSize: 12, color: KouMingTheme.text, height: 1.6), textAlign: TextAlign.center),
        if (_aiReading != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KouMingTheme.gold.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Text('心灵指引',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, fontFamily: 'MaShanZheng')),
                const SizedBox(height: 6),
                Text(_aiReading!,
                    style: const TextStyle(fontSize: 11, color: KouMingTheme.text, height: 1.5), textAlign: TextAlign.center),
              ],
            ),
          ),
        ] else if (_isGenerating) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(width: 8),
              Text('获取心灵指引中...', style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('元素: ', style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
          Text(_result!.element, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
          const SizedBox(width: 16),
          Text('守护: ', style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
          Text(_result!.guardian, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
        ]),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            widget.onDrawComplete();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(I18n.t('fate_accept'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KouMingTheme.deep)),
          ),
        ),
      ]),
    );
  }

  static Color _levelColor(FortuneLevel level) {
    switch (level) {
      case FortuneLevel.supreme:
        return KouMingTheme.gold;
      case FortuneLevel.great:
        return KouMingTheme.lantern;
      case FortuneLevel.medium:
        return KouMingTheme.purple;
      case FortuneLevel.low:
        return KouMingTheme.water;
      case FortuneLevel.bad:
        return const Color(0xFF666688);
    }
  }

  String _levelLabel(FortuneLevel level) {
    switch (level) {
      case FortuneLevel.supreme:
        return I18n.t('fortune_supreme');
      case FortuneLevel.great:
        return I18n.t('fortune_great');
      case FortuneLevel.medium:
        return I18n.t('fortune_medium');
      case FortuneLevel.low:
        return I18n.t('fortune_low');
      case FortuneLevel.bad:
        return I18n.t('fortune_bad');
    }
  }

  static const Map<FortuneLevel, List<FortuneSlip>> _fortunePool = {
    FortuneLevel.supreme: [
      FortuneSlip(title: '星光璀璨', description: '前路光明，心想事成。此刻正是最好的时机，勇敢前行。', emoji: '✨', level: FortuneLevel.supreme, element: '光明', guardian: '星辰'),
      FortuneSlip(title: '春风得意', description: '一切顺遂，好运相伴。保持这份积极的心态，继续向前。', emoji: '🌟', level: FortuneLevel.supreme, element: '温暖', guardian: '春风'),
    ],
    FortuneLevel.great: [
      FortuneSlip(title: '柳暗花明', description: '低谷已过，曙光初现。坚持本心，转机就在眼前。', emoji: '🌸', level: FortuneLevel.great, element: '生机', guardian: '绿芽'),
      FortuneSlip(title: '贵人相助', description: '有人愿意伸出援手，保持开放心态，接纳这份善意。', emoji: '🤝', level: FortuneLevel.great, element: '友善', guardian: '桥梁'),
      FortuneSlip(title: '锦上添花', description: '好事连连，正逢顺水推舟之时，把握机会。', emoji: '🎊', level: FortuneLevel.great, element: '喜悦', guardian: '彩虹'),
    ],
    FortuneLevel.medium: [
      FortuneSlip(title: '守中持平', description: '不急不躁，稳中求进。此时宜守不宜攻，静待花开。', emoji: '⚖️', level: FortuneLevel.medium, element: '平衡', guardian: '天平'),
      FortuneSlip(title: '循序渐进', description: '水到渠成，不必急于一时。一步一个脚印，终有所成。', emoji: '📈', level: FortuneLevel.medium, element: '成长', guardian: '阶梯'),
      FortuneSlip(title: '以静制动', description: '外界纷扰，内心安定则无碍。沉稳面对，自见分明。', emoji: '🧘', level: FortuneLevel.medium, element: '宁静', guardian: '灯塔'),
    ],
    FortuneLevel.low: [
      FortuneSlip(title: '云开雾散', description: '前路暂有迷雾，莫急躁。稍作休整，阳光终将穿透。', emoji: '🌤️', level: FortuneLevel.low, element: '耐心', guardian: '晨曦'),
      FortuneSlip(title: '事需缓图', description: '时机未到，强求反累。先退一步，再谋后动。', emoji: '🐢', level: FortuneLevel.low, element: '沉稳', guardian: '磐石'),
      FortuneSlip(title: '静待花开', description: '好事尚需时日，耐心浇灌，静候花开。', emoji: '🌱', level: FortuneLevel.low, element: '希望', guardian: '种子'),
    ],
    FortuneLevel.bad: [
      FortuneSlip(title: '柳暗花明', description: '前方有挑战，但也是成长的契机。谨慎前行，必有收获。', emoji: '💪', level: FortuneLevel.bad, element: '坚韧', guardian: '山峰'),
      FortuneSlip(title: '山重水复', description: '看似无路，实则转机将至。咬牙坚持，方见光明。', emoji: '🏔️', level: FortuneLevel.bad, element: '毅力', guardian: '溪流'),
      FortuneSlip(title: '黎明之前', description: '最黑暗的时刻往往预示着黎明。保持信念，光就在前方。', emoji: '🌅', level: FortuneLevel.bad, element: '信念', guardian: '曙光'),
    ],
  };
}

enum _Phase { idle, shaking, flying, reveal }
