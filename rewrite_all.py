import os, sys

base = r"C:\Users\85932\.qclaw\workspace\software-factory\projects\kouming\lib"

# ---- kouming_theme.dart ----
theme = r'''import 'package:flutter/material.dart';

/// KouMingTheme - Abyss Dark Style
class KouMingTheme {
  static const deep   = Color(0xFF060D1A);
  static const mid    = Color(0xFF0C1A30);
  static const surface = Color(0xFF132240);
  static const gold   = Color(0xFFFFD700);
  static const warm   = Color(0xFFFFAA33);
  static const water  = Color(0xFF4A9EFF);
  static const lantern = Color(0xFFFF4444);
  static const spirit = Color(0xFF80DEEA);
  static const purple = Color(0xFFB388FF);
  static const text   = Color(0xFFC8DDF0);
  static const dim    = Color(0xFF4A6A8A);

  static const payGradient = [Color(0xFFFFD700), Color(0xFFFF8C00)];

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: deep,
    colorScheme: const ColorScheme.dark(
      primary: gold, secondary: purple, surface: surface,
      onPrimary: Color(0xFF1A1A2E), onSurface: text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent, elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: 'MaShanZheng', fontSize: 28, color: gold, letterSpacing: 6),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: text, fontSize: 14),
      bodyMedium: TextStyle(color: text, fontSize: 12),
      titleLarge: TextStyle(fontFamily: 'MaShanZheng', fontSize: 24, color: gold),
      titleMedium: TextStyle(fontFamily: 'ZCOOLXiaoWei', fontSize: 16, color: gold),
      labelSmall: TextStyle(color: dim, fontSize: 10),
    ),
    cardTheme: CardThemeData(
      color: surface, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0x1AFFD700))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: const Color(0x0AFFFFFF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x29FFD700))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: gold)),
      hintStyle: const TextStyle(color: dim),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xF2060D1A), selectedItemColor: gold, unselectedItemColor: dim, type: BottomNavigationBarType.fixed,
    ),
  );
}

enum GlowTier {
  none(0, '', ''),
  faint(1, '\u{2728}', 'Faint'),
  bright(2, '\u{1F4AB}', 'Bright'),
  radiant(3, '\u{1F31F}', 'Radiant'),
  miracle(4, '\u{1F386}', 'Miracle');

  const GlowTier(this.level, this.emoji, this.label);
  final int level;
  final String emoji;
  final String label;

  static GlowTier fromLights(int lights) {
    if (lights >= 1000) return miracle;
    if (lights >= 200)  return radiant;
    if (lights >= 50)   return bright;
    if (lights >= 10)   return faint;
    return none;
  }
}

enum WishCategory {
  study('study', 'Study'),
  health('health', 'Health'),
  love('love', 'Love'),
  money('money', 'Money'),
  other('default', 'Other');

  const WishCategory(this.key, this.label);
  final String key;
  final String label;

  static WishCategory fromText(String text) {
    if (RegExp(r'\u4E2D\u5B66|\u8003\u7818|\u4E0A\u5CB8|\u8003\u8BD5|\u6BD5\u4E1A|offer|\u9762\u8BD5|\u6210\u7E9E').hasMatch(text)) return study;
    if (RegExp(r'\u5065\u5EB7|\u8EAB\u4F53|\u624B\u672F|\u5EB7\u590D|\u751F\u75C5|\u5E73\u5B89').hasMatch(text)) return health;
    if (RegExp(r'\u8131\u5355|\u559C\u6B22|\u604B\u7231|\u8868\u767D|\u5728\u4E00\u8D77|\u6697\u604B').hasMatch(text)) return love;
    if (RegExp(r'\u53D1\u8D22|\u66B4\u5BCC|\u8D5A\u94B1|\u623F\u8D37|\u5DE5\u8D44|\u5347\u804C').hasMatch(text)) return money;
    return other;
  }
}
'''

with open(os.path.join(base, "shared", "theme", "kouming_theme.dart"), "w", encoding="utf-8") as f:
    f.write(theme)
print("kouming_theme.dart OK")

