import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/achievement.dart';

class AchievementRepository {
  List<Achievement>? _cache;

  Future<List<Achievement>> getAchievements() async {
    if (_cache != null) return _cache!;
    final String json = await rootBundle.loadString('assets/data/achievements.json');
    final List<dynamic> data = jsonDecode(json);
    _cache = data.map((e) => Achievement.fromJson(e)).toList();
    return _cache!;
  }

  Future<List<Achievement>> getByCategory(String category) async {
    final all = await getAchievements();
    return all.where((a) => a.category == category).toList();
  }
}