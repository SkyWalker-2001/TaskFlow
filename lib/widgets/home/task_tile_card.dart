import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task_model.dart';

class TaskTileCard extends StatelessWidget {
  const TaskTileCard({
    super.key,
    required this.task,
    required this.priorityLabel,
    required this.priorityColor,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onClearDueDate,
  });

  final TaskItem task;
  final String priorityLabel;
  final Color priorityColor;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onClearDueDate;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: task.isCompleted
              ? Colors.white.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.92),
          border: Border.all(
            color: task.isCompleted
                ? const Color(0xFFDEE3D7)
                : const Color(0xFFD2D9CB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          leading: Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            value: task.isCompleted,
            onChanged: (_) => onToggle(),
          ),
          title: Text(
            task.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              decoration: task.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: task.isCompleted ? const Color(0xFF6E756B) : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.notes.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    task.notes.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4E5E54),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _TaskMetaPill(
                    icon: Icons.flag_rounded,
                    label: priorityLabel,
                    color: priorityColor,
                  ),
                  if (task.dueDate != null)
                    _TaskMetaPill(
                      icon: task.isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.calendar_today,
                      label: DateFormat('MMM d, yyyy').format(task.dueDate!),
                      color: task.isOverdue
                          ? Colors.red.shade600
                          : const Color(0xFF2A63A8),
                    ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
                return;
              }
              if (value == 'delete') {
                onDelete();
                return;
              }
              if (value == 'due_clear') {
                onClearDueDate();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
              if (task.dueDate != null)
                const PopupMenuItem(
                  value: 'due_clear',
                  child: Text('Clear due date'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskMetaPill extends StatelessWidget {
  const _TaskMetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
