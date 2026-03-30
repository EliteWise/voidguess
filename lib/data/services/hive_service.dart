import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _statsBox = 'stats';
  static const String _achievementsBox = 'achievements';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_statsBox);
    await Hive.openBox(_achievementsBox);
  }

  // Stats
  Future<void> saveStats({
    required int score,
    required int timeSeconds,
    required bool usedHint,
    required String category,
  }) async {
    final box = Hive.box(_statsBox);
    final history = List<Map>.from(box.get('history', defaultValue: []));
    history.add({
      'score': score,
      'time': timeSeconds,
      'usedHint': usedHint,
      'category': category,
      'date': DateTime.now().toIso8601String(),
    });
    await box.put('history', history);
    await _updateBests(score: score, timeSeconds: timeSeconds);
  }

  Future<void> _updateBests({required int score, required int timeSeconds}) async {
    final box = Hive.box(_statsBox);
    final bestScore = box.get('bestScore', defaultValue: 0);
    final bestTime = box.get('bestTime', defaultValue: 9999);
    if (score > bestScore) await box.put('bestScore', score);
    if (timeSeconds < bestTime) await box.put('bestTime', timeSeconds);
  }

  int getBestScore() => Hive.box(_statsBox).get('bestScore', defaultValue: 0);
  int getBestTime() => Hive.box(_statsBox).get('bestTime', defaultValue: 9999);
  List getHistory() => Hive.box(_statsBox).get('history', defaultValue: []);

  // Achievements
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
    final unlocked = List<String>.from(box.get('unlocked', defaultValue: []));
    return unlocked.contains(id);
  }

  List<String> getUnlocked() {
    final box = Hive.box(_achievementsBox);
    return List<String>.from(box.get('unlocked', defaultValue: []));
  }
}