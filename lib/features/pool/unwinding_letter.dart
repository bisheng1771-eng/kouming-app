import 'package:flutter/material.dart';
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
        Text('\u201C$wishText\u201D', style: const TextStyle(fontSize:13, fontStyle:FontStyle.italic, color:KouMingTheme.text, height:1.8)),
        const SizedBox(height:8),
        Row(children: [
          Text(hint, style: const TextStyle(fontSize:11, color:KouMingTheme.dim)),
          const Spacer(),
          if (onRead != null) TextButton(onPressed:onRead, child: Text(I18n.t('letter_read_now'), style: const TextStyle(fontSize:11))),
        ]),
      ]));
  }
}
