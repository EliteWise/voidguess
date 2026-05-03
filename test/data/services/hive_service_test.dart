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
  });
}