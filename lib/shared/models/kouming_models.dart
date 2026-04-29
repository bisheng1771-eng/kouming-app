library kouming_models;

/// KouMing Core Models

class Wish {
  final String id;
  final String text;
  final String category;
  final int lights;
  final DateTime createdAt;
  final String? ownerId;
  final bool isMine;

  const Wish({
    required this.id,
    required this.text,
    required this.category,
    this.lights = 0,
    required this.createdAt,
    this.ownerId,
    this.isMine = false,
  });

  Wish copyWith({int? lights}) => Wish(
        id: id,
        text: text,
        category: category,
        lights: lights ?? this.lights,
        createdAt: createdAt,
        ownerId: ownerId,
        isMine: isMine,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'category': category,
        'lights': lights,
        'createdAt': createdAt.toIso8601String(),
        'ownerId': ownerId,
        'isMine': isMine,
      };

  factory Wish.fromJson(Map<String, dynamic> json) => Wish(
        id: json['id'] as String,
        text: json['text'] as String,
        category: json['category'] as String,
        lights: json['lights'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        ownerId: json['ownerId'] as String?,
        isMine: json['isMine'] as bool? ?? false,
      );
}

class WishCapsule {
  final String id;
  final String wishText;
  final DateTime createdAt;
  final DateTime dueDate;
  final String category;
  final CapsuleStatus status;

  const WishCapsule({
    required this.id,
    required this.wishText,
    required this.createdAt,
    required this.dueDate,
    required this.category,
    this.status = CapsuleStatus.waiting,
  });

  int get daysLeft =>
      dueDate.difference(DateTime.now()).inDays.clamp(0, 99999);
  bool get canFulfill => daysLeft <= 0 && status == CapsuleStatus.waiting;

  WishCapsule copyWith({CapsuleStatus? s}) => WishCapsule(
        id: id,
        wishText: wishText,
        createdAt: createdAt,
        dueDate: dueDate,
        category: category,
        status: s ?? status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'wishText': wishText,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'category': category,
        'status': status.name,
      };

  factory WishCapsule.fromJson(Map<String, dynamic> json) => WishCapsule(
        id: json['id'] as String,
        wishText: json['wishText'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String),
        category: json['category'] as String,
        status: CapsuleStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CapsuleStatus.waiting,
        ),
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

  const FortuneSlip({
    required this.title,
    required this.description,
    required this.emoji,
    required this.level,
    required this.element,
    required this.guardian,
  });
}

enum FortuneLevel { supreme, great, medium, low, bad }

class Reading {
  final String hexagram;
  final String element;
  final String body;
  final String advice;
  final int similarCount;
  final int fulfilledCount;

  const Reading({
    required this.hexagram,
    required this.element,
    required this.body,
    required this.advice,
    required this.similarCount,
    required this.fulfilledCount,
  });
}

class KouBadge {
  final String id;
  final String label;
  final String emoji;
  final bool isMerit;
  final bool earned;

  const KouBadge({
    required this.id,
    required this.label,
    required this.emoji,
    this.isMerit = false,
    this.earned = false,
  });

  KouBadge copyWith({bool? earned}) => KouBadge(
        id: id,
        label: label,
        emoji: emoji,
        isMerit: isMerit,
        earned: earned ?? this.earned,
      );
}

class Offering {
  final String name;
  final int priceYuan;
  final String emoji;
  final int meritReward;

  const Offering({
    required this.name,
    required this.priceYuan,
    required this.emoji,
    required this.meritReward,
  });
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
  final Map<String, int> extraLights;
  final String lastResetDate; // YYYY-MM-DD
  final List<KouBadge> badges;
  final String userId;

  const AppState({
    this.throwLimit = 3,
    this.fishLimit = 5,
    this.totalFished = 0,
    this.myWishes = const [],
    this.totalWishes = 8347,
    this.litWishes = const {},
    this.meritPoints = 0,
    this.freeReadingUsed = false,
    this.capsules = const [],
    this.fishedCount = 0,
    this.extraLights = const {},
    this.lastResetDate = '',
    this.badges = const [],
    this.userId = '',
  });