# ---- kouming_models.dart ----
models = r'''/// KouMing Models - Core Entities
class Wish {
  final String id;
  final String text;
  final String category;
  final int lights;
  final DateTime createdAt;
  final String? ownerId;
  final bool isMine;

  const Wish({required this.id, required this.text, required this.category,
    this.lights = 0, required this.createdAt, this.ownerId, this.isMine = false});

  Wish copyWith({int? lights}) => Wish(id: id, text: text, category: category,
    lights: lights ?? this.lights, createdAt: createdAt, ownerId: ownerId, isMine: isMine);

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'category': category,
    'lights': lights, 'createdAt': createdAt.toIso8601String(), 'ownerId': ownerId, 'isMine': isMine};

  factory Wish.fromJson(Map<String, dynamic> json) => Wish(
    id: json['id'] as String, text: json['text'] as String, category: json['category'] as String,
    lights: json['lights'] as int? ?? 0, createdAt: DateTime.parse(json['createdAt'] as String),
    ownerId: json['ownerId'] as String?, isMine: json['isMine'] as bool? ?? false,
  );
}

class WishCapsule {
  final String id;
  final String wishText;
  final DateTime createdAt;
  final DateTime dueDate;
  final String category;
  final CapsuleStatus status;

  const WishCapsule({required this.id, required this.wishText, required this.createdAt,
    required this.dueDate, required this.category, this.status = CapsuleStatus.waiting});

  int get daysLeft => dueDate.difference(DateTime.now()).inDays.clamp(0, 99999);
  bool get canFulfill => daysLeft <= 0 && status == CapsuleStatus.waiting;

  WishCapsule copyWith({CapsuleStatus? s}) => WishCapsule(
    id: id, wishText: wishText, createdAt: createdAt, dueDate: dueDate,
    category: category, status: s ?? status);

  Map<String, dynamic> toJson() => {'id': id, 'wishText': wishText,
    'createdAt': createdAt.toIso8601String(), 'dueDate': dueDate.toIso8601String(),
    'category': category, 'status': status.name};

  factory WishCapsule.fromJson(Map<String, dynamic> json) => WishCapsule(
    id: json['id'] as String, wishText: json['wishText'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    dueDate: DateTime.parse(json['dueDate'] as String),
    category: json['category'] as String,
    status: CapsuleStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => CapsuleStatus.waiting),
  );
}

enum CapsuleStatus { waiting, fulfilled }

class FortuneSlip {
  final String title;
  final String description;
  final String emoji;
  final FortuneLevel level;
  final String element;
  final String guardian;

  const FortuneSlip({required this.title, required this.description, required this.emoji,
    required this.level, required this.element, required this.guardian});
}

enum FortuneLevel { supreme, great, medium, low, bad }

class Reading {
  final String hexagram;
  final String element;
  final String body;
  final String advice;
  final int similarCount;
  final int fulfilledCount;

  const Reading({required this.hexagram, required this.element, required this.body,
    required this.advice, required this.similarCount, required this.fulfilledCount});
}

class Badge {
  final String id;
  final String label;
  final String emoji;
  final bool isMerit;

  const Badge({required this.id, required this.label, required this.emoji, this.isMerit = false});
}

class Offering {
  final String name;
  final int priceYuan;
  final String emoji;
  final int meritReward;

  const Offering({required this.name, required this.priceYuan, required this.emoji, required this.meritReward});
}

class AppState {
  final int throwLimit;
  final int fishLimit;
  final int totalFished;
  final List<Wish> myWishes;
  final int totalWishes;
  final Set<String> litWishes;
  final int meritPoints;
  final bool freeReadingUsed;
  final List<WishCapsule> capsules;
  final int fishedCount;

  const AppState({
    this.throwLimit = 3, this.fishLimit = 5, this.totalFished = 0,
    this.myWishes = const [], this.totalWishes = 8347,
    this.litWishes = const {}, this.meritPoints = 0,
    this.freeReadingUsed = false, this.capsules = const [], this.fishedCount = 0,
  }) : meritLevel = meritPoints ~/ 15 + 1;

  final int meritLevel;
  double get meritProgress => (meritPoints % 15) / 15;

  AppState copyWith({
    int? throwLimit, int? fishLimit, int? totalFished,
    List<Wish>? myWishes, int? totalWishes,
    Set<String>? litWishes, int? meritPoints,
    bool? freeReadingUsed, List<WishCapsule>? capsules, int? fishedCount,
  }) => AppState(
    throwLimit: throwLimit ?? this.throwLimit,
    fishLimit: fishLimit ?? this.fishLimit,
    totalFished: totalFished ?? this.totalFished,
    myWishes: myWishes ?? this.myWishes,
    totalWishes: totalWishes ?? this.totalWishes,
    litWishes: litWishes ?? this.litWishes,
    meritPoints: meritPoints ?? this.meritPoints,
    freeReadingUsed: freeReadingUsed ?? this.freeReadingUsed,
    capsules: capsules ?? this.capsules,
    fishedCount: fishedCount ?? this.fishedCount,
  );
}
'''

with open(os.path.join(base, "shared", "models", "kouming_models.dart"), "w", encoding="utf-8") as f:
    f.write(models)
print("kouming_models.dart OK")

