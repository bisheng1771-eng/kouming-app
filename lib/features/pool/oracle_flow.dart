import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/ai_service.dart';
import 'package:kouming/services/i18n_service.dart';
import 'package:kouming/services/share_service.dart';
import 'package:kouming/services/alipay_service.dart';
import 'package:kouming/services/supabase_service.dart';

/// ─── Pool Spirit Oracle — Full Conversation Flow ───
///
/// Flow:
/// 1. Spirit appears after a wish is cast (or user taps Oracle)
/// 2. Spirit asks: "Want me to divine where this path leads?"
/// 3. User agrees → Spirit casts (loading animation with mist)
/// 4. Free first time: full reading shown with hexagram flip animation
/// 5. Paid subsequent: teaser shown → unlock button
/// 6. Full reading: hexagram + element + body + advice + stats

class OracleFlow {
  static Future<void> show(
    BuildContext context, {
    required Wish wish,
    required AiService aiService,
    required int freeOracleUsed,
    required int freeOracleCount,
    required void Function() onFreeOracleUsed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      builder: (ctx) => _OracleSheet(
        wish: wish,
        aiService: aiService,
        freeOracleUsed: freeOracleUsed,
        freeOracleCount: freeOracleCount,
        onFreeOracleUsed: onFreeOracleUsed,
      ),
    );
  }
}

class _OracleSheet extends StatefulWidget {
  final Wish wish;
  final AiService aiService;
  final int freeOracleUsed;
  final int freeOracleCount;
  final void Function() onFreeOracleUsed;

  const _OracleSheet({
    required this.wish,
    required this.aiService,
    required this.freeOracleUsed,
    required this.freeOracleCount,
    required this.onFreeOracleUsed,
  });

  @override
  State<_OracleSheet> createState() => _OracleSheetState();
}

enum _Phase { greet, casting, result, error }

