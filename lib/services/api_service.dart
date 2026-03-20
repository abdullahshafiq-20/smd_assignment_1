import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/todo.dart';

class ApiService {
  static const String _base = 'https://jsonplaceholder.typicode.com';
  static const int pageSize = 10;

  Future<List<Todo>> fetchTodos({required int page}) async {
    // Use query params so each call only fetches 10 items
    final uri = Uri.parse('$_base/todos?_page=$page&_limit=$pageSize');

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> raw = json.decode(response.body) as List<dynamic>;
      return raw
          .map((e) => Todo.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load todos (${response.statusCode})');
    }
  }

  Future<Todo> addTodo({
    required String title,
    required String description,
  }) async {
    final uri = Uri.parse('$_base/todos');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'title': title,
            'body': description,
            'completed': false,
            'userId': 1,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 201) {
      final map = json.decode(response.body) as Map<String, dynamic>;
      return Todo(
        id: map['id'] as int,
        title: title,
        description: description,
        completed: false,
        createdAt: DateTime.now(),
      );
    } else {
      throw Exception('Failed to add todo (${response.statusCode})');
    }
  }

  Future<Todo> updateTodo(Todo todo) async {
    final uri = Uri.parse('$_base/todos/${todo.id}');
    final response = await http
        .patch(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'completed': todo.completed}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return todo;
    } else {
      throw Exception('Failed to update todo (${response.statusCode})');
    }
  }
}