# ---- offering_shop.dart ----
shop = r'''import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';

const _headerStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: KouMingTheme.gold, letterSpacing: 1);

class OfferingShop extends StatelessWidget {
  const OfferingShop({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('\u{1F3EE} Offering Shop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KouMingTheme.gold)),
        const SizedBox(height: 4),
        const Text('Offerings increase Merit Points', style: TextStyle(fontSize: 11, color: KouMingTheme.dim)),
        const SizedBox(height: 16),
        const Text('\u{1F4A1} Basic Offerings', style: _headerStyle),
        const SizedBox(height: 8),
        _OfferingItem(emoji: '\u{1F56F}', name: 'Incense Stick',     desc: 'Basic offering of respect',     price: '1',   points: 5),
        _OfferingItem(emoji: '\u{1F338}', name: 'Flower Offering',   desc: 'Fresh daily, brightens the abyss', price: '3', points: 20),
        _OfferingItem(emoji: '\u{1F375}', name: 'Cup of Tea',        desc: 'The spirit says clarity helps',  price: '2',   points: 10),
        _OfferingItem(emoji: '\u{1F4FF}', name: 'Sacred Beads',      desc: 'Premium, boosts merit greatly',  price: '9.9', points: 80),
        const SizedBox(height: 20),
        const Text('\u{1F3B0} Fate Draws', style: _headerStyle),
        const SizedBox(height: 8),
        _OfferingItem(emoji: '\u{1F3B4}', name: 'Fate Card',         desc: 'Daily draw, random fortune card',  price: '6',   points: 0),
        _OfferingItem(emoji: '\u{1F381}', name: 'Fortune Bag',       desc: 'Random contents, possible rare',  price: '6',   points: 0),
        _OfferingItem(emoji: '\u{1F3C6}', name: 'Achievement Offer', desc: 'Unlock at milestones',          price: '18',  points: 0),
        const SizedBox(height: 20),
        const Text('\u{1F389} Return Offerings', style: _headerStyle),
        const SizedBox(height: 8),
        _OfferingItem(emoji: '\u{1F386}', name: 'Return Fireworks',  desc: 'Celebrate wish fulfillment',      price: '3.6', points: 36),
        _OfferingItem(emoji: '\u{1F370}', name: 'Return Cake',       desc: 'Sweet return gift',                 price: '6',   points: 60),
      ]),
    );
  }
}

class _OfferingItem extends StatelessWidget {
  final String emoji;
  final String name;
  final String desc;
  final String price;
  final int points;

  const _OfferingItem({required this.emoji, required this.name, required this.desc, required this.price, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KouMingTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.08)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: KouMingTheme.text)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(fontSize: 10, color: KouMingTheme.dim)),
          if (points > 0) ...[
            const SizedBox(height: 2),
            Text('+$points Merit', style: const TextStyle(fontSize: 10, color: KouMingTheme.purple)),
          ],
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [KouMingTheme.gold, KouMingTheme.warm]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text('\$$price', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        ),
      ]),
    );
  }
}
'''

with open(os.path.join(base, "features", "shop", "offering_shop.dart"), "w", encoding="utf-8") as f:
    f.write(shop)
print("offering_shop.dart OK")

