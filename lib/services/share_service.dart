import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/services/i18n_service.dart';

/// ─── Share Service ───
/// Generates share text and shows a share dialog with WeChat / LINE / KakaoTalk options.
/// On web, we can't directly open these apps, so we copy text to clipboard
/// and guide the user to paste in the target app.

class ShareService {
  /// Generate the share card text for a wish
  static String generateShareText(String wishText) {
    return '${I18n.t('pool_share_card_title')}\n'
        '${I18n.t('pool_share_card_wish', args: {'wish': wishText})}\n'
        '${I18n.t('pool_share_card_call')}\n'
        '${I18n.t('pool_share_card_principle')}\n'
        '${I18n.t('pool_share_card_download')}';
  }

  /// Show the share bottom sheet
  static Future<void> showShareSheet(BuildContext context, {required String wishText}) async {
    final shareText = generateShareText(wishText);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShareSheetContent(
        shareText: shareText,
        wishText: wishText,
      ),
    );
  }
}

// ─── Share Sheet UI ───

class _ShareSheetContent extends StatelessWidget {
  final String shareText;
  final String wishText;

  const _ShareSheetContent({
    required this.shareText,
    required this.wishText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KouMingTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: KouMingTheme.dim.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(I18n.t('pool_share_label'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: KouMingTheme.gold,
                fontFamily: 'MaShanZheng',
              )),
          const SizedBox(height: 4),
          Text(I18n.t('pool_share_hint'),
              style: const TextStyle(fontSize: 10, color: KouMingTheme.dim)),
          const SizedBox(height: 16),

          // Preview card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  KouMingTheme.gold.withValues(alpha: 0.08),
                  KouMingTheme.purple.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  I18n.t('pool_share_card_title'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: KouMingTheme.gold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  I18n.t('pool_share_card_wish', args: {'wish': wishText}),
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: KouMingTheme.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  I18n.t('pool_share_card_call'),
                  style: const TextStyle(fontSize: 11, color: KouMingTheme.dim),
                ),
                const SizedBox(height: 4),
                Text(
                  I18n.t('pool_share_card_principle'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: KouMingTheme.purple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Share buttons — wrap for 5 items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 12,
              runSpacing: 12,
              children: [
                _ShareButton(
                  emoji: '💬',
                  label: I18n.t('pool_share_wechat'),
                  color: const Color(0xFF07C160),
                  onTap: () => _copyAndGuide(context, 'WeChat'),
                ),
                _ShareButton(
                  emoji: '📱',
                  label: I18n.t('pool_share_whatsapp'),
                  color: const Color(0xFF25D366),
                  onTap: () => _copyAndGuide(context, 'WhatsApp'),
                ),
                _ShareButton(
                  emoji: '💚',
                  label: I18n.t('pool_share_line'),
                  color: const Color(0xFF06C755),
                  onTap: () => _copyAndGuide(context, 'LINE'),
                ),
                _ShareButton(
                  emoji: '💛',
                  label: I18n.t('pool_share_kakao'),
                  color: const Color(0xFFFAE100),
                  onTap: () => _copyAndGuide(context, 'KakaoTalk'),
                ),
                _ShareButton(
                  emoji: '📋',
                  label: I18n.t('pool_share_copy'),
                  color: KouMingTheme.gold,
                  onTap: () => _copyOnly(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _copyAndGuide(BuildContext context, String platform) {
    Clipboard.setData(ClipboardData(text: shareText));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          I18n.t('pool_share_copied', args: {'platform': platform}),
        ),
        backgroundColor: KouMingTheme.gold,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyOnly(BuildContext context) {
    Clipboard.setData(ClipboardData(text: shareText));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(I18n.t('pool_share_copied_generic')),
        backgroundColor: KouMingTheme.gold,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
