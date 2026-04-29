import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/i18n_service.dart';

/// Badges grid — shows all 11 badges with earned/locked states
class BadgesSection extends StatelessWidget {
  final List<KouBadge> badges;

  const BadgesSection({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('\u{1F3C6} ${I18n.t('badge_title')}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KouMingTheme.gold)),
            const SizedBox(width: 8),
            Text('${badges.where((b) => b.earned).length}/${badges.length}',
                style: const TextStyle(fontSize: 10, color: KouMingTheme.dim)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges.map((b) => _BadgeTile(badge: b)).toList(),
        ),
      ],
    );
  }
}

class _BadgeTile extends StatefulWidget {
  final KouBadge badge;
  const _BadgeTile({required this.badge});

  @override
  State<_BadgeTile> createState() => _BadgeTileState();
}

class _BadgeTileState extends State<_BadgeTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.badge.earned) _ctrl.forward(from: 0.3);
  }

  @override
  void didUpdateWidget(covariant _BadgeTile old) {
    super.didUpdateWidget(old);
    if (!old.badge.earned && widget.badge.earned) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earned = widget.badge.earned;
    return ScaleTransition(
      scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: earned
              ? KouMingTheme.gold.withValues(alpha: 0.1)
              : KouMingTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: earned
                ? KouMingTheme.gold.withValues(alpha: 0.3)
                : KouMingTheme.dim.withValues(alpha: 0.1),
          ),
          boxShadow: earned
              ? [BoxShadow(color: KouMingTheme.gold.withValues(alpha: 0.15), blurRadius: 8)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.badge.emoji,
              style: TextStyle(
                fontSize: 22,
                color: earned ? null : KouMingTheme.dim.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.badge.label,
              style: TextStyle(
                fontSize: 8,
                color: earned ? KouMingTheme.gold : KouMingTheme.dim.withValues(alpha: 0.4),
                fontWeight: earned ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