# ---- pool_page.dart (simple but clean) ----
pool = r'''import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';

class PoolPage extends StatefulWidget {
  final AppState state;
  final void Function(AppState) onStateChanged;
  final void Function(Wish) onWishCreated;
  final void Function(String) onLightWish;
  final VoidCallback onReadingRequested;

  const PoolPage({super.key, required this.state, required this.onStateChanged,
    required this.onWishCreated, required this.onLightWish, required this.onReadingRequested});

  @override
  State<PoolPage> createState() => _PoolPageState();
}

class _PoolPageState extends State<PoolPage> {
  final _wishController = TextEditingController();

  static DateTime _ago(int minutes) => DateTime.now().subtract(Duration(minutes: minutes));

  static final List<Wish> _mockWishes = [
    Wish(id: '1',  text: 'Get into my dream school!',         category: 'study',  lights: 892,  createdAt: _ago(2)),
    Wish(id: '2',  text: 'Mom stays healthy',                 category: 'health', lights: 1203, createdAt: _ago(5)),
    Wish(id: '3',  text: 'Find love this year',               category: 'love',   lights: 674,  createdAt: _ago(8)),
    Wish(id: '4',  text: 'Financial freedom',                 category: 'money',  lights: 1547, createdAt: _ago(12)),
    Wish(id: '5',  text: 'Land that dream offer',             category: 'study',  lights: 423,  createdAt: _ago(15)),
    Wish(id: '6',  text: 'World peace',                       category: 'default', lights: 256, createdAt: _ago(25)),
    Wish(id: '7',  text: 'Pay off mortgage early',            category: 'money',  lights: 512,  createdAt: _ago(30)),
    Wish(id: '8',  text: 'He likes me back',                  category: 'love',   lights: 741,  createdAt: _ago(35)),
    Wish(id: '9',  text: 'Pass all exams',                    category: 'study', lights: 1023, createdAt: _ago(40)),
    Wish(id: '10', text: 'My dog surgery goes well',         category: 'health', lights: 668,  createdAt: _ago(60)),
  ];

  @override
  void dispose() {
    _wishController.dispose();
    super.dispose();
  }

  void _throwWish() {
    final text = _wishController.text.trim();
    if (text.isEmpty) return;
    final category = WishCategory.fromText(text);
    final wish = Wish(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text, category: category.key, lights: 0,
      createdAt: DateTime.now(), isMine: true,
    );
    widget.onWishCreated(wish);
    _wishController.clear();
    widget.onStateChanged(widget.state.copyWith(
      myWishes: [wish, ...widget.state.myWishes],
      throwLimit: widget.state.throwLimit - 1,
    ));
  }

  void _fishWish() {
    if (widget.state.fishLimit <= 0) return;
    final random = DateTime.now().millisecondsSinceEpoch % _mockWishes.length;
    final fished = _mockWishes[random];
    widget.onStateChanged(widget.state.copyWith(
      fishLimit: widget.state.fishLimit - 1,
      fishedCount: widget.state.fishedCount + 1,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fished: \u201C${fished.text}\u201D'), backgroundColor: KouMingTheme.surface),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allWishes = [...widget.state.myWishes, ..._mockWishes];
    return Scaffold(
      body: Stack(children: [
        Container(decoration: const BoxDecoration(gradient: RadialGradient(
          center: Alignment.bottomCenter, radius: 1.5,
          colors: [KouMingTheme.mid, KouMingTheme.deep],
        ))),
        SafeArea(child: Column(children: [
          _buildHeader(),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: allWishes.length,
            itemBuilder: (ctx, i) => _WishCard(
              wish: allWishes[i],
              isLit: widget.state.litWishes.contains(allWishes[i].id),
              onLight: () => widget.onLightWish(allWishes[i].id),
              onReading: widget.onReadingRequested,
            ),
          )),
        ])),
        Positioned(bottom: 16, left: 0, right: 0, child: _buildInputBar()),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        const Text("\u{1F30A}", style: TextStyle(fontSize: 28)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Abyss", style: TextStyle(fontFamily: 'MaShanZheng', fontSize: 22, color: KouMingTheme.gold, letterSpacing: 3)),
          Text('${widget.state.totalWishes} wishes sleeping', style: const TextStyle(fontSize: 10, color: KouMingTheme.dim)),
        ]),
        const Spacer(),
        _StatChip(label: 'Throw', value: '${widget.state.throwLimit}', color: KouMingTheme.water),
        const SizedBox(width: 6),
        _StatChip(label: 'Fish', value: '${widget.state.fishLimit}', color: KouMingTheme.purple),
      ]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KouMingTheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _wishController,
          style: const TextStyle(fontSize: 13, color: KouMingTheme.text),
          decoration: const InputDecoration(hintText: 'Ask the abyss...', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
          onSubmitted: (_) => _throwWish(),
        )),
        if (widget.state.throwLimit > 0)
          IconButton(onPressed: _throwWish, icon: const Text("\u{1F30A}", style: TextStyle(fontSize: 22)), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36)),
        IconButton(onPressed: widget.state.fishLimit > 0 ? _fishWish : null, icon: const Text("\u{1F3A2}", style: TextStyle(fontSize: 20)), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36)),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 10, color: color)),
        const SizedBox(width: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

class _WishCard extends StatelessWidget {
  final Wish wish;
  final bool isLit;
  final VoidCallback onLight;
  final VoidCallback onReading;

  const _WishCard({required this.wish, required this.isLit, required this.onLight, required this.onReading});

  @override
  Widget build(BuildContext context) {
    final category = WishCategory.values.firstWhere((c) => c.key == wish.category, orElse: () => WishCategory.other);
    final tier = GlowTier.fromLights(wish.lights);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KouMingTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLit ? KouMingTheme.lantern.withValues(alpha: 0.4) : KouMingTheme.dim.withValues(alpha: 0.1)),
        boxShadow: isLit ? [BoxShadow(color: KouMingTheme.lantern.withValues(alpha: 0.1), blurRadius: 8, spreadRadius: 1)] : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(category.label, style: TextStyle(fontSize: 10, color: KouMingTheme.dim)),
          const SizedBox(width: 8),
          Text(_timeAgo(wish.createdAt), style: TextStyle(fontSize: 9, color: KouMingTheme.dim)),
          const Spacer(),
          if (tier.level > 0) ...[
            Text(tier.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(tier.label, style: TextStyle(fontSize: 9, color: KouMingTheme.gold)),
          ],
        ]),
        const SizedBox(height: 6),
        Text('\u201C${wish.text}\u201D', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: KouMingTheme.text)),
        const SizedBox(height: 8),
        Row(children: [
          Text('\u{1F3EE} ${wish.lights}', style: TextStyle(fontSize: 10, color: KouMingTheme.lantern)),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: isLit ? null : onLight,
            icon: const Text('\u{1F3EE}', style: TextStyle(fontSize: 13)),
            label: Text(isLit ? 'Lit' : 'Light'),
            style: OutlinedButton.styleFrom(
              foregroundColor: KouMingTheme.lantern,
              side: BorderSide(color: isLit ? KouMingTheme.lantern : KouMingTheme.lantern.withValues(alpha: 0.2)),
              backgroundColor: KouMingTheme.lantern.withValues(alpha: isLit ? 0.15 : 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (!wish.isMine) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: onReading,
              style: TextButton.styleFrom(foregroundColor: KouMingTheme.purple, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Oracle', style: TextStyle(fontSize: 10)),
            ),
          ],
        ]),
      ]),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d';
  }
}
'''

with open(os.path.join(base, "features", "pool", "pool_page.dart"), "w", encoding="utf-8") as f:
    f.write(pool)
print("pool_page.dart OK")

