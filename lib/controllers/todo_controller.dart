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