class _OracleSheetState extends State<_OracleSheet>
    with TickerProviderStateMixin {
  _Phase _phase = _Phase.greet;
  late AnimationController _mistCtrl;
  late AnimationController _hexFlipCtrl;
  Reading? _reading;
  String? _errorMessage;
  bool get _hasFreeOracle => widget.freeOracleUsed < widget.freeOracleCount;

  @override
  void initState() {
    super.initState();
    _mistCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _hexFlipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _mistCtrl.dispose();
    _hexFlipCtrl.dispose();
    super.dispose();
  }

  Future<void> _startDivination() async {
    // 检查免费次数
    if (!_hasFreeOracle) {
      _showLimitReachedDialog('今日免费算卦次数已用完', '明天再来吧，或者付费使用');
      return;
    }
    
    setState(() => _phase = _Phase.casting);
    _mistCtrl.repeat(reverse: true);

    try {
      final reading = await widget.aiService.generateReading(
        widget.wish.text,
        widget.wish.category,
      );
      if (!mounted) return;
      _mistCtrl.stop();
      _hexFlipCtrl.forward(from: 0);
      setState(() {
        _reading = reading;
        _phase = _Phase.result;
      });
      if (_hasFreeOracle) {
        widget.onFreeOracleUsed();
      }
    } catch (e) {
      if (!mounted) return;
      _mistCtrl.stop();
      setState(() {
        _errorMessage = I18n.t('spirit_error_msg');
        _phase = _Phase.error;
      });
    }
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
            child: const Text('知道了', style: TextStyle(color: KouMingTheme.dim)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _payForOracle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KouMingTheme.gold,
              foregroundColor: KouMingTheme.deep,
            ),
            child: const Text('去付费 ¥6', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _payForOracle() async {
    setState(() => _phase = _Phase.casting);
    _mistCtrl.repeat(reverse: true);

    try {
      // 获取用户ID（确保已登录）
      final supabase = SupabaseService();
      await supabase.ensureLogin();
      final userId = supabase.userId ?? 'anonymous';

      // 调用支付宝支付
      final result = await AlipayService.pay(
        product: 'oracle',
        userId: userId,
      );

      if (result == 'success') {
        // 支付成功，进行算卦
        final reading = await widget.aiService.generateReading(
          widget.wish.text,
          widget.wish.category,
        );
        if (!mounted) return;
        _mistCtrl.stop();
        _hexFlipCtrl.forward(from: 0);
        setState(() {
          _reading = reading;
          _phase = _Phase.result;
        });
      } else if (result == 'canceled') {
        if (!mounted) return;
        _mistCtrl.stop();
        setState(() => _phase = _Phase.greet);
      } else {
        if (!mounted) return;
        _mistCtrl.stop();
        setState(() {
          _errorMessage = '支付失败，请重试';
          _phase = _Phase.error;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _mistCtrl.stop();
      setState(() {
        _errorMessage = I18n.t('spirit_error_msg');
        _phase = _Phase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final height = mq.size.height * 0.85;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1628), KouMingTheme.deep],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: KouMingTheme.gold.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KouMingTheme.dim.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _buildPhase(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _Phase.greet:
        return _buildGreet();
      case _Phase.casting:
        return _buildCasting();
      case _Phase.result:
        return _buildResult();
      case _Phase.error:
        return _buildError();
    }
  }

  Widget _buildGreet() {
    final cat = WishCategory.values.firstWhere(
      (c) => c.key == widget.wish.category,
      orElse: () => WishCategory.other,
    );

    return Padding(
      key: const ValueKey('greet'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _SpiritAvatar(pulse: true),
          const SizedBox(height: 24),
          _SpiritBubble(
            messages: [
              I18n.t('spirit_saw'),
              _hasFreeOracle
                  ? I18n.t('spirit_first_free')
                  : I18n.t('spirit_pay_hint'),
              '"${widget.wish.text}"',
              I18n.t('spirit_ask_reading'),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: KouMingTheme.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: KouMingTheme.purple.withValues(alpha: 0.15)),
            ),
            child: Text(
              cat.label,
              style: const TextStyle(fontSize: 10, color: KouMingTheme.purple),
            ),
          ),
          const Spacer(),
          // Principle card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KouMingTheme.purple.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: KouMingTheme.purple.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Text('\u{1F4A1}', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(I18n.t('principle_body'),
                      style: const TextStyle(
                        fontSize: 9,
                        color: KouMingTheme.dim,
                        height: 1.3,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Compliance notice
          Text(
            I18n.t('disclaimer_virtual_notice'),
            style: TextStyle(
              fontSize: 8,
              color: KouMingTheme.dim.withValues(alpha: 0.6),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KouMingTheme.dim,
                    side: BorderSide(color: KouMingTheme.dim.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(I18n.t('spirit_skip'), style: const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _startDivination,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KouMingTheme.gold,
                    foregroundColor: KouMingTheme.deep,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('\u{1F52E}', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        _hasFreeOracle
                            ? I18n.t('spirit_do_reading')
                            : '${I18n.t('spirit_do_reading')} (\u00A56)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCasting() {
    return Padding(
      key: const ValueKey('casting'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: AnimatedBuilder(
              animation: _mistCtrl,
              builder: (_, __) {
                final t = _mistCtrl.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140 + sin(t * pi * 2) * 30,
                      height: 140 + sin(t * pi * 2) * 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            KouMingTheme.purple.withValues(alpha: 0.15 * (1 - t * 0.3)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 80 + cos(t * pi * 2) * 15,
                      height: 80 + cos(t * pi * 2) * 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            KouMingTheme.gold.withValues(alpha: 0.3 + t * 0.1),
                            KouMingTheme.spirit.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const Text('\u262F', style: TextStyle(fontSize: 40, color: KouMingTheme.gold)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          _FloatingSymbols(),
          const SizedBox(height: 24),
          Text(
            I18n.t('spirit_looking'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: KouMingTheme.dim,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_reading == null) return const SizedBox.shrink();
    final r = _reading!;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SpiritAvatar(pulse: false, size: 32),
              const SizedBox(width: 10),
              Text(
                I18n.t('spirit_unlocked'),
                style: const TextStyle(
                  fontFamily: 'MaShanZheng',
                  fontSize: 18,
                  color: KouMingTheme.gold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: KouMingTheme.dim, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Hexagram Card (flip animation)
          AnimatedBuilder(
            animation: _hexFlipCtrl,
            builder: (_, __) {
              final t = _hexFlipCtrl.value;
              final showFront = t < 0.5;
              final scaleX = showFront ? 1 - t * 2 : (t - 0.5) * 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(max(scaleX, 0.01), 1.0),
                child: Opacity(
                  opacity: showFront ? 1 - t * 1.5 : (t - 0.5) * 2,
                  child: showFront
                      ? _HexCardBack(r: r)
                      : _HexCardFront(r: r),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Wish echo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KouMingTheme.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Text('\u{1F4AD}', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"${widget.wish.text}"',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: KouMingTheme.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (r.interpretation.isNotEmpty) ...[
            _buildSection('🔮 ${I18n.t('reading_interpretation')}', r.interpretation, KouMingTheme.text, isBody: true),
            const SizedBox(height: 14),
          ],
          if (r.advice1.isNotEmpty) ...[
            _buildSection('💡 ${I18n.t('reading_advice_1')}', r.advice1, KouMingTheme.water),
            const SizedBox(height: 14),
          ],

          _buildStats(r),
          const SizedBox(height: 20),

          // Signature
          Center(
            child: Text(
              I18n.t('reading_signature'),
              style: const TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: KouMingTheme.dim,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Share + Accept row
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => ShareService.showShareSheet(context, wishText: widget.wish.text),
                icon: const Text('\u{1F4E4}', style: TextStyle(fontSize: 12)),
                label: Text(I18n.t('pool_share_label'), style: const TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KouMingTheme.gold,
                  side: BorderSide(color: KouMingTheme.gold.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KouMingTheme.gold,
                    foregroundColor: KouMingTheme.deep,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(I18n.t('spirit_unlocked').replaceAll(' \u{1F52E}', ''),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      key: const ValueKey('error'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SpiritAvatar(pulse: false),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KouMingTheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KouMingTheme.dim.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                const Text('\u{1F32B}', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 12),
                Text(
                  I18n.t('spirit_error_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KouMingTheme.dim,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage ?? I18n.t('spirit_error_msg'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: KouMingTheme.dim,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KouMingTheme.dim,
                    side: BorderSide(color: KouMingTheme.dim.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(I18n.t('spirit_think'), style: const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _phase = _Phase.greet;
                      _errorMessage = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KouMingTheme.gold,
                    foregroundColor: KouMingTheme.deep,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text('\u{1F504} ${I18n.t('spirit_retry')}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, Color accent,
      {bool isBody = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
              letterSpacing: 1,
            )),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            content,
            style: TextStyle(
              fontSize: isBody ? 12 : 11,
              height: 1.6,
              color: isBody ? KouMingTheme.text : KouMingTheme.dim,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(Reading r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KouMingTheme.purple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KouMingTheme.purple.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('${r.similarCount}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: KouMingTheme.purple)),
                    const SizedBox(height: 2),
                    Text(I18n.t('reading_similar', args: {
                      'same': '${r.similarCount}',
                      'done': '${r.fulfilledCount}',
                    }),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9, color: KouMingTheme.dim)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Spirit Avatar ──────────────────────────────────────────

class _SpiritAvatar extends StatefulWidget {
  final bool pulse;
  final double size;
  const _SpiritAvatar({required this.pulse, this.size = 56});

  @override
  State<_SpiritAvatar> createState() => _SpiritAvatarState();
}

class _SpiritAvatarState extends State<_SpiritAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) return _buildAvatar(1.0);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => _buildAvatar(1.0 + _ctrl.value * 0.06),
    );
  }

  Widget _buildAvatar(double scale) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              KouMingTheme.spirit.withValues(alpha: 0.4),
              KouMingTheme.purple.withValues(alpha: 0.2),
              Colors.transparent,
            ],
            center: Alignment.center,
          ),
          border: Border.all(
            color: KouMingTheme.spirit.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: const Center(child: Text('\u{1F441}', style: TextStyle(fontSize: 24))),
      ),
    );
  }
}

// ─── Spirit Speech Bubble ───────────────────────────────────

class _SpiritBubble extends StatelessWidget {
  final List<String> messages;
  const _SpiritBubble({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KouMingTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KouMingTheme.spirit.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: messages.map((m) {
          final isQuote = m.startsWith('"') && m.endsWith('"');
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              m,
              style: TextStyle(
                fontSize: isQuote ? 13 : 12,
                fontStyle: isQuote ? FontStyle.italic : FontStyle.normal,
                color: isQuote ? KouMingTheme.gold : KouMingTheme.text,
                height: 1.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Hexagram Card Back ─────────────────────────────────────

class _HexCardBack extends StatelessWidget {
  final Reading r;
  const _HexCardBack({required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A0A2E), Color(0xFF0D1B2A)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KouMingTheme.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('\u262F', style: TextStyle(fontSize: 48, color: KouMingTheme.purple)),
          const SizedBox(height: 12),
          Text(I18n.t('spirit_looking'),
              style: const TextStyle(fontSize: 14, color: KouMingTheme.dim, letterSpacing: 4)),
        ],
      ),
    );
  }
}

// ─── Hexagram Card Front ────────────────────────────────────

class _HexCardFront extends StatelessWidget {
  final Reading r;
  const _HexCardFront({required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [KouMingTheme.mid, KouMingTheme.deep]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: KouMingTheme.gold.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          _TrigramLines(hexagram: r.hexagram),
          const SizedBox(height: 16),
          Text(
            r.hexagram,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'MaShanZheng',
              fontSize: 22,
              color: KouMingTheme.gold,
              letterSpacing: 3,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trigram Lines ──────────────────────────────────────────

class _TrigramLines extends StatelessWidget {
  final String hexagram;
  const _TrigramLines({required this.hexagram});

  /// 64卦的爻象定义：true=阳爻(—)，false=阴爻(- -)
  static const _hexagramLines = {
    '乾卦': [true, true, true, true, true, true],
    '坤卦': [false, false, false, false, false, false],
    '屯卦': [false, false, true, false, true, false],
    '蒙卦': [true, false, false, false, false, true],
    '需卦': [true, true, true, true, false, false],
    '讼卦': [false, false, true, true, true, true],
    '师卦': [false, false, false, true, false, false],
    '比卦': [false, false, true, false, false, false],
    '小畜卦': [true, true, true, false, true, false],
    '履卦': [false, true, true, true, true, true],
    '泰卦': [true, true, true, false, false, false],
    '否卦': [false, false, false, true, true, true],
    '同人卦': [false, true, false, true, true, true],
    '大有卦': [true, true, true, false, true, false],
    '谦卦': [true, false, false, false, false, false],
    '豫卦': [false, false, false, false, true, false],
    '随卦': [false, true, false, false, true, true],
    '蛊卦': [false, true, false, true, false, false],
    '临卦': [false, true, true, false, false, false],
    '观卦': [false, false, false, false, true, false],
    '噬嗑卦': [false, true, false, false, true, false],
    '贲卦': [false, true, false, true, false, false],
    '剥卦': [false, false, false, true, false, false],
    '复卦': [false, true, false, false, false, false],
    '无妄卦': [false, true, false, true, true, true],
    '大畜卦': [true, true, true, true, false, false],
    '颐卦': [false, true, false, true, false, false],
    '大过卦': [false, true, false, false, true, true],
    '坎卦': [false, true, false, false, true, false],
    '离卦': [true, false, true, true, false, true],
    '咸卦': [true, false, false, false, true, true],
    '恒卦': [false, true, false, false, true, false],
    '遁卦': [true, false, false, true, true, true],
    '大壮卦': [true, true, true, false, true, false],
    '晋卦': [false, false, false, false, true, false],
    '明夷卦': [false, true, false, false, false, false],
    '家人卦': [false, true, false, false, true, false],
    '睽卦': [false, true, true, false, true, false],
    '蹇卦': [true, false, false, true, false, false],
    '解卦': [false, false, true, false, true, false],
    '损卦': [false, true, true, true, false, false],
    '益卦': [false, false, true, false, true, false],
    '夬卦': [true, true, true, false, true, true],
    '姤卦': [false, true, false, true, true, true],
    '萃卦': [false, false, false, false, true, true],
    '升卦': [false, true, false, false, false, false],
    '困卦': [false, true, true, true, false, false],
    '井卦': [false, false, true, false, true, false],
    '革卦': [false, true, false, false, true, true],
    '鼎卦': [false, true, true, false, true, false],
    '震卦': [false, false, true, false, false, true],
    '艮卦': [true, false, false, true, false, false],
    '渐卦': [true, false, false, false, true, false],
    '归妹卦': [false, true, false, false, true, true],
    '丰卦': [false, true, false, false, true, false],
    '旅卦': [false, true, false, true, false, false],
    '巽卦': [false, true, false, true, false, true],
    '兑卦': [false, true, true, false, true, true],
    '涣卦': [false, false, true, false, true, false],
    '节卦': [false, true, true, true, false, false],
    '中孚卦': [false, true, false, false, true, true],
    '小过卦': [false, true, false, true, false, false],
    '既济卦': [false, true, false, true, false, false],
    '未济卦': [false, false, true, false, true, false],
  };

  List<bool> _getLines() {
    // 从卦象名称提取卦名（去掉符号）
    final name = hexagram.split(' ').first;
    return _hexagramLines[name] ?? [true, true, true, true, true, true];
  }

  @override
  Widget build(BuildContext context) {
    final lines = _getLines();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: lines.reversed.map((isYang) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: isYang ? _yangLine() : _yinLine(),
        );
      }).toList(),
    );
  }

  Widget _yangLine() {
    return Container(
      width: 120,
      height: 5,
      decoration: BoxDecoration(
        color: KouMingTheme.gold.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _yinLine() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 52, height: 5,
            decoration: BoxDecoration(color: KouMingTheme.gold.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 16),
        Container(width: 52, height: 5,
            decoration: BoxDecoration(color: KouMingTheme.gold.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(2))),
      ],
    );
  }
}

// ─── Floating Symbols ───────────────────────────────────────

class _FloatingSymbols extends StatefulWidget {
  @override
  State<_FloatingSymbols> createState() => _FloatingSymbolsState();
}

class _FloatingSymbolsState extends State<_FloatingSymbols>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  static const _symbols = ['\u2630', '\u2631', '\u2632', '\u2633', '\u2634', '\u2635', '\u2636', '\u2637'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_symbols.length, (i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = _ctrl.value;
              final offset = sin(t * pi * 2 + i * 0.8) * 12;
              final opacity = 0.3 + 0.4 * sin(t * pi * 2 + i * 1.2);
              return Transform.translate(
                offset: Offset(0, offset),
                child: Opacity(
                  opacity: opacity.clamp(0.1, 0.7),
                  child: Text(_symbols[i], style: const TextStyle(fontSize: 18, color: KouMingTheme.gold)),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
