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
  final int blessingCount; // 收到的文字祝福条数
  final List<String> blessings; // 收到的祝福文字列表
  final String? fulfillText; // 还愿文字

  const Wish({
    required this.id,
    required this.text,
    required this.category,
    this.lights = 0,
    required this.createdAt,
    this.ownerId,
    this.isMine = false,
    this.blessingCount = 0,
    this.blessings = const [],
    this.fulfillText,
  });

  Wish copyWith({int? lights, int? blessingCount, List<String>? blessings, String? fulfillText}) => Wish(
        id: id,
        text: text,
        category: category,
        lights: lights ?? this.lights,
        createdAt: createdAt,
        ownerId: ownerId,
        isMine: isMine,
        blessingCount: blessingCount ?? this.blessingCount,
        blessings: blessings ?? this.blessings,
        fulfillText: fulfillText ?? this.fulfillText,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'category': category,
        'lights': lights,
        'createdAt': createdAt.toIso8601String(),
        'ownerId': ownerId,
        'isMine': isMine,
        'blessingCount': blessingCount,
        'blessings': blessings,
        'fulfillText': fulfillText,
      };

  factory Wish.fromJson(Map<String, dynamic> json) => Wish(
        id: json['id'] as String,
        text: json['text'] as String,
        category: json['category'] as String,
        lights: json['lights'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        ownerId: json['ownerId'] as String?,
        isMine: json['isMine'] as bool? ?? false,
        blessingCount: json['blessingCount'] as int? ?? 0,
        blessings: (json['blessings'] as List<dynamic>?)?.cast<String>() ?? const [],
        fulfillText: json['fulfillText'] as String?,
      );
}

class WishCapsule {
  final String id;
  final String wishText;
  final DateTime createdAt;
  final DateTime dueDate;
  final String category;
  final CapsuleStatus status;
  final int lights; // 被点灯数
  final int blessingCount; // 收到的文字祝福条数
  final List<String> blessings; // 收到的祝福文字列表
  final String? fulfillText; // 还愿时写的文字

  const WishCapsule({
    required this.id,
    required this.wishText,
    required this.createdAt,
    required this.dueDate,
    required this.category,
    this.status = CapsuleStatus.waiting,
    this.lights = 0,
    this.blessingCount = 0,
    this.blessings = const [],
    this.fulfillText,
  });

  int get daysLeft =>
      dueDate.difference(DateTime.now()).inDays.clamp(0, 99999);
  bool get canFulfill => daysLeft <= 0 && status == CapsuleStatus.waiting;