print("All core files rewritten successfully!")
'''

with open(r"C:\Users\85932\.qclaw\workspace\software-factory\projects\kouming\fix_all.py", "w", encoding="utf-8") as f:
    f.write(theme + "\n" + models + "\n" + shop + "\n" + pool)

# Actually write the Python script properly
script = r'''import os
base = r"C:\Users\85932\.qclaw\workspace\software-factory\projects\kouming\lib"

# kouming_theme.dart
theme = r"""import 'package:flutter/material.dart';

class KouMingTheme {
  static const deep   = Color(0xFF060D1A);
  static const mid    = Color(0xFF0C1A30);
  static const surface = Color(0xFF132240);
  static const gold   = Color(0xFFFFD700);
  static const warm   = Color(0xFFFFAA33);
  static const water  = Color(0xFF4A9EFF);
  static const lantern = Color(0xFFFF4444);
  static const spirit = Color(0xFF80DEEA);
  static const purple = Color(0xFFB388FF);
  static const text   = Color(0xFFC8DDF0);
  static const dim    = Color(0xFF4A6A8A);
  static const payGradient = [Color(0xFFFFD700), Color(0xFFFF8C00)];

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: deep,
    colorScheme: const ColorScheme.dark(primary: gold, secondary: purple, surface: surface, onPrimary: Color(0xFF1A1A2E), onSurface: text),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, titleTextStyle: TextStyle(fontFamily: 'MaShanZheng', fontSize: 28, color: gold, letterSpacing: 6)),
    textTheme: const TextTheme(bodyLarge: TextStyle(color: text, fontSize: 14), bodyMedium: TextStyle(color: text, fontSize: 12), titleLarge: TextStyle(fontFamily: 'MaShanZheng', fontSize: 24, color: gold), titleMedium: TextStyle(fontFamily: 'ZCOOLXiaoWei', fontSize: 16, color: gold), labelSmall: TextStyle(color: dim, fontSize: 10)),
    cardTheme: CardThemeData(color: surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0x1AFFD700)))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0x0AFFFFFF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x29FFD700))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: gold)), hintStyle: const TextStyle(color: dim)),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xF2060D1A), selectedItemColor: gold, unselectedItemColor: dim, type: BottomNavigationBarType.fixed),
  );
}

enum GlowTier {
  none(0, '', ''), faint(1, '\u2728', 'Faint'),
  bright(2, '\u{1F4AB}', 'Bright'), radiant(3, '\u{1F31F}', 'Radiant'),
  miracle(4, '\u{1F386}', 'Miracle');
  const GlowTier(this.level, this.emoji, this.label);
  final int level; final String emoji; final String label;
  static GlowTier fromLights(int lights) {
    if (lights >= 1000) return miracle;
    if (lights >= 200)  return radiant;
    if (lights >= 50)   return bright;
    if (lights >= 10)   return faint;
    return none;
  }
}

enum WishCategory {
  study('study', 'Study'), health('health', 'Health'),
  love('love', 'Love'), money('money', 'Money'), other('default', 'Other');
  const WishCategory(this.key, this.label);
  final String key; final String label;
  static WishCategory fromText(String text) {
    if (RegExp(r'\u4e2d\u5b66|\u8003\u7818|\u4e0a\u5cb8|\u8003\u8bd5|\u6bd5\u4e1a|offer|\u9762\u8bd5|\u6210\u7e9e').hasMatch(text)) return study;
    if (RegExp(r'\u5065\u5eb7|\u8eab\u4f53|\u624b\u672f|\u5eb7\u590d|\u751f\u75c5|\u5e73\u5b89').hasMatch(text)) return health;
    if (RegExp(r'\u8131\u5355|\u559c\u6b22|\u604b\u7231|\u8868\u767d|\u5728\u4e00\u8d77|\u6697\u604b').hasMatch(text)) return love;
    if (RegExp(r'\u53d1\u8d22|\u66b4\u5bcc|\u8d5a\u94b1|\u623f\u8d37|\u5de5\u8d44|\u5347\u804c').hasMatch(text)) return money;
    return other;
  }
}
"""

