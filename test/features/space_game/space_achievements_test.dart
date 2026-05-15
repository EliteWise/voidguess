import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:voidguess/data/services/hive_service.dart';

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('voidguess_space_test_');
    Hive.init(hiveDir.path);
    await Hive.openBox('stats');
    await Hive.openBox('achievements');
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('space achievements unlock from a strong space run', () async {
    final hive = HiveService();
    final results = [
      {'differenceMillionKm': 1.5, 'time': 6, 'score': 980},
    ];

    for (var i = 0; i < 50; i++) {
      await hive.saveSpaceRun(
        totalScore: 9200,
        totalItems: 10,
        avgTimeSeconds: 7,
        avgDifferenceMillionKm: 5,
        results: results,
      );
      await hive.checkAndUnlockSpaceAchievements(
        totalScore: 9200,
        totalItems: 10,
        avgTime: 7,
        results: results,
      );
    }

    expect(hive.isUnlocked('first_space_run'), isTrue);
    expect(hive.isUnlocked('space_close_call'), isTrue);
    expect(hive.isUnlocked('space_fast'), isTrue);
    expect(hive.isUnlocked('orbit_master'), isTrue);
    expect(hive.isUnlocked('space_pinpoint'), isTrue);
    expect(hive.isUnlocked('space_grand_tour'), isTrue);
  });

  test('flag achievements unlock from a perfect flag run', () async {
    final hive = HiveService();

    for (var i = 0; i < 50; i++) {
      await hive.saveFlagRun(
        totalScore: 10000,
        correctCount: 10,
        totalItems: 10,
        avgTimeSeconds: 3,
        results: const [],
      );
      await hive.checkAndUnlockFlagAchievements(
        totalScore: 10000,
        correctCount: 10,
        totalItems: 10,
        avgTime: 3,
      );
    }

    expect(hive.isUnlocked('first_flag_run'), isTrue);
    expect(hive.isUnlocked('flag_sharp'), isTrue);
    expect(hive.isUnlocked('flag_clean_sweep'), isTrue);
    expect(hive.isUnlocked('flag_flash'), isTrue);
    expect(hive.isUnlocked('flag_grandmaster'), isTrue);
    expect(hive.isUnlocked('flag_marathon'), isTrue);
  });

  test('gemstone achievements unlock from a perfect gemstone run', () async {
    final hive = HiveService();

    for (var i = 0; i < 50; i++) {
      await hive.saveGemstoneRun(
        totalScore: 10000,
        correctCount: 10,
        totalItems: 10,
        avgTimeSeconds: 3,
        results: const [],
      );
      await hive.checkAndUnlockGemstoneAchievements(
        totalScore: 10000,
        correctCount: 10,
        totalItems: 10,
        avgTime: 3,
      );
    }

    expect(hive.isUnlocked('first_gemstone_run'), isTrue);
    expect(hive.isUnlocked('gemstone_sharp'), isTrue);
    expect(hive.isUnlocked('gemstone_clean_sweep'), isTrue);
    expect(hive.isUnlocked('gemstone_flash'), isTrue);
    expect(hive.isUnlocked('gemstone_veteran'), isTrue);
    expect(hive.isUnlocked('gemstone_grandmaster'), isTrue);
    expect(hive.isUnlocked('gemstone_marathon'), isTrue);
  });
}
