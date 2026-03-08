import 'package:flutter/material.dart';

class TaskEmptyState extends StatelessWidget {
  const TaskEmptyState({super.key, required this.hasTasks});

  final bool hasTasks;

  @override
  Widget build(BuildContext context) {
    final text = hasTasks
        ? 'No tasks match your current filters'
        : 'No tasks yet. Add your first task.';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDDE3D5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFF0C6B58).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt,
                size: 36,
                color: Color(0xFF0C6B58),
              ),
            ),
            const SizedBox(height: 14),
            Text(text, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