# kouming_models.dart
models = r"""class Wish {
  final String id; final String text; final String category;
  final int lights; final DateTime createdAt; final String? ownerId; final bool isMine;
  const Wish({required this.id, required this.text, required this.category, this.lights = 0, required this.createdAt, this.ownerId, this.isMine = false});
  Wish copyWith({int? lights}) => Wish(id: id, text: text, category: category, lights: lights ?? this.lights, createdAt: createdAt, ownerId: ownerId, isMine: isMine);
  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'category': category, 'lights': lights, 'createdAt': createdAt.toIso8601String(), 'ownerId': ownerId, 'isMine': isMine};
  factory Wish.fromJson(Map<String, dynamic> json) => Wish(id: json['id'] as String, text: json['text'] as String, category: json['category'] as String, lights: json['lights'] as int? ?? 0, createdAt: DateTime.parse(json['createdAt'] as String), ownerId: json['ownerId'] as String?, isMine: json['isMine'] as bool? ?? false);
}

class WishCapsule {
  final String id; final String wishText; final DateTime createdAt; final DateTime dueDate; final String category; final CapsuleStatus status;
  const WishCapsule({required this.id, required this.wishText, required this.createdAt, required this.dueDate, required this.category, this.status = CapsuleStatus.waiting});
  int get daysLeft => dueDate.difference(DateTime.now()).inDays.clamp(0, 99999);
  bool get canFulfill => daysLeft <= 0 && status == CapsuleStatus.waiting;
  WishCapsule copyWith({CapsuleStatus? s}) => WishCapsule(id: id, wishText: wishText, createdAt: createdAt, dueDate: dueDate, category: category, status: s ?? status);
  Map<String, dynamic> toJson() => {'id': id, 'wishText': wishText, 'createdAt': createdAt.toIso8601String(), 'dueDate': dueDate.toIso8601String(), 'category': category, 'status': status.name};
  factory WishCapsule.fromJson(Map<String, dynamic> json) => WishCapsule(id: json['id'] as String, wishText: json['wishText'] as String, createdAt: DateTime.parse(json['createdAt'] as String), dueDate: DateTime.parse(json['dueDate'] as String), category: json['category'] as String, status: CapsuleStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => CapsuleStatus.waiting));
}
enum CapsuleStatus { waiting, fulfilled }

class FortuneSlip {
  final String title; final String description; final String emoji; final FortuneLevel level; final String element; final String guardian;
  const FortuneSlip({required this.title, required this.description, required this.emoji, required this.level, required this.element, required this.guardian});
}
enum FortuneLevel { supreme, great, medium, low, bad }

class Reading {
  final String hexagram; final String element; final String body; final String advice; final int similarCount; final int fulfilledCount;
  const Reading({required this.hexagram, required this.element, required this.body, required this.advice, required this.similarCount, required this.fulfilledCount});
}

class Badge {
  final String id; final String label; final String emoji; final bool isMerit;
  const Badge({required this.id, required this.label, required this.emoji, this.isMerit = false});
}

class Offering {
  final String name; final int priceYuan; final String emoji; final int meritReward;
  const Offering({required this.name, required this.priceYuan, required this.emoji, required this.meritReward});
}

class AppState {
  final int throwLimit; final int fishLimit; final int totalFished;
  final List<Wish> myWishes; final int totalWishes;
  final Set<String> litWishes; final int meritPoints;
  final bool freeReadingUsed; final List<WishCapsule> capsules; final int fishedCount;
  const AppState({this.throwLimit = 3, this.fishLimit = 5, this.totalFished = 0, this.myWishes = const [], this.totalWishes = 8347, this.litWishes = const {}, this.meritPoints = 0, this.freeReadingUsed = false, this.capsules = const [], this.fishedCount = 0}) : meritLevel = meritPoints ~/ 15 + 1;
  final int meritLevel;
  double get meritProgress => (meritPoints % 15) / 15;
  AppState copyWith({int? throwLimit, int? fishLimit, int? totalFished, List<Wish>? myWishes, int? totalWishes, Set<String>? litWishes, int? meritPoints, bool? freeReadingUsed, List<WishCapsule>? capsules, int? fishedCount}) => AppState(throwLimit: throwLimit ?? this.throwLimit, fishLimit: fishLimit ?? this.fishLimit, totalFished: totalFished ?? this.totalFished, myWishes: myWishes ?? this.myWishes, totalWishes: totalWishes ?? this.totalWishes, litWishes: litWishes ?? this.litWishes, meritPoints: meritPoints ?? this.meritPoints, freeReadingUsed: freeReadingUsed ?? this.freeReadingUsed, capsules: capsules ?? this.capsules, fishedCount: fishedCount ?? this.fishedCount);
}
"""

with open(os.path.join(base, "shared", "theme", "kouming_theme.dart"), "w", encoding="utf-8") as f:
    f.write(theme)
print("1. kouming_theme.dart OK")

with open(os.path.join(base, "shared", "models", "kouming_models.dart"), "w", encoding="utf-8") as f:
    f.write(models)
print("2. kouming_models.dart OK")