  int get meritLevel => meritPoints ~/ 15 + 1;
  double get meritProgress => (meritPoints % 15) / 15;

  /// Check if daily limits need reset (new day)
  AppState checkDailyReset() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastResetDate != today) {
      return copyWith(
        throwLimit: 3,
        fishLimit: 5,
        freeReadingUsed: false,
        lastResetDate: today,
      );
    }
    return this;
  }

  /// Evaluate and unlock earned badges
  AppState evaluateBadges() {
    final updated = <KouBadge>[];
    for (final b in _allBadgeDefs) {
      final isEarned = _checkBadge(b.id);
      final existing = badges.firstWhere(
        (e) => e.id == b.id,
        orElse: () => b,
      );
      updated.add(existing.copyWith(earned: isEarned));
    }
    return copyWith(badges: updated);
  }

  bool _checkBadge(String id) {
    switch (id) {
      case 'first_wish': return myWishes.isNotEmpty;
      case 'throw_10': return myWishes.length >= 10;
      case 'throw_50': return myWishes.length >= 50;
      case 'light_1': return litWishes.isNotEmpty;
      case 'light_30': return litWishes.length >= 30;
      case 'light_100': return litWishes.length >= 100;
      case 'fish_1': return fishedCount >= 1;
      case 'fish_20': return fishedCount >= 20;
      case 'merit_5': return meritLevel >= 5;
      case 'merit_10': return meritLevel >= 10;
      case 'merit_20': return meritLevel >= 20;
      default: return false;
    }
  }

  static const _allBadgeDefs = <KouBadge>[
    KouBadge(id: 'first_wish', label: '初愿', emoji: '🌊'),
    KouBadge(id: 'throw_10', label: '叩命达人', emoji: '🎯'),
    KouBadge(id: 'throw_50', label: '执念者', emoji: '💎'),
    KouBadge(id: 'light_1', label: '点灯人', emoji: '🏮'),
    KouBadge(id: 'light_30', label: '灯火阑珊', emoji: '✨'),
    KouBadge(id: 'light_100', label: '万家灯火', emoji: '🏮'),
    KouBadge(id: 'fish_1', label: '初捞', emoji: '🎣'),
    KouBadge(id: 'fish_20', label: '渔者', emoji: '🐟'),
    KouBadge(id: 'merit_5', label: '修行者', emoji: '📿', isMerit: true),
    KouBadge(id: 'merit_10', label: '觉者', emoji: '🧘', isMerit: true),
    KouBadge(id: 'merit_20', label: '天命', emoji: '👑', isMerit: true),
  ];

  AppState copyWith({
    int? throwLimit,
    int? fishLimit,
    int? totalFished,
    List<Wish>? myWishes,
    int? totalWishes,
    Set<String>? litWishes,
    int? meritPoints,
    bool? freeReadingUsed,
    List<WishCapsule>? capsules,
    int? fishedCount,
    Map<String, int>? extraLights,
    String? lastResetDate,
    List<KouBadge>? badges,
    String? userId,
  }) =>
      AppState(
        throwLimit: throwLimit ?? this.throwLimit,
        fishLimit: fishLimit ?? this.fishLimit,
        totalFished: totalFished ?? this.totalFished,
        myWishes: myWishes ?? this.myWishes,
        totalWishes: totalWishes ?? this.totalWishes,
        litWishes: litWishes ?? this.litWishes,
        meritPoints: meritPoints ?? this.meritPoints,
        userId: userId ?? this.userId,
        freeReadingUsed: freeReadingUsed ?? this.freeReadingUsed,
        capsules: capsules ?? this.capsules,
        fishedCount: fishedCount ?? this.fishedCount,
        extraLights: extraLights ?? this.extraLights,
        lastResetDate: lastResetDate ?? this.lastResetDate,
        badges: badges ?? this.badges,
      );
}
