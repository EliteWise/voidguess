import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:voidguess/data/services/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HiveService hiveService;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => Directory.systemTemp.path,
        );
    hiveService = HiveService();
    await hiveService.init();
  });

  tearDown(() async => await Hive.deleteFromDisk());

  group('VP ranking system', () {
    test('VP should increase after a successful run', () async {
      final before = hiveService.getVPInCurrentRank();
      await hiveService.updateRank(1000, false);
      final after = hiveService.getVPInCurrentRank();
      expect(after, greaterThan(before));
    });

    test(
      'flag ranked updates promote at 10 VP and clamp losses at Void',
      () async {
        await Hive.box('stats').put('currentVP', 9);
        await Hive.box('stats').put('rankIndex', 0);

        final gained = await hiveService.updateFlagRank(
          correctCount: 10,
          totalItems: 10,
        );

        expect(gained, 1);
        expect(hiveService.getCurrentVP(), 10);
        expect(hiveService.getCurrentRankName(), 'Bronze');

        await hiveService.resetRank();
        final lost = await hiveService.updateFlagRank(
          correctCount: 0,
          totalItems: 10,
        );

        expect(lost, -1);
        expect(hiveService.getCurrentVP(), 0);
        expect(hiveService.getCurrentRankName(), 'Void');
      },
    );
  });

  group('run counters', () {
    test('total runs should include every game mode', () async {
      await hiveService.saveRun(
        totalScore: 100,
        itemsFound: 1,
        totalItems: 1,
        avgTimeSeconds: 5,
        mode: 'classic',
        category: 'game',
        itemResults: const [],
      );
      await hiveService.saveFlagRun(
        totalScore: 200,
        correctCount: 2,
        totalItems: 2,
        avgTimeSeconds: 4,
        results: const [],
      );
      await hiveService.saveSpaceRun(
        totalScore: 300,
        totalItems: 3,
        avgTimeSeconds: 6,
        avgDifferenceMillionKm: 12,
        results: const [],
      );
      await hiveService.saveGemstoneRun(
        totalScore: 400,
        correctCount: 4,
        totalItems: 4,
        avgTimeSeconds: 3,
        results: const [],
      );

      expect(hiveService.getTotalRuns(), 4);
    });
  });
}
