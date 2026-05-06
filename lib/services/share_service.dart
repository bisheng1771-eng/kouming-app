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

  /// Generate language-specific share text
  static String generateLocalizedShareText(String wishText, String platform) {
    const downloadLink = 'https://kouming.app/download';
    switch (platform) {
      case 'WeChat':
        return '我在叩命许了一个愿望\n'
            '「$wishText」\n'
            '来为我祝福吧！也来许下你自己的愿望——\n'
            '当更多人一起想，愿望就更有可能实现。\n'
            '下载叩命APP，一起许愿 → $downloadLink';
      case 'WhatsApp':
        return 'I made a wish on KouMing\n'
            '「$wishText」\n'
            'Come bless my wish! Make your own wish too —\n'
            'When more people think together, wishes come true.\n'
            'Download KouMing APP → $downloadLink';
      case 'LINE':
        return 'KouMingで願い事をしました\n'
            '「$wishText」\n'
            '祝福してください！あなたも願い事を——\n'
            'みんなで想えば、願いは叶う。\n'
            'KouMingアプリをダウンロード → $downloadLink';
      case 'KakaoTalk':
        return 'KouMing에서 소원을 빌었어요\n'
            '「$wishText」\n'
            '축복해주세요! 당신도 소원을 빌어보세요——\n'
            '함께 생각하면 소원은 이루어집니다.\n'
            'KouMing 앱 다운로드 → $downloadLink';
      default:
        return generateShareText(wishText);
    }
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

          // Share buttons — 4 items centered
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ShareButton(
                  emoji: '💬',
                  label: I18n.t('pool_share_wechat'),
                  color: const Color(0xFF07C160),
                  onTap: () => _shareWithImage(context, 'WeChat', wishText),
                ),
                const SizedBox(width: 16),
                _ShareButton(
                  emoji: '📱',
                  label: I18n.t('pool_share_whatsapp'),
                  color: const Color(0xFF25D366),
                  onTap: () => _shareWithImage(context, 'WhatsApp', wishText),
                ),
                const SizedBox(width: 16),
                _ShareButton(
                  emoji: '💚',
                  label: I18n.t('pool_share_line'),
                  color: const Color(0xFF06C755),
                  onTap: () => _shareWithImage(context, 'LINE', wishText),
                ),
                const SizedBox(width: 16),
                _ShareButton(
                  emoji: '💛',
                  label: I18n.t('pool_share_kakao'),
                  color: const Color(0xFFFAE100),
                  onTap: () => _shareWithImage(context, 'KakaoTalk', wishText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _shareWithImage(BuildContext context, String platform, String wishText) {
    final localizedText = ShareService.generateLocalizedShareText(wishText, platform);
    Clipboard.setData(ClipboardData(text: localizedText));
    Navigator.pop(context);
    
    // Show image preview dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KouMingTheme.surface,
        title: Text('$platform 分享卡片', style: const TextStyle(color: KouMingTheme.gold, fontFamily: 'MaShanZheng')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    KouMingTheme.gold.withValues(alpha: 0.15),
                    KouMingTheme.purple.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('\u{1F30A}', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        platform == 'WeChat' ? '叩命' : 'KouMing',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: KouMingTheme.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizedText,
                    style: const TextStyle(fontSize: 12, color: KouMingTheme.text, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '文案已复制到剪贴板\n请截图保存或长按粘贴到对应APP',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: KouMingTheme.dim),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了', style: TextStyle(color: KouMingTheme.gold)),
          ),
        ],
      ),
    );
  }

  void _downloadImage(BuildContext context, String wishText) {
    // 由于Flutter直接保存图片到相册需要平台特定代码，
    // 这里先显示一个提示，让用户截图保存
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KouMingTheme.surface,
        title: const Text('保存分享图片', style: TextStyle(color: KouMingTheme.gold, fontFamily: 'MaShanZheng')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    KouMingTheme.gold.withValues(alpha: 0.15),
                    KouMingTheme.purple.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('\u{1F30A}', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        '叩命 KouMing',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: KouMingTheme.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '「$wishText」',
                    style: const TextStyle(fontSize: 14, color: KouMingTheme.text, height: 1.5, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '来为我祝福吧！下载叩命APP，一起许愿',
                    style: TextStyle(fontSize: 11, color: KouMingTheme.dim),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'https://kouming.app/download',
                    style: TextStyle(fontSize: 10, color: KouMingTheme.water, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '请截图保存此图片\n然后分享到您想要的平台',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: KouMingTheme.dim),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了', style: TextStyle(color: KouMingTheme.gold)),
          ),
        ],
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
