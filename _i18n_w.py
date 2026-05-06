import os
BASE = r"C:\Users\85932\.qclaw\workspace\software-factory\projects\kouming\lib"

# ── fortune_reading_dialog.dart ──
f1 = r"""import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/ai_service.dart';
import 'package:kouming/services/i18n_service.dart';

class FortuneReadingDialog extends StatefulWidget {
  final Wish wish;
  final AiService aiService;
  const FortuneReadingDialog({super.key, required this.wish, required this.aiService});
  static Future<void> show(BuildContext context, Wish wish, AiService aiService) {
    return showDialog(context: context, barrierDismissible: false, barrierColor: Colors.black87,
      builder: (ctx) => FortuneReadingDialog(wish: wish, aiService: aiService));
  }
  @override State<FortuneReadingDialog> createState() => _FortuneReadingDialogState();
}

class _FortuneReadingDialogState extends State<FortuneReadingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  Reading? _reading;
  bool _loading = true;

  @override void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _anim.forward();
    _callAi();
  }

  Future<void> _callAi() async {
    try {
      final reading = await widget.aiService.generateReading(widget.wish.text, widget.wish.category);
      if (mounted) setState(() { _reading = reading; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override void dispose() { _anim.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Dialog(backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(16),
      child: FadeTransition(opacity: _fade,
        child: Container(constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(color: KouMingTheme.deep, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: KouMingTheme.gold.withValues(alpha: 0.1), blurRadius: 32, spreadRadius: 2)]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _buildHeader(),
            Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20,0,20,20),
              child: _loading ? _buildLoading() : _buildContent())),
          ]))));
  }

  Widget _buildHeader() {
    return Container(padding: const EdgeInsets.fromLTRB(20,16,12,16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: KouMingTheme.gold.withValues(alpha:0.08)))),
      child: Row(children: [
        const Text('\u{1F3B4}', style: TextStyle(fontSize:20)),
        const SizedBox(width:8),
        Text(I18n.t('reading_title'), style: const TextStyle(fontFamily:'MaShanZheng', fontSize:18, color:KouMingTheme.gold, letterSpacing:2)),
        const Spacer(),
        if (!_loading) IconButton(onPressed: ()=>Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: KouMingTheme.dim, size:18), padding:EdgeInsets.zero, constraints: const BoxConstraints(minWidth:32)),
      ]));
  }

  Widget _buildLoading() {
    return Container(padding: const EdgeInsets.symmetric(vertical:40),
      child: Column(children: [
        SizedBox(width:36, height:36,
          child: CircularProgressIndicator(strokeWidth:2, valueColor: AlwaysStoppedAnimation<Color>(KouMingTheme.gold.withValues(alpha:0.6)))),
        const SizedBox(height:16),
        Text(I18n.t('reading_casting'), textAlign:TextAlign.center,
          style: const TextStyle(fontSize:12, color:KouMingTheme.dim, fontStyle:FontStyle.italic)),
      ]));
  }

  Widget _buildContent() {
    final r = _reading!;
    final cat = WishCategory.values.firstWhere((c)=>c.key==widget.wish.category, orElse:()=>WishCategory.other);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(margin: const EdgeInsets.only(top:16), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: KouMingTheme.surface.withValues(alpha:0.4), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: KouMingTheme.gold.withValues(alpha:0.1))),
        child: Row(children: [
          Text(cat.label, style: const TextStyle(fontSize:10, color:KouMingTheme.dim)),
          const SizedBox(width:8),
          Expanded(child: Text('"'+widget.wish.text+'"', style: const TextStyle(fontSize:12, fontStyle:FontStyle.italic, color:KouMingTheme.text))),
        ])),
      const SizedBox(height:20),
      if (r.hexagram.isNotEmpty) ...[_buildSection(I18n.t('reading_hex_section'), r.hexagram, '\u{1F52E}'), const SizedBox(height:14)],
      if (r.element.isNotEmpty) ...[_buildSection(I18n.t('reading_element_section'), r.element, '\u{2694}'), const SizedBox(height:14)],
      if (r.body.isNotEmpty) ...[_buildSection(I18n.t('reading_interpretation'), r.body, '\u{1F4AD}', isBody:true), const SizedBox(height:14)],
      if (r.advice.isNotEmpty) ...[_buildSection(I18n.t('reading_guidance'), r.advice, '\u{2728}', accent:KouMingTheme.water), const SizedBox(height:14)],
      if (r.similarCount > 0) _buildStats(r),
      const SizedBox(height:20),
      if (_reading != null) _buildPaywallTeaser(),
    ]);
  }

  Widget _buildSection(String title, String content, String emoji, {Color accent=KouMingTheme.gold, bool isBody=false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize:14)),
        const SizedBox(width:6),
        Text(title, style: TextStyle(fontSize:11, fontWeight:FontWeight.w600, color:accent, letterSpacing:1)),
      ]),
      const SizedBox(height:6),
      Padding(padding: const EdgeInsets.only(left:20),
        child: Text(content, style: TextStyle(fontSize: isBody?12:11, height:1.6, color: isBody?KouMingTheme.text:KouMingTheme.dim))),
    ]);
  }

  Widget _buildStats(Reading r) {
    return Container(margin: const EdgeInsets.only(top:4), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: KouMingTheme.purple.withValues(alpha:0.06), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KouMingTheme.purple.withValues(alpha:0.1))),
      child: Row(children: [
        Expanded(child: Column(children: [
          Text('${r.similarCount}', style: const TextStyle(fontSize:18, fontWeight:FontWeight.bold, color:KouMingTheme.purple)),
          Text(I18n.t('reading_similar_wishes'), style: const TextStyle(fontSize:9, color:KouMingTheme.dim))])),
        Container(width:1, height:30, color: KouMingTheme.purple.withValues(alpha:0.15)),
        Expanded(child: Column(children: [
          Text('${r.fulfilledCount}', style: const TextStyle(fontSize:18, fontWeight:FontWeight.bold, color:KouMingTheme.lantern)),
          Text(I18n.t('reading_fulfilled'), style: const TextStyle(fontSize:9, color:KouMingTheme.dim))])),
      ]));
  }

  Widget _buildPaywallTeaser() {
    return Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(gradient: LinearGradient(colors:[KouMingTheme.gold.withValues(alpha:0.08), KouMingTheme.purple.withValues(alpha:0.05)]),
        borderRadius: BorderRadius.circular(12), border: Border.all(color: KouMingTheme.gold.withValues(alpha:0.15))),
      child: Column(children: [
        Text(I18n.t('reading_unlock_title'), style: const TextStyle(fontSize:12, fontWeight:FontWeight.w600, color:KouMingTheme.gold)),
        const SizedBox(height:4),
        Text(I18n.t('reading_unlock_desc'), textAlign:TextAlign.center, style: const TextStyle(fontSize:10, color:KouMingTheme.dim)),
        const SizedBox(height:10),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: ()=>Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(foregroundColor:KouMingTheme.dim,
              side: BorderSide(color:KouMingTheme.dim.withValues(alpha:0.2)),
              shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical:8)),
            child: Text(I18n.t('reading_close'), style: const TextStyle(fontSize:11)))),
          const SizedBox(width:8),
          Expanded(flex:2, child: ElevatedButton(onPressed: (){
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(I18n.t('reading_unlock_snack')), backgroundColor:KouMingTheme.gold));
          }, style: ElevatedButton.styleFrom(backgroundColor:KouMingTheme.gold, foregroundColor:KouMingTheme.deep,
            shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical:8)),
            child: Text(I18n.t('reading_unlock_btn'), style: const TextStyle(fontSize:11)))),
        ]),
      ]));
  }
}
"""

