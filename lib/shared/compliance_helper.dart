import 'package:flutter/material.dart';
import 'package:kouming/services/i18n_service.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';

/// Shows a compliance/responsibility disclaimer before any paid action.
/// Returns true if user acknowledged, false if cancelled.
Future<bool> showComplianceDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: KouMingTheme.deep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: KouMingTheme.gold.withValues(alpha: 0.2)),
      ),
      title: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            I18n.t('disclaimer_title'),
            style: const TextStyle(
              color: KouMingTheme.gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DisclaimerRow(
              emoji: '🔮',
              text: I18n.t('disclaimer_virtual_notice'),
            ),
            const SizedBox(height: 10),
            _DisclaimerRow(
              emoji: '💳',
              text: I18n.t('disclaimer_pay_notice'),
            ),
            const SizedBox(height: 10),
            _DisclaimerRow(
              emoji: '💡',
              text: I18n.t('disclaimer_responsible'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            I18n.t('disclaimer_cancel'),
            style: TextStyle(color: KouMingTheme.dim),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: KouMingTheme.gold,
            foregroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(I18n.t('disclaimer_acknowledge')),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _DisclaimerRow extends StatelessWidget {
  final String emoji;
  final String text;

  const _DisclaimerRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: KouMingTheme.text,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
