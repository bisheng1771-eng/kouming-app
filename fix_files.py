import os

base = r"C:\Users\85932\.qclaw\workspace\software-factory\projects\kouming\lib"

# 1. Fix pool_page.dart
with open(f"{base}\\features\\pool\\pool_page.dart", "r", encoding="utf-8") as f:
    content = f.read()
content = content.replace(
    "  DateTime _ago(int minutes) => DateTime.now().subtract(Duration(minutes: minutes));\n",
    "  static DateTime _ago(int minutes) => DateTime.now().subtract(Duration(minutes: minutes));\n"
)
content = content.replace(
    "  final List<Wish> _mockWishes = [",
    "  static final List<Wish> _mockWishes = ["
)
with open(f"{base}\\features\\pool\\pool_page.dart", "w", encoding="utf-8") as f:
    f.write(content)
print("pool_page.dart: _ago static OK")

# 2. Fix kouming_models.dart - meritLevel is already a field via initializer, just remove the getter
with open(f"{base}\\shared\\models\\kouming_models.dart", "r", encoding="utf-8") as f:
    models = f.read()
# Remove the getter that conflicts
models = models.replace("  int get meritLevel;\n\n", "")
with open(f"{base}\\shared\\models\\kouming_models.dart", "w", encoding="utf-8") as f:
    f.write(models)
print("kouming_models.dart: meritLevel getter removed OK")

# 3. Write profile_page.dart with Python (safe encoding)
profile = r"""import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';

class ProfilePage extends StatelessWidget {
  final AppState state;
  final List<Wish> myWishes;
  final VoidCallback? onSignIn;

  const ProfilePage({
    super.key,
    required this.state,
    required this.myWishes,
    this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _AvatarCard(state: state),
        const SizedBox(height: 16),
        _DailySignIn(onSignIn: onSignIn),
        const SizedBox(height: 16),
        _StatsGrid(state: state),
        const SizedBox(height: 16),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text("My Wishes", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: KouMingTheme.text)),
        ),
        const SizedBox(height: 8),
        if (myWishes.isEmpty)
          const _EmptyWishes()
        else
          ...myWishes.map((w) => _MyWishItem(wish: w)),
        const SizedBox(height: 16),
        const _SettingsList(),
      ]),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  final AppState state;
  const _AvatarCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [KouMingTheme.gold.withValues(alpha: 0.06), KouMingTheme.purple.withValues(alpha: 0.04)]),
        border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle, color: KouMingTheme.purple.withValues(alpha: 0.2)),
          child: const Center(child: Text("\u{1F30A}", style: TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Seeker", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: KouMingTheme.text)),
          const SizedBox(height: 4),
          Text("Merit Lv.${state.meritLevel}", style: const TextStyle(fontSize: 11, color: KouMingTheme.purple)),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: state.meritProgress,
            backgroundColor: KouMingTheme.purple.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(KouMingTheme.purple),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
        ])),
        Column(children: [
          Text("${state.meritPoints}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KouMingTheme.gold)),
          const Text("MP", style: TextStyle(fontSize: 9, color: KouMingTheme.dim)),
        ]),
      ]),
    );
  }
}

class _DailySignIn extends StatelessWidget {
  final VoidCallback? onSignIn;
  const _DailySignIn({this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KouMingTheme.surface,
        border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Text("\u{1F381}", style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Daily Sign-In", style: TextStyle(fontSize: 12, color: KouMingTheme.text)),
          Text("+3 Merit + Attempts", style: TextStyle(fontSize: 10, color: KouMingTheme.dim)),
        ])),
        ElevatedButton(
          onPressed: onSignIn ?? () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: KouMingTheme.gold,
            foregroundColor: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text("Sign In", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AppState state;
  const _StatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatItem(emoji: "\u{1F30A}", label: "Wishes", value: state.myWishes.length),
      _StatItem(emoji: "\u{1F3A2}", label: "Fished", value: state.fishedCount),
      _StatItem(emoji: "\u{1F3EE}", label: "Lit", value: state.litWishes.length),
      _StatItem(emoji: "\u{1F49C}", label: "Merit", value: state.meritPoints),
    ]);
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  const _StatItem({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: KouMingTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text("$value", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: KouMingTheme.text)),
        Text(label, style: const TextStyle(fontSize: 9, color: KouMingTheme.dim)),
      ]),
    ));
  }
}

class _EmptyWishes extends StatelessWidget {
  const _EmptyWishes();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24), alignment: Alignment.center,
      child: const Column(children: [
        Text("\u{1F30A}", style: TextStyle(fontSize: 32)),
        SizedBox(height: 8),
        Text("The abyss holds no wishes yet", style: TextStyle(fontSize: 12, color: KouMingTheme.dim)),
      ]),
    );
  }
}

class _MyWishItem extends StatelessWidget {
  final Wish wish;
  const _MyWishItem({required this.wish});

  @override
  Widget build(BuildContext context) {
    final tier = GlowTier.fromLights(wish.lights);
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: KouMingTheme.surface, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("\u{201C${wish.text}\u{201D}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          const SizedBox(height: 3),
          Text("\u{1F3EE} ${wish.lights}", style: const TextStyle(fontSize: 9, color: KouMingTheme.dim)),
        ])),
        if (tier.level > 0) Text(tier.emoji, style: const TextStyle(fontSize: 14)),
      ]),
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList();

  @override
  Widget build(BuildContext context) {
    final items = [
      {"emoji": "\u{1F310}", "label": "Language"},
      {"emoji": "\u{1F514}", "label": "Notifications"},
      {"emoji": "\u{1F6E1}", "label": "Privacy"},
      {"emoji": "\u{1F4AC}", "label": "Contact Us"},
      {"emoji": "\u{2139}", "label": "About"},
    ];
    return Column(children: items.map((item) => ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text(item["emoji"]!, style: const TextStyle(fontSize: 16)),
      title: Text(item["label"]!, style: const TextStyle(fontSize: 12, color: KouMingTheme.text)),
      trailing: const Icon(Icons.chevron_right, size: 16, color: KouMingTheme.dim),
    )).toList());
  }
}
"""

with open(f"{base}\\features\\profile\\profile_page.dart", "w", encoding="utf-8") as f:
    f.write(profile)
print("profile_page.dart: rewritten OK")
print("All done!")
