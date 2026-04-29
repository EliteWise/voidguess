class Item {
  final int id;
  final Map<String, String> name;
  final int year;
  final int difficulty;
  final Map<String, String> hint;
  final String category;

  const Item({
    required this.id,
    required this.name,
    required this.year,
    required this.difficulty,
    required this.hint,
    required this.category,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      name: Map<String, String>.from(json['name'] as Map),
      year: json['year'] as int,
      difficulty: json['difficulty'] as int,
      hint: Map<String, String>.from(json['hint'] as Map),
      category: json['category'] as String,
    );
  }

  String getName(String locale) => name[locale] ?? name['en'] ?? '';
  String getHint(String locale) => hint[locale] ?? hint['en'] ?? '';
}