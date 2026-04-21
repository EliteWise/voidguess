class Country {
  final int id;
  final Map<String, String> name;
  final String code;
  final int difficulty;

  const Country({
    required this.id,
    required this.name,
    required this.code,
    required this.difficulty,
  });

  factory Country.fromJson(Map<String, dynamic> json) => Country(
    id: json['id'],
    name: Map<String, String>.from(json['name']),
    code: json['code'],
    difficulty: json['difficulty'],
  );

  // Helper pour récupérer le nom dans la bonne langue
  String getName(String locale) => name[locale] ?? name['en'] ?? '';
}