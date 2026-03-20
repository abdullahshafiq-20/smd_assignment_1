#!/bin/bash
# Run this script from inside your Flutter project's /lib directory
# Usage: bash setup.sh

set -e

# ── Directory structure ──────────────────────────────────────────────────────
mkdir -p models services controllers screens widgets

# ════════════════════════════════════════════════════════════════════════════
# models/todo.dart
# ════════════════════════════════════════════════════════════════════════════
cat > models/todo.dart << 'DART'
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
DART

# ════════════════════════════════════════════════════════════════════════════
# models/paginated_response.dart
# ════════════════════════════════════════════════════════════════════════════
cat > models/paginated_response.dart << 'DART'
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
DART

# ════════════════════════════════════════════════════════════════════════════
# services/api_service.dart
# ════════════════════════════════════════════════════════════════════════════
cat > services/api_service.dart << 'DART'
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/todo.dart';

/// JSONPlaceholder is used as the demo backend.
/// /todos returns 200 items – we simulate pagination client-side.
class ApiService {
  static const String _base = 'https://jsonplaceholder.typicode.com';
  static const int pageSize = 10;

  // ── Fetch paginated todos ──────────────────────────────────────────────
  Future<List<Todo>> fetchTodos({required int page}) async {
    final start = (page - 1) * pageSize + 1; // _start param (1-based)
    final uri = Uri.parse(
      '$_base/todos?_page=$page&_limit=$pageSize&_sort=id&_order=desc',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> raw = json.decode(response.body) as List<dynamic>;
      return raw
          .map((e) => Todo.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load todos (${response.statusCode})');
    }
  }

  // ── Add new todo ───────────────────────────────────────────────────────
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

  // ── Toggle completion (PATCH) ──────────────────────────────────────────
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
      return todo; // JSONPlaceholder echoes back; we trust our local model
    } else {
      throw Exception('Failed to update todo (${response.statusCode})');
    }
  }
}
DART

# ════════════════════════════════════════════════════════════════════════════
# controllers/todo_controller.dart
# ════════════════════════════════════════════════════════════════════════════
cat > controllers/todo_controller.dart << 'DART'
import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/api_service.dart';

