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
