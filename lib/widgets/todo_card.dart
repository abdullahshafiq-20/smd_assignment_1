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