# offering_shop.dart
shop = r"""import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';

const _hs = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: KouMingTheme.gold, letterSpacing: 1);

class OfferingShop extends StatelessWidget {
  const OfferingShop({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('\u{1F3EE} Offering Shop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KouMingTheme.gold)),
      const SizedBox(height: 4),
      const Text('Offerings increase Merit Points', style: TextStyle(fontSize: 11, color: KouMingTheme.dim)),
      const SizedBox(height: 16),
      const Text('\u{1F4A1} Basic Offerings', style: _hs), const SizedBox(height: 8),
      _oi('\u{1F56F}', 'Incense Stick', 'Basic offering of respect', '\u00a51', 5),
      _oi('\u{1F338}', 'Flower Offering', 'Fresh daily, brightens the abyss', '\u00a53', 20),
      _oi('\u{1F375}', 'Cup of Tea', 'Clarity helps the spirit', '\u00a52', 10),
      _oi('\u{1F4FF}', 'Sacred Beads', 'Premium, boosts merit greatly', '\u00a59.9', 80),
      const SizedBox(height: 20),
      const Text('\u{1F3B0} Fate Draws', style: _hs), const SizedBox(height: 8),
      _oi('\u{1F3B4}', 'Fate Card', 'Daily draw, random fortune card', '\u00a56', 0),
      _oi('\u{1F381}', 'Fortune Bag', 'Random contents, possible rare', '\u00a56', 0),
      _oi('\u{1F3C6}', 'Achievement Offer', 'Unlock at milestones', '\u00a518', 0),
      const SizedBox(height: 20),
      const Text('\u{1F389} Return Offerings', style: _hs), const SizedBox(height: 8),
      _oi('\u{1F386}', 'Return Fireworks', 'Celebrate wish fulfillment', '\u00a53.6', 36),
      _oi('\u{1F370}', 'Return Cake', 'Sweet return gift', '\u00a56', 60),
    ]));
  }
}

Widget _oi(String emoji, String name, String desc, String price, int points) {
  return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: KouMingTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.08))),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 24)), const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: KouMingTheme.text)),
        const SizedBox(height: 2),
        Text(desc, style: const TextStyle(fontSize: 10, color: KouMingTheme.dim)),
        if (points > 0) Text('+$points Merit', style: const TextStyle(fontSize: 10, color: KouMingTheme.purple)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [KouMingTheme.gold, KouMingTheme.warm]), borderRadius: BorderRadius.circular(16)),
        child: Text(price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)))),
    ])));
}
"""

with open(os.path.join(base, "features", "shop", "offering_shop.dart"), "w", encoding="utf-8") as f:
    f.write(shop)
print("3. offering_shop.dart OK")

