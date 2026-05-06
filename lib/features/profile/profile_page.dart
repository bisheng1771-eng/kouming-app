import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/services/i18n_service.dart';
import 'package:kouming/services/share_service.dart';
import 'package:kouming/services/storage_service.dart';
import 'package:kouming/features/capsule/capsule_viewer.dart';
import 'package:kouming/features/profile/badges_section.dart';

class _LevelInfo {
  final int level;
  final int points;
  final String title;
  const _LevelInfo(this.level, this.points, this.title);
}

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
                // 昵称（大字）
                Text(
                  state.nickname.isNotEmpty ? state.nickname : I18n.t('profile_seeker'),
                  style: const TextStyle(
                    fontFamily: 'MaShanZheng',
                    fontSize: 22,
                    color: KouMingTheme.gold,
                  ),
                ),
                const SizedBox(height: 4),
                // 等级称号（小字）
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: KouMingTheme.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lv.${state.meritLevel} ${state.levelBenefits.title}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: KouMingTheme.gold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Capsules - 直接显示，不重复标题
          if (state.capsules.isNotEmpty) ...[
            const SizedBox(height: 8),
            CapsuleTimeline(
              capsules: state.capsules,
              onFulfill: onFulfillCapsule,
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KouMingTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  '还没有心愿胶囊\n去许愿池投下你的第一个愿望吧',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: KouMingTheme.dim),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 等级祝福 - 显示升级门槛
          _buildSection('等级祝福', [
            Text(
              '祝福数 = 法物购买 + 还愿仪式 + 收到祝福',
              style: TextStyle(
                fontSize: 11,
                color: KouMingTheme.dim.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '当前祝福数: ${state.blessingCount}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: KouMingTheme.gold,
              ),
            ),
            const SizedBox(height: 12),
            _buildLevelThresholds(),
          ]),
          const SizedBox(height: 16),

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
    final isLoggedIn = state.userId.isNotEmpty;
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          if (!isLoggedIn) {
            // 未登录状态 - 显示登录对话框
            _showLoginDialog(context);
            return;
          }
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
                  onPressed: () async {
                    Navigator.pop(context);
                    // 保存当前用户数据
                    final storage = StorageService();
                    await storage.saveAppState(state);
                    
                    // 清空状态（未登录状态）
                    onStateChanged(const AppState().checkDailyReset());
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
        icon: Icon(
          isLoggedIn ? Icons.logout : Icons.login,
          size: 18,
          color: isLoggedIn ? KouMingTheme.dim : KouMingTheme.gold,
        ),
        label: Text(
          isLoggedIn ? I18n.t('profile_logout') : '登录 / 注册',
          style: TextStyle(
            color: isLoggedIn ? KouMingTheme.dim : KouMingTheme.gold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isLoggedIn
                ? KouMingTheme.dim.withValues(alpha: 0.3)
                : KouMingTheme.gold.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final nicknameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KouMingTheme.surface,
        title: const Text('设置昵称', style: TextStyle(color: KouMingTheme.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '输入你的昵称即可开始使用\n支持中文、英文、日语、韩语等各种语言',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: KouMingTheme.dim),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nicknameController,
              style: const TextStyle(color: KouMingTheme.text),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: '例如：小明、Sakura、천사',
                hintStyle: const TextStyle(color: KouMingTheme.dim, fontSize: 12),
                prefixIcon: const Icon(Icons.person_outline, color: KouMingTheme.dim),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KouMingTheme.dim),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: KouMingTheme.dim.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KouMingTheme.gold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: KouMingTheme.dim)),
          ),
          TextButton(
            onPressed: () async {
              final nickname = nicknameController.text.trim();
              if (nickname.isNotEmpty) {
                Navigator.pop(context);
                // 生成唯一userId，昵称作为显示名
                final userId = 'user_${nickname.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
                
                // 加载该昵称的本地数据
                final storage = StorageService();
                final saved = await storage.loadAppState(nickname: nickname);
                
                if (saved != null) {
                  // 已有数据，恢复
                  onStateChanged(saved.copyWith(
                    userId: userId,
                    nickname: nickname,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('欢迎回来，$nickname！'),
                      backgroundColor: KouMingTheme.gold,
                    ),
                  );
                } else {
                  // 新用户，创建空状态
                  onStateChanged(state.copyWith(
                    userId: userId,
                    nickname: nickname,
                    // 重置所有数据
                    myWishes: [],
                    capsules: [],
                    totalWishes: 8347,
                    meritPoints: 0,
                    litWishes: {},
                    extraLights: {},
                    fishedCount: 0,
                    totalFished: 0,
                    freeOracleUsed: 0,
                    freeFateDrawUsed: 0,
                    badges: [],
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('欢迎，$nickname！'),
                      backgroundColor: KouMingTheme.gold,
                    ),
                  );
                }
              }
            },
            child: const Text('开始', style: TextStyle(color: KouMingTheme.gold)),
          ),
        ],
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
                  color: state.userId.isNotEmpty
                      ? KouMingTheme.gold.withValues(alpha: 0.1)
                      : KouMingTheme.dim.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    state.userId.isNotEmpty ? '已登录' : '未登录',
                    style: TextStyle(
                      fontSize: 11,
                      color: state.userId.isNotEmpty
                          ? KouMingTheme.gold
                          : KouMingTheme.dim,
                    )),
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

  Widget _buildLevelThresholds() {
    // 新规则：每级100祝福，Lv1=100, Lv2=200, Lv3=300...
    final thresholds = [
      _LevelInfo(1, 100, '寻光者'),
      _LevelInfo(2, 200, '修行者'),
      _LevelInfo(3, 300, '悟道者'),
      _LevelInfo(4, 400, '护法'),
      _LevelInfo(5, 500, '长老'),
      _LevelInfo(6, 600, '尊者'),
      _LevelInfo(7, 700, '圣者'),
      _LevelInfo(8, 800, '半仙'),
      _LevelInfo(9, 900, '天命之人'),
      _LevelInfo(10, 1000, '化境'),
    ];

    return Column(
      children: thresholds.map((info) {
        final isCurrent = info.level == state.meritLevel;
        final isUnlocked = state.blessingCount >= info.points;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isCurrent
                ? KouMingTheme.gold.withValues(alpha: 0.15)
                : KouMingTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: isCurrent
                ? Border.all(color: KouMingTheme.gold.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? KouMingTheme.gold.withValues(alpha: 0.2)
                      : KouMingTheme.dim.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${info.level}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? KouMingTheme.gold : KouMingTheme.dim,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  info.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? KouMingTheme.gold : KouMingTheme.text,
                  ),
                ),
              ),
              Text(
                '${info.points}祝福',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? KouMingTheme.gold : KouMingTheme.dim,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBlessingRow(String emoji, String label, String value) {
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
            child: Text(label, style: const TextStyle(fontSize: 12, color: KouMingTheme.text)),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KouMingTheme.gold)),
        ],
      ),
    );
  }

  Widget _buildFulfillCard(WishCapsule capsule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KouMingTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: KouMingTheme.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('\u{1F386}', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capsule.wishText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KouMingTheme.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '预计实现时间: ${capsule.dueDate.toString().substring(0, 10)}',
                  style: const TextStyle(fontSize: 10, color: KouMingTheme.dim),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onFulfillCapsule(capsule),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [KouMingTheme.gold, KouMingTheme.warm],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '还愿',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
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
