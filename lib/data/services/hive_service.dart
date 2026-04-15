import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  static const String _statsBox = 'stats';
  static const String _achievementsBox = 'achievements';

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    Hive.init(dir.path);
    await Hive.openBox(_statsBox);
    await Hive.openBox(_achievementsBox);
  }

  // ─── Runs ───────────────────────────────────────────────

  Future<void> saveRun({
    required int totalScore,
    required int itemsFound,
    required int totalItems,
    required int avgTimeSeconds,
    required String mode,
    required String category,
  }) async {
    final box = Hive.box(_statsBox);
    final runs = List<Map>.from(box.get('runs', defaultValue: []));
    runs.add({
      'totalScore': totalScore,
      'itemsFound': itemsFound,
      'totalItems': totalItems,
      'avgTime': avgTimeSeconds,
      'mode': mode,
      'category': category,
      'date': DateTime.now().toIso8601String(),
    });
    await box.put('runs', runs);
    await _updateBests(
      score: totalScore,
      avgTime: avgTimeSeconds,
      itemsFound: itemsFound,
      totalItems: totalItems,
    );
  }

  Future<void> _updateBests({
    required int score,
    required int avgTime,
    required int itemsFound,
    required int totalItems,
  }) async {
    final box = Hive.box(_statsBox);
    if (score > getBestScore()) await box.put('bestScore', score);
    if (avgTime < getBestAvgTime()) await box.put('bestAvgTime', avgTime);
  }

  List<Map> getRuns() {
    return List<Map>.from(
      Hive.box(_statsBox).get('runs', defaultValue: []),
    );
  }

  int getBestScore() =>
      Hive.box(_statsBox).get('bestScore', defaultValue: 0);

  int getBestAvgTime() =>
      Hive.box(_statsBox).get('bestAvgTime', defaultValue: 9999);

  int getTotalRuns() => getRuns().length;

  double getSuccessRate() {
    final runs = getRuns();
    if (runs.isEmpty) return 0;
    final totalFound = runs.fold<int>(0, (sum, r) => sum + (r['itemsFound'] as int));
    final totalItems = runs.fold<int>(0, (sum, r) => sum + (r['totalItems'] as int));
    if (totalItems == 0) return 0;
    return (totalFound / totalItems) * 100;
  }

  Map<String, dynamic>? getBestRun() {
    final runs = getRuns();
    if (runs.isEmpty) return null;
    runs.sort((a, b) => (b['totalScore'] as int).compareTo(a['totalScore'] as int));
    return Map<String, dynamic>.from(runs.first);
  }

  // ─── Achievements ────────────────────────────────────────

  Future<void> unlockAchievement(String id) async {
    final box = Hive.box(_achievementsBox);
    final unlocked = List<String>.from(box.get('unlocked', defaultValue: []));
    if (!unlocked.contains(id)) {
      unlocked.add(id);
      await box.put('unlocked', unlocked);
    }
  }

  bool isUnlocked(String id) {
    final box = Hive.box(_achievementsBox);
    return List<String>.from(
      box.get('unlocked', defaultValue: []),
    ).contains(id);
  }

  List<String> getUnlocked() {
    return List<String>.from(
      Hive.box(_achievementsBox).get('unlocked', defaultValue: []),
    );
  }

  Future<void> checkAndUnlockAchievements({
    required int totalScore,
    required int itemsFound,
    required int totalItems,
    required int avgTime,
    required bool usedHint,
  }) async {
    if (avgTime <= 5) await unlockAchievement('speed_5s');
    if (totalScore >= 1000 * totalItems) await unlockAchievement('perfect_score');
    if (itemsFound == totalItems && !usedHint) await unlockAchievement('no_hint_10');
    if (itemsFound == totalItems) await unlockAchievement('veteran_100');
  }
}