class TodoController extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ── State ──────────────────────────────────────────────────────────────
  final List<Todo> _todos = [];
  List<Todo> get todos => List.unmodifiable(_todos);

  int _page = 1;
  bool _isLoading = false;
  bool _isPosting = false;
  bool _hasMore = true;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isPosting => _isPosting;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // ── Load / refresh ─────────────────────────────────────────────────────
  Future<void> loadTodos({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    if (refresh) {
      _page = 1;
      _hasMore = true;
      _todos.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _api.fetchTodos(page: _page);
      if (fetched.isEmpty) {
        _hasMore = false;
      } else {
        _todos.addAll(fetched);
        if (fetched.length < ApiService.pageSize) _hasMore = false;
        _page++;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Add ────────────────────────────────────────────────────────────────
  Future<bool> addTodo(String title, String description) async {
    _isPosting = true;
    _error = null;
    notifyListeners();

    try {
      final newTodo = await _api.addTodo(
        title: title,
        description: description,
      );
      _todos.insert(0, newTodo); // most recent at top
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isPosting = false;
      notifyListeners();
    }
  }

  // ── Toggle done ────────────────────────────────────────────────────────
  Future<void> toggleTodo(int id) async {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final updated = _todos[idx].copyWith(completed: !_todos[idx].completed);
    _todos[idx] = updated;
    notifyListeners();

    try {
      await _api.updateTodo(updated);
    } catch (_) {
      // Revert optimistic update
      _todos[idx] = _todos[idx].copyWith(completed: !updated.completed);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
DART

# ════════════════════════════════════════════════════════════════════════════
# widgets/todo_card.dart
# ════════════════════════════════════════════════════════════════════════════
cat > widgets/todo_card.dart << 'DART'
import 'package:flutter/material.dart';
import '../models/todo.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;

  const TodoCard({super.key, required this.todo, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: todo.completed
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              border: Border.all(
                color: todo.completed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                width: 2,
              ),
            ),
            child: todo.completed
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          todo.title,
          style: theme.textTheme.titleSmall?.copyWith(
            decoration:
                todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed
                ? theme.colorScheme.onSurface.withOpacity(0.5)
                : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              todo.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: todo.completed
                    ? theme.colorScheme.onSurface.withOpacity(0.4)
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  todo.completed
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  size: 12,
                  color: todo.completed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  todo.completed ? 'Completed' : 'Pending',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: todo.completed
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            todo.completed ? Icons.undo_rounded : Icons.done_rounded,
            color: todo.completed
                ? theme.colorScheme.secondary
                : theme.colorScheme.primary,
          ),
          tooltip: todo.completed ? 'Mark undone' : 'Mark done',
          onPressed: onToggle,
        ),
      ),
    );
  }
}
DART

# ════════════════════════════════════════════════════════════════════════════
# widgets/add_todo_sheet.dart
# ════════════════════════════════════════════════════════════════════════════
cat > widgets/add_todo_sheet.dart << 'DART'
import 'package:flutter/material.dart';

class AddTodoSheet extends StatefulWidget {
  final bool isPosting;
  final Future<bool> Function(String title, String description) onAdd;

  const AddTodoSheet({
    super.key,
    required this.isPosting,
    required this.onAdd,
  });

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final success =
        await widget.onAdd(_titleCtrl.text.trim(), _descCtrl.text.trim());
    if (mounted) {
      setState(() => _submitting = false);
      if (success) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('New Todo',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter todo title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                if (v.trim().length < 3) return 'At least 3 characters';
                if (v.trim().length > 100) return 'Max 100 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Enter todo description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Description is required';
                }
                if (v.trim().length < 5) return 'At least 5 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: (_submitting || widget.isPosting) ? null : _submit,
              icon: (_submitting || widget.isPosting)
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add_task),
              label: Text(
                  (_submitting || widget.isPosting) ? 'Adding…' : 'Add Todo'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART

# ════════════════════════════════════════════════════════════════════════════
# screens/todo_list_screen.dart
# ════════════════════════════════════════════════════════════════════════════
cat > screens/todo_list_screen.dart << 'DART'
import 'package:flutter/material.dart';
import '../controllers/todo_controller.dart';
import '../widgets/todo_card.dart';
import '../widgets/add_todo_sheet.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TodoController _controller = TodoController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.loadTodos();
    _controller.addListener(_onControllerUpdate);
    _scrollController.addListener(_onScroll);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
    final err = _controller.error;
    if (err != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: Theme.of(context).colorScheme.error,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: _controller.clearError,
              ),
            ),
          );
          _controller.clearError();
        }
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadTodos();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddTodoSheet(
        isPosting: _controller.isPosting,
        onAdd: (title, desc) => _controller.addTodo(title, desc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todos = _controller.todos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Todos'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_controller.isPosting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _controller.loadTodos(refresh: true),
        child: todos.isEmpty && _controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : todos.isEmpty && !_controller.isLoading
                ? ListView(
                    // Needed so pull-to-refresh works even on empty list
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.checklist_rounded,
                                size: 64,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text('No todos yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                )),
                            const SizedBox(height: 6),
                            Text('Tap + to add your first todo',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                                )),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount:
                        todos.length + (_controller.hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == todos.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child:
                              Center(child: CircularProgressIndicator()),
                        );
                      }
                      return TodoCard(
                        todo: todos[i],
                        onToggle: () => _controller.toggleTodo(todos[i].id),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Todo'),
      ),
    );
  }
}
DART

# ════════════════════════════════════════════════════════════════════════════
# main.dart
# ════════════════════════════════════════════════════════════════════════════
cat > main.dart << 'DART'
import 'package:flutter/material.dart';
import 'screens/todo_list_screen.dart';

void main() => runApp(const TodoApp());

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        cardTheme: const CardTheme(surfaceTintColor: Colors.transparent),
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const TodoListScreen(),
    );
  }
}
DART

echo ""
echo "✅  All files created successfully!"
echo ""
echo "File tree:"
find . -type f -name "*.dart" | sort
echo ""
echo "Next steps:"
echo "  1. Make sure 'http' is in your pubspec.yaml dependencies"
echo "  2. Run: flutter pub get"
echo "  3. Run: flutter run"