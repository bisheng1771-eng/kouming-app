import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kouming/shared/models/kouming_models.dart';
import 'package:kouming/shared/theme/kouming_theme.dart';

void main() {
  group('Theme', () {
    test('KouMingTheme has correct colors', () {
      expect(KouMingTheme.deep.value, const Color(0xFF060D1A).value);
      expect(KouMingTheme.gold.value, const Color(0xFFFFD700).value);
      expect(KouMingTheme.spirit.value, const Color(0xFF80DEEA).value);
      expect(KouMingTheme.surface.value, const Color(0xFF132240).value);
      expect(KouMingTheme.purple.value, const Color(0xFFB388FF).value);
      expect(KouMingTheme.text.value, const Color(0xFFC8DDF0).value);
      expect(KouMingTheme.dim.value, const Color(0xFF4A6A8A).value);
    });

    test('KouMingTheme darkTheme is configured correctly', () {
      final theme = KouMingTheme.darkTheme;
      
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, KouMingTheme.deep);
      expect(theme.colorScheme.primary, KouMingTheme.gold);
      expect(theme.colorScheme.secondary, KouMingTheme.purple);
    });
  });

  group('WishCategory', () {
    test('WishCategory has all expected categories', () {
      final categories = WishCategory.values;
      expect(categories.length, 5);
      
      final keys = categories.map((c) => c.key).toList();
      expect(keys, contains('study'));
      expect(keys, contains('health'));
      expect(keys, contains('love'));
      expect(keys, contains('money'));
      expect(keys, contains('default'));
    });

    test('WishCategory labels are correct', () {
      expect(WishCategory.study.label, 'Study');
      expect(WishCategory.love.label, 'Love');
      expect(WishCategory.money.label, 'Money');
      expect(WishCategory.health.label, 'Health');
      expect(WishCategory.other.label, 'Other');
    });

    test('WishCategory fromText detects study keywords', () {
      expect(WishCategory.fromText('I hope to pass my exam'), WishCategory.study);
      expect(WishCategory.fromText('I want a job offer'), WishCategory.study);
      expect(WishCategory.fromText('college admission'), WishCategory.study);
    });

    test('WishCategory fromText detects love keywords', () {
      expect(WishCategory.fromText('I want to find love'), WishCategory.love);
      expect(WishCategory.fromText('my crush likes me back'), WishCategory.love);
      expect(WishCategory.fromText('relationship success'), WishCategory.love);
    });

    test('WishCategory fromText detects money keywords', () {
      expect(WishCategory.fromText('I want to be rich'), WishCategory.money);
      expect(WishCategory.fromText('salary increase'), WishCategory.money);
      expect(WishCategory.fromText('good investment'), WishCategory.money);
    });

    test('WishCategory fromText detects health keywords', () {
      expect(WishCategory.fromText('I want good health'), WishCategory.health);
      expect(WishCategory.fromText('quick recovery from surgery'), WishCategory.health);
      expect(WishCategory.fromText('stay safe'), WishCategory.health);
    });

    test('WishCategory fromText returns other for unknown', () {
      expect(WishCategory.fromText('random text without keywords'), WishCategory.other);
      expect(WishCategory.fromText('hello world'), WishCategory.other);
    });
  });

  group('GlowTier', () {
    test('GlowTier has correct levels', () {
      expect(GlowTier.none.level, 0);
      expect(GlowTier.faint.level, 1);
      expect(GlowTier.bright.level, 2);
      expect(GlowTier.radiant.level, 3);
      expect(GlowTier.miracle.level, 4);
    });

    test('GlowTier has correct emojis', () {
      expect(GlowTier.none.emoji, '');
      expect(GlowTier.faint.emoji.isNotEmpty, isTrue);
      expect(GlowTier.bright.emoji.isNotEmpty, isTrue);
      expect(GlowTier.radiant.emoji.isNotEmpty, isTrue);
      expect(GlowTier.miracle.emoji.isNotEmpty, isTrue);
    });

    test('GlowTier fromLights returns correct tier', () {
      expect(GlowTier.fromLights(0), GlowTier.none);
      expect(GlowTier.fromLights(5), GlowTier.none);
      expect(GlowTier.fromLights(10), GlowTier.faint);
      expect(GlowTier.fromLights(49), GlowTier.faint);
      expect(GlowTier.fromLights(50), GlowTier.bright);
      expect(GlowTier.fromLights(199), GlowTier.bright);
      expect(GlowTier.fromLights(200), GlowTier.radiant);
      expect(GlowTier.fromLights(999), GlowTier.radiant);
      expect(GlowTier.fromLights(1000), GlowTier.miracle);
    });

    test('GlowTier fromLights handles edge cases', () {
      // Exact thresholds
      expect(GlowTier.fromLights(10), GlowTier.faint);
      expect(GlowTier.fromLights(50), GlowTier.bright);
      expect(GlowTier.fromLights(200), GlowTier.radiant);
      expect(GlowTier.fromLights(1000), GlowTier.miracle);
      
      // Just below thresholds
      expect(GlowTier.fromLights(9), GlowTier.none);
      expect(GlowTier.fromLights(49), GlowTier.faint);
      expect(GlowTier.fromLights(199), GlowTier.bright);
      expect(GlowTier.fromLights(999), GlowTier.radiant);
    });
  });

  group('Reading Model', () {
    test('Reading can be created with all fields', () {
      const reading = Reading(
        hexagram: '渐卦',
        element: '风山渐',
        body: '此卦主循序渐进...',
        advice: '宜静待时机',
        similarCount: 237,
        fulfilledCount: 68,
      );
      
      expect(reading.hexagram, '渐卦');
      expect(reading.element, '风山渐');
      expect(reading.similarCount, 237);
      expect(reading.fulfilledCount, 68);
    });
  });

  group('FortuneLevel', () {
    test('FortuneLevel has correct order', () {
      expect(FortuneLevel.values.length, 5);
      expect(FortuneLevel.supreme.index < FortuneLevel.great.index, isTrue);
      expect(FortuneLevel.great.index < FortuneLevel.medium.index, isTrue);
      expect(FortuneLevel.medium.index < FortuneLevel.low.index, isTrue);
      expect(FortuneLevel.low.index < FortuneLevel.bad.index, isTrue);
    });
  });

  group('Offering Model', () {
    test('Offering has correct properties', () {
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

  group('FortuneSlip Model', () {
    test('FortuneSlip can be created', () {
      const slip = FortuneSlip(
        title: '上上签',
        description: '大吉大利',
        emoji: '🌟',
        level: FortuneLevel.supreme,
        element: '金',
        guardian: '财神',
      );
      
      expect(slip.title, '上上签');
      expect(slip.level, FortuneLevel.supreme);
    });
  });
}
