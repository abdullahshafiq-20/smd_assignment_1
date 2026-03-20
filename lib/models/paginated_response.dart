import 'todo.dart';

class PaginatedResponse {
  final List<Todo> todos;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  const PaginatedResponse({
    required this.todos,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawList =
        json['todos'] as List<dynamic>? ?? json['data'] as List<dynamic>? ?? [];
    final todos = rawList
        .map((e) => Todo.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = json['total'] as int? ?? todos.length;
    final page = json['page'] as int? ?? 1;
    final limit = json['limit'] as int? ?? 10;
    return PaginatedResponse(
      todos: todos,
      total: total,
      page: page,
      limit: limit,
      hasMore: (page * limit) < total,
    );
  }
}