with open(os.path.join(BASE, "features","pool","fortune_reading_dialog.dart"), "w", encoding="utf-8") as f:
    f.write(f1)
print("1. fortune_reading_dialog.dart OK")

# ── unwinding_letter.dart ──
f2 = r"""import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/services/i18n_service.dart';

class UnwindingLetter extends StatelessWidget {
  final String wishText;
  final String category;
  final VoidCallback? onRead;
  const UnwindingLetter({super.key, required this.wishText, required this.category, this.onRead});

  static const Map<String,String> _categoryKeys = {
    'study':'letter_hint_study','health':'letter_hint_health','love':'letter_hint_love','money':'letter_hint_money','default':'letter_hint_default',
  };

  @override Widget build(BuildContext context) {
    final hintKey = _categoryKeys[category] ?? _categoryKeys['default']!;
    final hint = I18n.t(hintKey);
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color:KouMingTheme.surface,
        border: Border.all(color:KouMingTheme.gold.withValues(alpha:0.15)), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('\u{1F4DC}', style:TextStyle(fontSize:20)),
          const SizedBox(width:8),
          Text(I18n.t('letter_title'), style: const TextStyle(fontSize:15, fontWeight:FontWeight.w600, color:KouMingTheme.gold, letterSpacing:3)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:2),
            decoration: BoxDecoration(color:KouMingTheme.gold.withValues(alpha:0.08), borderRadius: BorderRadius.circular(8)),
            child: Text(I18n.t('letter_unlock_in', args:{'days':'7'}), style: const TextStyle(fontSize:10, color:KouMingTheme.gold))),
        ]),
        const SizedBox(height:10),
        Text('\u201C'+wishText+'\u201D', style: const TextStyle(fontSize:13, fontStyle:FontStyle.italic, color:KouMingTheme.text, height:1.8)),
        const SizedBox(height:8),
        Row(children: [
          Text(hint, style: const TextStyle(fontSize:11, color:KouMingTheme.dim)),
          const Spacer(),
          if (onRead != null) TextButton(onPressed:onRead, child: Text(I18n.t('letter_read_now'), style: const TextStyle(fontSize:11))),
        ]),
      ]));
  }
}
"""

with open(os.path.join(BASE, "features","pool","unwinding_letter.dart"), "w", encoding="utf-8") as f:
    f.write(f2)
print("2. unwinding_letter.dart OK")
print("STEP 1 DONE")
