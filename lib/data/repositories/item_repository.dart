import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/item.dart';

class ItemRepository {
  List<Item>? _cache;

  Future<List<Item>> getItems() async {
    if (_cache != null) return _cache!;

    final String json = await rootBundle.loadString('assets/data/items.json');
    final List<dynamic> data = jsonDecode(json);
    _cache = data.map((e) => Item.fromJson(e)).toList();
    return _cache!;
  }

  Future<Item> getRandomItem({String? category, int? difficulty}) async {
    final items = await getItems();
    var filtered = items;

    if (category != null) {
      filtered = filtered.where((i) => i.category == category).toList();
    }
    if (difficulty != null) {
      filtered = filtered.where((i) => i.difficulty == difficulty).toList();
    }

    filtered.shuffle();
    return filtered.first;
  }

  // Retourne les noms dans la langue donnée
  Future<List<String>> getItemNames({String? category, required String locale}) async {
    final items = await getItems();
    var filtered = items;
    if (category != null) {
      filtered = filtered.where((i) => i.category == category).toList();
    }
    return filtered.map((i) => i.getName(locale)).toList();
  }

  // Prend un hint string (déjà extrait via item.getHint(locale))
  String getRandomHint(String hintString) {
    final hints = hintString.split(',').map((h) => h.trim()).toList();
    hints.shuffle();
    return hints.first;
  }
}