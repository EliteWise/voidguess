class Item {
  final int id;
  final String name;
  final int year;
  final int difficulty;
  final String hint;
  final String category; // 'game', 'movie'

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
      name: json['name'] as String,
      year: json['year'] as int,
      difficulty: json['difficulty'] as int,
      hint: json['hint'] as String,
      category: json['category'] as String,
    );
  }
}