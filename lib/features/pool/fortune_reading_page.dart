import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';

/// 六爻卦象数据
class Hexagram {
  final String name;      // 卦名，如"乾"
  final String gua;        // 卦辞
  final String commentary; // 象曰
  final String lines;      // 六爻

  const Hexagram({
    required this.name,
    required this.gua,
    required this.commentary,
    required this.lines,
  });
}

/// 64 卦象库（精简演示版）
const _hexagrams = [
  Hexagram(name: '乾', gua: '元亨利贞', commentary: '天行健，君子以自强不息', lines: '111111'),
  Hexagram(name: '坤', gua: '元亨，利牝马之贞', commentary: '地势坤，君子以厚德载物', lines: '000000'),
  Hexagram(name: '屯', gua: '元亨利贞，勿用有攸往', commentary: '云雷屯，君子以经纶', lines: '010001'),
  Hexagram(name: '蒙', gua: '亨，匪我求童蒙，童蒙求我', commentary: '山水蒙，君子以果行育德', lines: '100010'),
  Hexagram(name: '需', gua: '有孚，光亨，贞吉', commentary: '云上于天，需，君子以饮食宴乐', lines: '010111'),
  Hexagram(name: '讼', gua: '有孚窒，惕，中吉', commentary: '天与水违行，讼，君子以作事谋始', lines: '111010'),
  Hexagram(name: '师', gua: '贞，丈人吉，无咎', commentary: '地中有水，师，君子以容民畜众', lines: '000010'),
  Hexagram(name: '比', gua: '吉，原筮，元永贞', commentary: '地上有水，比，君子以建万国亲诸侯', lines: '010000'),
  Hexagram(name: '小畜', gua: '亨，密云不雨，自我西郊', commentary: '风行天上，小畜，君子以懿文德', lines: '111011'),
  Hexagram(name: '履', gua: '亨，履虎尾，不咥人', commentary: '上天下泽，履，君子以辨上下定民志', lines: '011111'),
  Hexagram(name: '泰', gua: '小往大来，吉亨', commentary: '天地交，泰，后以财成天地之道', lines: '011000'),
  Hexagram(name: '否', gua: '否之匪人，不利君子贞', commentary: '天地不交，否，君子以俭德辟难', lines: '000011'),
  Hexagram(name: '同人', gua: '同人于野，亨，利涉大川', commentary: '天与火，同人，君子以类族辨物', lines: '101111'),
  Hexagram(name: '大有', gua: '元亨', commentary: '火在天上，大有，君子以遏恶扬善', lines: '111101'),
  Hexagram(name: '谦', gua: '亨，君子有终', commentary: '地中有山，谦，君子以裒多益寡', lines: '000100'),
  Hexagram(name: '豫', gua: '利建侯行师', commentary: '雷出地奋，豫，先王以作乐崇德', lines: '001000'),
  Hexagram(name: '随', gua: '元亨利贞，无咎', commentary: '泽中有雷，随，君子以向晦入宴息', lines: '001011'),
  Hexagram(name: '蛊', gua: '元亨，利涉大川', commentary: '山下有风，蛊，君子以振民育德', lines: '110100'),
  Hexagram(name: '临', gua: '元亨利贞，至于八月有凶', commentary: '泽上有地，临，君子以教思无穷', lines: '010000'),
  Hexagram(name: '观', gua: '盥而不荐，有孚颙若', commentary: '风行地上，观，先王以省方观民设教', lines: '000101'),
];

/// 算卦页面
class FortuneReadingPage extends StatefulWidget {
  final String wishText;
  final String category;
  final bool isFree;
  final VoidCallback? onPaid;

  const FortuneReadingPage({
    super.key,
    required this.wishText,
    required this.category,
    this.isFree = false,
    this.onPaid,
  });

  @override
  State<FortuneReadingPage> createState() => _FortuneReadingPageState();
}

class _FortuneReadingPageState extends State<FortuneReadingPage> {
  bool _throwing = false;
  bool _resultShown = false;
  Hexagram? _hexagram;

