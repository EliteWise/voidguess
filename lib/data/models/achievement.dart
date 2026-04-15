class Achievement {
  final String id;
  final String title;
  final String description;
  final String category;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
    );
  }
}