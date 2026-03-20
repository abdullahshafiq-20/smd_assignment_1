class Todo {
  final int id;
  final String title;
  final String description;
  final bool completed;
  final DateTime createdAt;

  const Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.createdAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ??
          json['body'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(
              (json['id'] as int) * 1000,
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
      };

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? completed,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