  WishCapsule copyWith({CapsuleStatus? s, int? lights, int? blessingCount, List<String>? blessings, String? fulfillText}) => WishCapsule(
        id: id,
        wishText: wishText,
        createdAt: createdAt,
        dueDate: dueDate,
        category: category,
        status: s ?? status,
        lights: lights ?? this.lights,
        blessingCount: blessingCount ?? this.blessingCount,
        blessings: blessings ?? this.blessings,
        fulfillText: fulfillText ?? this.fulfillText,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'wishText': wishText,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'category': category,
        'status': status.name,
        'lights': lights,
        'blessingCount': blessingCount,
        'blessings': blessings,
        'fulfillText': fulfillText,
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
        lights: json['lights'] as int? ?? 0,
        blessingCount: json['blessingCount'] as int? ?? 0,
        blessings: (json['blessings'] as List<dynamic>?)?.cast<String>() ?? const [],
        fulfillText: json['fulfillText'] as String?,
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
  final String interpretation;
  final String advice1;
  final int similarCount;
  final int fulfilledCount;

  const Reading({
    required this.hexagram,
    required this.interpretation,
    required this.advice1,
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
  final int freeOracleUsed;      // 今日已用免费算卦次数
  final int freeFateDrawUsed;    // 今日已用免费祈福签次数
  final List<WishCapsule> capsules;
  final int fishedCount;
  final Map<String, int> extraLights;
  final String lastResetDate; // YYYY-MM-DD
  final List<KouBadge> badges;
  final String userId;
  final String nickname; // 用户昵称

  const AppState({
    this.throwLimit = 3,
    this.fishLimit = 5,
    this.totalFished = 0,
    this.myWishes = const [],
    this.totalWishes = 8347,
    this.litWishes = const {},
    this.meritPoints = 0,
    this.freeReadingUsed = false,
    this.freeOracleUsed = 0,
    this.freeFateDrawUsed = 0,
    this.capsules = const [],
    this.fishedCount = 0,
    this.extraLights = const {},
    this.lastResetDate = '',
    this.badges = const [],
    this.userId = '',
    this.nickname = '',
  });

  /// 祝福等级 - 线性增长，每级+100祝福
  /// Lv1: 0-99, Lv2: 100-199, Lv3: 200-299, Lv4: 300-399, Lv5: 400-499
  /// Lv6: 500-599, Lv7: 600-699, Lv8: 700-799, Lv9: 800-899, Lv10+: 900+
  int get meritLevel {
    final total = blessingCount;
    if (total >= 900) return 10 + (total - 900) ~/ 100;
    return (total ~/ 100) + 1;
  }

  /// 等级福利 - 返回当前等级的特权
  LevelBenefits get levelBenefits => LevelBenefits.forLevel(meritLevel);

  /// 当前等级进度 (0.0 - 1.0)
  double get meritProgress {
    final total = blessingCount;
    final level = meritLevel;
    final current = (level - 1) * 100;
    final next = level * 100;
    return ((total - current) / (next - current)).clamp(0.0, 1.0);
  }

  /// 升到下一级需要的祝福数
  int get meritToNextLevel {
    final total = blessingCount;
    final level = meritLevel;
    final nextThreshold = level * 100;
    return nextThreshold - total;
  }

  /// 祝福数计算公式：
  /// 法物购买获得的祝福值 + 还愿获得的祝福值 + 收到祝福文字的总和
  /// meritPoints 只包含法物购买 + 还愿
  /// 收到祝福文字 = 所有心愿胶囊的 blessingCount 总和
  int get blessingCount {
    final capsuleBlessings = capsules.fold<int>(0, (sum, c) => sum + c.blessingCount);
    return meritPoints + capsuleBlessings;
  }

  /// Check if daily limits need reset (new day)
  AppState checkDailyReset() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastResetDate != today) {
      final benefits = levelBenefits;
      return copyWith(
        throwLimit: benefits.dailyThrowLimit,
        fishLimit: benefits.dailyFishLimit,
        freeReadingUsed: false,
        freeOracleUsed: 0,
        freeFateDrawUsed: 0,
        lastResetDate: today,
      );
    }
    return this;
  }

  /// Evaluate and unlock earned badges
  AppState evaluateBadges() {
    final updated = <KouBadge>[];
    for (final b in allBadgeDefs) {
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

  static const allBadgeDefs = <KouBadge>[
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
    int? freeOracleUsed,
    int? freeFateDrawUsed,
    List<WishCapsule>? capsules,
    int? fishedCount,
    Map<String, int>? extraLights,
    String? lastResetDate,
    List<KouBadge>? badges,
    String? userId,
    String? nickname,
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
        nickname: nickname ?? this.nickname,
        freeReadingUsed: freeReadingUsed ?? this.freeReadingUsed,
        freeOracleUsed: freeOracleUsed ?? this.freeOracleUsed,
        freeFateDrawUsed: freeFateDrawUsed ?? this.freeFateDrawUsed,
        capsules: capsules ?? this.capsules,
        fishedCount: fishedCount ?? this.fishedCount,
        extraLights: extraLights ?? this.extraLights,
        lastResetDate: lastResetDate ?? this.lastResetDate,
        badges: badges ?? this.badges,
      );
}

/// 等级福利系统 - 升级增加许愿和祈福签免费次数
class LevelBenefits {
  final int dailyThrowLimit;      // 每日投愿次数
  final int dailyFishLimit;       // 每日捞愿次数
  final int freeOracleCount;      // 免费算卦次数
  final int freeFateDrawCount;    // 免费天命签次数
  final String title;             // 称号

  const LevelBenefits({
    this.dailyThrowLimit = 3,
    this.dailyFishLimit = 5,
    this.freeOracleCount = 0,
    this.freeFateDrawCount = 0,
    this.title = '寻光者',
  });

  /// 升级规则：每升1级，许愿+1次，捞愿+1次
  /// 每升2级，免费算卦+1次
  /// 每升3级，免费天命签+1次
  factory LevelBenefits.forLevel(int level) {
    // 基础值 + 等级增量
    final throwLimit = 3 + level;           // Lv1=4, Lv2=5, Lv3=6...
    final fishLimit = 5 + level;            // Lv1=6, Lv2=7, Lv3=8...
    final oracleCount = level ~/ 2;         // Lv1=0, Lv2=1, Lv3=1, Lv4=2...
    final fateDrawCount = level ~/ 3;       // Lv1=0, Lv2=0, Lv3=1, Lv4=1...

    // 每级都有独特称号
    final titles = [
      '寻光者',      // Lv1
      '修行者',      // Lv2
      '悟道者',      // Lv3
      '护法',        // Lv4
      '长老',        // Lv5
      '尊者',        // Lv6
      '圣者',        // Lv7
      '半仙',        // Lv8
      '天命之人',    // Lv9
      '化境',        // Lv10
    ];
    String title;
    if (level >= 1 && level <= 10) {
      title = titles[level - 1];
    } else if (level > 10) {
      title = '化境';
    } else {
      title = '寻光者';
    }

    return LevelBenefits(
      dailyThrowLimit: throwLimit,
      dailyFishLimit: fishLimit,
      freeOracleCount: oracleCount,
      freeFateDrawCount: fateDrawCount,
      title: title,
    );
  }

  String get benefitsText {
    final parts = <String>[
      '每日许愿 $dailyThrowLimit 次',
      '每日捞愿 $dailyFishLimit 次',
      if (freeOracleCount > 0) '免费算卦 $freeOracleCount 次',
      if (freeFateDrawCount > 0) '免费祈福签 $freeFateDrawCount 次',
    ];
    return parts.join(' · ');
  }
}
