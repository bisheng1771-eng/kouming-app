import 'package:flutter_test/flutter_test.dart';
import 'package:kouming/shared/models/kouming_models.dart';

void main() {
  group('AppState', () {
    test('initial state has correct defaults', () {
      const state = AppState();
      
      expect(state.myWishes, isEmpty);
      expect(state.capsules, isEmpty);
      expect(state.meritPoints, 0);
      expect(state.throwLimit, 3);
      expect(state.fishLimit, 5);
      expect(state.totalWishes, 8347); // Global counter starts with fake data
      expect(state.litWishes, isEmpty);
      expect(state.badges, isEmpty);
      expect(state.freeReadingUsed, false);
    });

    test('copyWith preserves unchanged values', () {
      final capsule = WishCapsule(
        id: 'test-1',
        wishText: 'Test wish',
        category: 'study',
        createdAt: DateTime(2026, 1, 1),
        dueDate: DateTime(2027, 1, 1),
      );
      
      const state = AppState(
        meritPoints: 10,
        throwLimit: 2,
        fishLimit: 4,
      );
      
      final newState = state.copyWith(
        capsules: [capsule],
      );
      
      expect(newState.meritPoints, 10);
      expect(newState.throwLimit, 2);
      expect(newState.fishLimit, 4);
      expect(newState.capsules.length, 1);
      expect(newState.capsules.first.wishText, 'Test wish');
    });

    test('checkDailyReset resets limits on new day', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final state = AppState(
        lastResetDate: yesterday.toIso8601String().substring(0, 10),
        throwLimit: 0,
        fishLimit: 0,
        freeReadingUsed: true,
      );
      
      final newState = state.checkDailyReset();
      
      expect(newState.throwLimit, 3);
      expect(newState.fishLimit, 5);
      expect(newState.freeReadingUsed, false);
      expect(newState.lastResetDate, DateTime.now().toIso8601String().substring(0, 10));
    });

    test('checkDailyReset preserves limits on same day', () {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final state = AppState(
        lastResetDate: today,
        throwLimit: 2,
        fishLimit: 4,
      );
      
      final newState = state.checkDailyReset();
      
      expect(newState.throwLimit, 2);
      expect(newState.fishLimit, 4);
    });
  });

  group('KouBadge', () {
    test('badge can be created with earned status', () {
      const badge = KouBadge(
        id: 'test_badge',
        label: '测试徽章',
        emoji: '🏆',
        isMerit: false,
        earned: true,
      );
      
      expect(badge.id, 'test_badge');
      expect(badge.earned, isTrue);
    });

    test('copyWith can update earned status', () {
      const badge = KouBadge(
        id: 'merit_5',
        label: '修行者',
        emoji: '⭐',
        isMerit: true,
        earned: false,
      );
      
      final updated = badge.copyWith(earned: true);
      
      expect(updated.earned, isTrue);
      expect(updated.id, 'merit_5');
    });
  });

  group('Badge Evaluation', () {
    test('first_wish badge unlocks with first wish', () {
      final wish = Wish(
        id: 'w1',
        text: 'Test wish',
        category: 'study',
        createdAt: DateTime.now(),
      );
      
      final state = AppState(myWishes: [wish]);
      final evaluated = state.evaluateBadges();
      
      final firstWishBadge = evaluated.badges.firstWhere((b) => b.id == 'first_wish');
      expect(firstWishBadge.earned, isTrue);
    });

    test('throw_10 badge requires 10 wishes', () {
      // 9 wishes - should not earn
      final wishes9 = List.generate(9, (i) => Wish(
        id: 'w$i',
        text: 'Wish $i',
        category: 'study',
        createdAt: DateTime.now(),
      ));
      
      final state9 = AppState(myWishes: wishes9);
      final evaluated9 = state9.evaluateBadges();
      
      final throw10Badge = evaluated9.badges.firstWhere((b) => b.id == 'throw_10');
      expect(throw10Badge.earned, isFalse);
      
      // 10 wishes - should earn
      final wishes10 = [...wishes9, Wish(id: 'w9', text: 'Wish 10', category: 'study', createdAt: DateTime.now())];
      final state10 = AppState(myWishes: wishes10);
      final evaluated10 = state10.evaluateBadges();
      
      final throw10BadgeEarned = evaluated10.badges.firstWhere((b) => b.id == 'throw_10');
      expect(throw10BadgeEarned.earned, isTrue);
    });

    test('merit_5 badge unlocks at meritLevel 5', () {
      // Level is meritPoints ~/ 15 + 1, so 60 points = level 5
      const state = AppState(meritPoints: 60);
      
      expect(state.meritLevel, 5);
      
      final evaluated = state.evaluateBadges();
      final merit5Badge = evaluated.badges.firstWhere((b) => b.id == 'merit_5');
      expect(merit5Badge.earned, isTrue);
    });

    test('fish_1 badge unlocks with first catch', () {
      const state = AppState(fishedCount: 1);
      final evaluated = state.evaluateBadges();
      
      final fish1Badge = evaluated.badges.firstWhere((b) => b.id == 'fish_1');
      expect(fish1Badge.earned, isTrue);
    });
  });

  group('Wish', () {
    test('wish can be created with all fields', () {
      final wish = Wish(
        id: 'w1',
        text: '考试顺利通过',
        category: 'study',
        createdAt: DateTime(2026, 4, 24),
        lights: 10,
        isMine: true,
      );
      
      expect(wish.id, 'w1');
      expect(wish.text, '考试顺利通过');
      expect(wish.category, 'study');
      expect(wish.lights, 10);
      expect(wish.isMine, isTrue);
    });

    test('wish toJson and fromJson are symmetric', () {
      final wish = Wish(
        id: 'wish-test',
        text: '身体健康',
        category: 'health',
        createdAt: DateTime(2026, 3, 15),
        lights: 3,
        isMine: false,
      );
      
      final json = wish.toJson();
      final restored = Wish.fromJson(json);
      
      expect(restored.id, 'wish-test');
      expect(restored.text, '身体健康');
      expect(restored.category, 'health');
      expect(restored.lights, 3);
      expect(restored.isMine, isFalse);
    });

    test('wish copyWith updates lights', () {
      final wish = Wish(
        id: 'w1',
        text: 'Test',
        category: 'study',
        createdAt: DateTime.now(),
        lights: 5,
      );
      
      final updated = wish.copyWith(lights: 10);
      
      expect(updated.lights, 10);
      expect(updated.id, 'w1');
      expect(updated.text, 'Test');
    });
  });

  group('WishCapsule', () {
    test('capsule has correct waiting status', () {
      final capsule = WishCapsule(
        id: 'cap-1',
        wishText: '测试愿望',
        category: 'study',
        createdAt: DateTime(2026, 1, 1),
        dueDate: DateTime(2027, 1, 1),
        status: CapsuleStatus.waiting,
      );
      
      expect(capsule.status, CapsuleStatus.waiting);
      expect(capsule.canFulfill, isFalse);
    });

    test('capsule canFulfill when dueDate passed', () {
      final capsule = WishCapsule(
        id: 'cap-1',
        wishText: '测试愿望',
        category: 'study',
        createdAt: DateTime(2025, 1, 1),
        dueDate: DateTime(2026, 1, 1),
        status: CapsuleStatus.waiting,
      );
      
      expect(capsule.canFulfill, isTrue);
    });

    test('capsule toJson and fromJson are symmetric', () {
      final capsule = WishCapsule(
        id: 'cap-json',
        wishText: '愿望内容',
        category: 'love',
        createdAt: DateTime(2026, 2, 14),
        dueDate: DateTime(2026, 8, 14),
        status: CapsuleStatus.fulfilled,
      );
      
      final json = capsule.toJson();
      final restored = WishCapsule.fromJson(json);
      
      expect(restored.id, 'cap-json');
      expect(restored.wishText, '愿望内容');
      expect(restored.category, 'love');
      expect(restored.status, CapsuleStatus.fulfilled);
    });

    test('daysLeft calculates correctly', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final capsule = WishCapsule(
        id: 'cap-days',
        wishText: '未来愿望',
        category: 'money',
        createdAt: DateTime.now(),
        dueDate: futureDate,
      );
      
      expect(capsule.daysLeft, closeTo(30, 1));
    });
  });

  group('Merit Level', () {
    test('meritLevel returns correct tier for points', () {
      // Level formula: meritPoints ~/ 15 + 1
      const state0 = AppState(meritPoints: 0);
      const state14 = AppState(meritPoints: 14);
      const state15 = AppState(meritPoints: 15);
      const state150 = AppState(meritPoints: 150);
      
      expect(state0.meritLevel, 1);  // 0/15 = 0, +1 = 1
      expect(state14.meritLevel, 1); // 14/15 = 0, +1 = 1
      expect(state15.meritLevel, 2); // 15/15 = 1, +1 = 2
      expect(state150.meritLevel, 11); // 150/15 = 10, +1 = 11
    });

    test('meritProgress returns fraction toward next level', () {
      // Progress formula: (meritPoints % 15) / 15
      const state5 = AppState(meritPoints: 5);
      const state15 = AppState(meritPoints: 15);
      
      expect(state5.meritProgress, closeTo(5/15, 0.01));
      expect(state15.meritProgress, closeTo(0, 0.01));
    });
  });

  group('Offering', () {
    test('offering has correct properties', () {
      const offering = Offering(
        name: '线香',
        priceYuan: 1,
        emoji: '🕯️',
        meritReward: 5,
      );
      
      expect(offering.name, '线香');
      expect(offering.priceYuan, 1);
      expect(offering.emoji, '🕯️');
      expect(offering.meritReward, 5);
    });
  });

  group('FortuneLevel', () {
    test('fortune levels are ordered', () {
      expect(FortuneLevel.values.length, 5);
      expect(FortuneLevel.supreme.index < FortuneLevel.great.index, isTrue);
      expect(FortuneLevel.great.index < FortuneLevel.medium.index, isTrue);
      expect(FortuneLevel.medium.index < FortuneLevel.low.index, isTrue);
      expect(FortuneLevel.low.index < FortuneLevel.bad.index, isTrue);
    });
  });
}