# pool_page.dart
pool = r"""import 'package:flutter/material.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';
import 'package:kouming/shared/models/kouming_models.dart';

class PoolPage extends StatefulWidget {
  final AppState state;
  final void Function(AppState) onStateChanged;
  final void Function(Wish) onWishCreated;
  final void Function(String) onLightWish;
  final VoidCallback onReadingRequested;
  const PoolPage({super.key, required this.state, required this.onStateChanged, required this.onWishCreated, required this.onLightWish, required this.onReadingRequested});
  @override
  State<PoolPage> createState() => _PoolPageState();
}

class _PoolPageState extends State<PoolPage> {
  final _wishController = TextEditingController();
  static DateTime _ago(int minutes) => DateTime.now().subtract(Duration(minutes: minutes));
  static final List<Wish> _mockWishes = [
    Wish(id: '1', text: 'Get into my dream school!', category: 'study', lights: 892, createdAt: _ago(2)),
    Wish(id: '2', text: 'Mom stays healthy', category: 'health', lights: 1203, createdAt: _ago(5)),
    Wish(id: '3', text: 'Find love this year', category: 'love', lights: 674, createdAt: _ago(8)),
    Wish(id: '4', text: 'Financial freedom', category: 'money', lights: 1547, createdAt: _ago(12)),
    Wish(id: '5', text: 'Land that dream offer', category: 'study', lights: 423, createdAt: _ago(15)),
    Wish(id: '6', text: 'World peace', category: 'default', lights: 256, createdAt: _ago(25)),
    Wish(id: '7', text: 'Pay off mortgage early', category: 'money', lights: 512, createdAt: _ago(30)),
    Wish(id: '8', text: 'He likes me back', category: 'love', lights: 741, createdAt: _ago(35)),
    Wish(id: '9', text: 'Pass all exams', category: 'study', lights: 1023, createdAt: _ago(40)),
    Wish(id: '10', text: 'My dog surgery goes well', category: 'health', lights: 668, createdAt: _ago(60)),
  ];
  @override
  void dispose() { _wishController.dispose(); super.dispose(); }
  void _throwWish() {
    final text = _wishController.text.trim();
    if (text.isEmpty) return;
    final cat = WishCategory.fromText(text);
    final wish = Wish(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, category: cat.key, lights: 0, createdAt: DateTime.now(), isMine: true);
    widget.onWishCreated(wish);
    _wishController.clear();
    widget.onStateChanged(widget.state.copyWith(myWishes: [wish, ...widget.state.myWishes], throwLimit: widget.state.throwLimit - 1));
  }
  void _fishWish() {
    if (widget.state.fishLimit <= 0) return;
    final idx = DateTime.now().millisecondsSinceEpoch % _mockWishes.length;
    final fished = _mockWishes[idx];
    widget.onStateChanged(widget.state.copyWith(fishLimit: widget.state.fishLimit - 1, fishedCount: widget.state.fishedCount + 1));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fished: \u201C${fished.text}\u201D'), backgroundColor: KouMingTheme.surface));
  }
  @override
  Widget build(BuildContext context) {
    final all = [...widget.state.myWishes, ..._mockWishes];
    return Scaffold(body: Stack(children: [
      Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.bottomCenter, radius: 1.5, colors: [KouMingTheme.mid, KouMingTheme.deep]))),
      SafeArea(child: Column(children: [_h(), Expanded(child: ListView.builder(padding: const EdgeInsets.only(bottom: 80), itemCount: all.length, itemBuilder: (ctx, i) => _WC(wish: all[i], isLit: widget.state.litWishes.contains(all[i].id), onLight: () => widget.onLightWish(all[i].id), onReading: widget.onReadingRequested)))])]),
      Positioned(bottom: 16, left: 0, right: 0, child: _ib()),
    ]));
  }
  Widget _h() => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(children: [
    const Text('\u{1F30A}', style: TextStyle(fontSize: 28)), const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Abyss', style: TextStyle(fontFamily: 'MaShanZheng', fontSize: 22, color: KouMingTheme.gold, letterSpacing: 3)),
      Text('${widget.state.totalWishes} wishes sleeping', style: const TextStyle(fontSize: 10, color: KouMingTheme.dim)),
    ]),
    const Spacer(),
    _sc('Throw', '${widget.state.throwLimit}', KouMingTheme.water), const SizedBox(width: 6),
    _sc('Fish', '${widget.state.fishLimit}', KouMingTheme.purple),
  ]));
  Widget _sc(String l, String v, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withValues(alpha: 0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(l, style: TextStyle(fontSize: 10, color: c)), const SizedBox(width: 2), Text(v, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c))]));
  Widget _ib() => Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: KouMingTheme.surface.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(20), border: Border.all(color: KouMingTheme.gold.withValues(alpha: 0.2))), child: Row(children: [
    Expanded(child: TextField(controller: _wishController, style: const TextStyle(fontSize: 13, color: KouMingTheme.text), decoration: const InputDecoration(hintText: 'Ask the abyss...', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)), onSubmitted: (_) => _throwWish())),
    if (widget.state.throwLimit > 0) IconButton(onPressed: _throwWish, icon: const Text('\u{1F30A}', style: TextStyle(fontSize: 22)), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36)),
    IconButton(onPressed: widget.state.fishLimit > 0 ? _fishWish : null, icon: const Text('\u{1F3A2}', style: TextStyle(fontSize: 20)), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36)),
  ]));
}

class _WC extends StatelessWidget {
  final Wish wish; final bool isLit; final VoidCallback onLight; final VoidCallback onReading;
  const _WC({required this.wish, required this.isLit, required this.onLight, required this.onReading});
  @override
  Widget build(BuildContext context) {
    final cat = WishCategory.values.firstWhere((c) => c.key == wish.category, orElse: () => WishCategory.other);
    final tier = GlowTier.fromLights(wish.lights);
    return Container(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: KouMingTheme.surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: isLit ? KouMingTheme.lantern.withValues(alpha: 0.4) : KouMingTheme.dim.withValues(alpha: 0.1)), boxShadow: isLit ? [BoxShadow(color: KouMingTheme.lantern.withValues(alpha: 0.1), blurRadius: 8, spreadRadius: 1)] : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(cat.label, style: TextStyle(fontSize: 10, color: KouMingTheme.dim)), const SizedBox(width: 8), Text(_ta(wish.createdAt), style: TextStyle(fontSize: 9, color: KouMingTheme.dim)), const Spacer(), if (tier.level > 0) Text('${tier.emoji} ${tier.label}', style: TextStyle(fontSize: 9, color: KouMingTheme.gold))]),
        const SizedBox(height: 6),
        Text('\u201C${wish.text}\u201D', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: KouMingTheme.text)),
        const SizedBox(height: 8),
        Row(children: [Text('\u{1F3EE} ${wish.lights}', style: TextStyle(fontSize: 10, color: KouMingTheme.lantern)), const Spacer(),
          OutlinedButton.icon(onPressed: isLit ? null : onLight, icon: const Text('\u{1F3EE}', style: TextStyle(fontSize: 13)), label: Text(isLit ? 'Lit' : 'Light'),
            style: OutlinedButton.styleFrom(foregroundColor: KouMingTheme.lantern, side: BorderSide(color: isLit ? KouMingTheme.lantern : KouMingTheme.lantern.withValues(alpha: 0.2)), backgroundColor: KouMingTheme.lantern.withValues(alpha: isLit ? 0.15 : 0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          if (!wish.isMine) ...[const SizedBox(width: 6), TextButton(onPressed: onReading, style: TextButton.styleFrom(foregroundColor: KouMingTheme.purple, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: const Text('Oracle', style: TextStyle(fontSize: 10)))],
        ]),
      ]),
    );
  }
  String _ta(DateTime dt) { final d = DateTime.now().difference(dt); if (d.inMinutes < 60) return '${d.inMinutes}m ago'; if (d.inHours < 24) return '${d.inHours}h ago'; return '${d.inDays}d'; }
}
"""

with open(os.path.join(base, "features", "pool", "pool_page.dart"), "w", encoding="utf-8") as f:
    f.write(pool)
print("4. pool_page.dart OK")

print("ALL DONE - run flutter analyze next")
'''

with open(r"C:\Users\85932\.qclaw\workspace\software-factory\projects\kouming\rewrite_all.py", "w", encoding="utf-8") as f:
    f.write(script)
print("rewrite_all.py written")
