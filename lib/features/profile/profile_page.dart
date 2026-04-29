import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/i18n_service.dart';
import 'package:kouming/services/share_service.dart';
import 'package:kouming/features/capsule/capsule_viewer.dart';
import 'package:kouming/features/profile/badges_section.dart';

class ProfilePage extends StatelessWidget {
  final AppState state;
  final void Function(AppState) onStateChanged;
  final void Function(WishCapsule) onFulfillCapsule;

  const ProfilePage({
    super.key,
    required this.state,
    required this.onStateChanged,
    required this.onFulfillCapsule,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  KouMingTheme.gold.withValues(alpha: 0.15),
                  KouMingTheme.purple.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [KouMingTheme.gold, KouMingTheme.warm],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KouMingTheme.gold.withValues(alpha: 0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('\u{1F451}', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(I18n.t('profile_seeker'),
                    style: const TextStyle(
                      fontFamily: 'MaShanZheng',
                      fontSize: 20,
                      color: KouMingTheme.gold,
                    )),
                const SizedBox(height: 4),
                Text(I18n.t('profile_level', args: {'level': '${state.meritLevel}'}),
                    style: const TextStyle(fontSize: 11, color: KouMingTheme.dim)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Merit Progress
          _buildSection(I18n.t('profile_merit_level'), [
            _buildMeritBar(),
          ]),
          const SizedBox(height: 16),

          // Stats Grid
          _buildSection(I18n.t('profile_journey'), [
            _StatRow(
              emoji: '\u{1F30A}',
              label: I18n.t('profile_wishes_thrown'),
              value: '${state.myWishes.length}',
              meaning: I18n.t('pool_throw_meaning'),
            ),
            _StatRow(
              emoji: '\u{1F3EE}',
              label: I18n.t('profile_lanterns_lit'),
              value: '${state.litWishes.length}',
              meaning: I18n.t('pool_light_meaning'),
            ),
            _StatRow(
              emoji: '\u{1F3A2}',
              label: I18n.t('profile_wishes_fished'),
              value: '${state.fishedCount}',
              meaning: I18n.t('pool_fish_meaning'),
            ),
            _StatRow(
              emoji: '\u{1F31F}',
              label: I18n.t('profile_merit_points'),
              value: '${state.meritPoints}',
              meaning: '',
            ),
          ]),
          const SizedBox(height: 16),

          // My Wishes
          if (state.myWishes.isNotEmpty) ...[
            _buildSection(I18n.t('profile_my_wishes'), [
              ...state.myWishes.map((w) => _WishRow(wish: w)),
            ]),
            const SizedBox(height: 16),
          ],

          // Capsules
          if (state.capsules.isNotEmpty) ...[
            Text(I18n.t('profile_capsules'),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KouMingTheme.gold)),
            const SizedBox(height: 8),
            CapsuleTimeline(
              capsules: state.capsules,
              onFulfill: onFulfillCapsule,
            ),
            const SizedBox(height: 16),
          ],

          // Badges
          if (state.badges.isNotEmpty) ...[
            BadgesSection(badges: state.badges),
            const SizedBox(height: 16),
          ],

          // App Info
          _buildAppInfo(),
          const SizedBox(height: 16),
          // Logout Button
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: KouMingTheme.surface,
              title: Text(I18n.t('profile_logout_title'),
                  style: const TextStyle(color: KouMingTheme.text)),
              content: Text(I18n.t('profile_logout_confirm'),
                  style: const TextStyle(color: KouMingTheme.dim)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(I18n.t('cancel'),
                      style: const TextStyle(color: KouMingTheme.dim)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onStateChanged(state.copyWith(userId: ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(I18n.t('profile_logout_success')),
                        backgroundColor: KouMingTheme.purple,
                      ),
                    );
                  },
                  child: Text(I18n.t('confirm'),
                      style: const TextStyle(color: KouMingTheme.gold)),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout, size: 18, color: KouMingTheme.dim),
        label: Text(I18n.t('profile_logout'),
            style: const TextStyle(color: KouMingTheme.dim)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: KouMingTheme.dim.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KouMingTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('关于',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KouMingTheme.gold)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('版本',
                  style: TextStyle(fontSize: 12, color: KouMingTheme.dim)),
              const Spacer(),
              const Text('V1.0',
                  style: TextStyle(fontSize: 12, color: KouMingTheme.text)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('反馈邮箱',
                  style: TextStyle(fontSize: 12, color: KouMingTheme.dim)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // 可以添加打开邮件客户端的逻辑
                },
                child: const Text('bisheng1771@gmail.com',
                    style: TextStyle(
                        fontSize: 12,
                        color: KouMingTheme.water,
                        decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('登录状态',
                  style: TextStyle(fontSize: 12, color: KouMingTheme.dim)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: KouMingTheme.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('已登录',
                    style: TextStyle(fontSize: 11, color: KouMingTheme.gold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KouMingTheme.gold)),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildMeritBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KouMingTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KouMingTheme.purple.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(I18n.t('profile_level', args: {'level': '${state.meritLevel}'}),
                  style: const TextStyle(fontSize: 12, color: KouMingTheme.text)),
              Text('${state.meritPoints} ${I18n.t('profile_pts')}',
                  style: const TextStyle(fontSize: 12, color: KouMingTheme.purple)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.meritProgress,
              backgroundColor: KouMingTheme.purple.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(KouMingTheme.purple),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(I18n.t('profile_to_next', args: {'pct': '${(state.meritProgress * 100).toInt()}'}),
              style: const TextStyle(fontSize: 10, color: KouMingTheme.dim)),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String meaning;

  const _StatRow({
    required this.emoji,
    required this.label,
    required this.value,
    required this.meaning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: KouMingTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: KouMingTheme.text)),
                if (meaning.isNotEmpty)
                  Text(meaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8,
                        color: KouMingTheme.purple.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      )),
              ],
            ),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: KouMingTheme.gold)),
        ],
      ),
    );
  }
}

class _WishRow extends StatelessWidget {
  final Wish wish;
  const _WishRow({required this.wish});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: KouMingTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KouMingTheme.lantern.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Text(wish.category == 'study'
              ? '\u{1F4DA}'
              : wish.category == 'health'
                  ? '\u{1FA7A}'
                  : wish.category == 'love'
                      ? '\u{1F496}'
                      : wish.category == 'money'
                          ? '\u{1F4B0}'
                          : '\u{1F30A}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(wish.text,
                style: const TextStyle(fontSize: 11, color: KouMingTheme.text)),
          ),
          Text('\u{1F3EE} ${wish.lights}',
              style: const TextStyle(fontSize: 10, color: KouMingTheme.lantern)),
          const SizedBox(width: 4),
          // Share button per wish
          GestureDetector(
            onTap: () => ShareService.showShareSheet(context, wishText: wish.text),
            child: const Text('\u{1F4E4}', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