  void _throwCoins() {
    if (_throwing) return;
    setState(() {
      _throwing = true;
      _resultShown = false;
    });

    // 随机选一卦
    final rng = Random();
    final hex = _hexagrams[rng.nextInt(_hexagrams.length)];

    // 动画效果
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _hexagram = hex;
        _resultShown = true;
        _throwing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔮 叩问命运'),
        centerTitle: true,
        leading: IconButton(
          icon: const Text('←'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 愿望提示
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x0A80DEEA),
                border: Border.all(color: KouMingTheme.spirit.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text(
                    '你叩问的是：',
                    style: TextStyle(fontSize: 11, color: KouMingTheme.dim),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '「${widget.wishText}」',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: KouMingTheme.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 卦象显示区
            if (_resultShown && _hexagram != null)
              _HexagramResult(hexagram: _hexagram!)
            else if (_throwing)
              _ThrowingAnimation()
            else
              _IdleState(isFree: widget.isFree),

            const SizedBox(height: 24),

            // 解读按钮
            if (_resultShown && _hexagram != null && !widget.isFree)
              ElevatedButton(
                onPressed: widget.onPaid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KouMingTheme.gold,
                  foregroundColor: const Color(0xFF1A1A2E),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                child: const Text('查看完整解读 ¥6 🔮'),
              )
            else if (_resultShown && _hexagram != null && widget.isFree)
              _FreeTeaser(hexagram: _hexagram!),

            if (!_throwing && !_resultShown)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton(
                  onPressed: _throwCoins,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KouMingTheme.gold,
                    side: const BorderSide(color: Color(0x33FFD700)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('🪙 摇钱起卦'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 闲置状态
class _IdleState extends StatelessWidget {
  final bool isFree;
  const _IdleState({required this.isFree});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('🪙', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Text(
          isFree ? '免费起一卦' : '投入 6 元，让命运开口说话',
          style: const TextStyle(fontSize: 13, color: KouMingTheme.dim),
        ),
      ],
    );
  }
}

/// 摇卦动画
class _ThrowingAnimation extends StatefulWidget {
  @override
  State<_ThrowingAnimation> createState() => _ThrowingAnimationState();
}

class _ThrowingAnimationState extends State<_ThrowingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, 8 * sin(_ctrl.value * 2 * pi)),
            child: const Text('🪙', style: TextStyle(fontSize: 64)),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '钱币在命运中旋转...',
          style: TextStyle(fontSize: 13, color: KouMingTheme.dim),
        ),
      ],
    );
  }
}

/// 卦象结果
class _HexagramResult extends StatelessWidget {
  final Hexagram hexagram;
  const _HexagramResult({required this.hexagram});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KouMingTheme.gold.withValues(alpha: 0.06),
            KouMingTheme.purple.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // 卦名
          Text(
            hexagram.name,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: KouMingTheme.gold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '第${hexagram.lines}卦',
            style: const TextStyle(fontSize: 11, color: KouMingTheme.dim, letterSpacing: 4),
          ),
          const SizedBox(height: 16),
          // 卦画
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: hexagram.lines.split('').map((l) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 6,
                      decoration: BoxDecoration(
                        color: l == '1' ? KouMingTheme.gold : Colors.transparent,
                        border: Border.all(color: KouMingTheme.gold, width: 1.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: l == '0'
                          ? const SizedBox()
                          : Container(height: 2, margin: const EdgeInsets.only(top: 2)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // 卦辞
          const Text(
            '卦辞',
            style: TextStyle(fontSize: 11, color: KouMingTheme.dim, letterSpacing: 2),
          ),
          const SizedBox(height: 6),
          Text(
            hexagram.gua,
            style: const TextStyle(fontSize: 14, height: 1.8, color: KouMingTheme.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // 象曰
          const Text(
            '象曰',
            style: TextStyle(fontSize: 11, color: KouMingTheme.dim, letterSpacing: 2),
          ),
          const SizedBox(height: 6),
          Text(
            hexagram.commentary,
            style: const TextStyle(
              fontSize: 12,
              height: 1.8,
              color: KouMingTheme.purple,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 免费版只显示一行解读
class _FreeTeaser extends StatelessWidget {
  final Hexagram hexagram;
  const _FreeTeaser({required this.hexagram});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x1AFFD700),
            border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '💡 ${hexagram.name}卦告诉你：${hexagram.commentary.substring(0, hexagram.commentary.length > 20 ? 20 : hexagram.commentary.length)}...',
            style: const TextStyle(fontSize: 12, color: KouMingTheme.gold),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '解锁完整解读（含变爻、逐爻分析、相关愿望案例）',
          style: TextStyle(fontSize: 11, color: KouMingTheme.dim),
        ),
      ],
    );
  }
}