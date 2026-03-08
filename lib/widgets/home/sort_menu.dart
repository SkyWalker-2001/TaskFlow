import 'package:flutter/material.dart';

import '../../models/task_model.dart';

class TaskSortMenu extends StatelessWidget {
  const TaskSortMenu({
    super.key,
    required this.activeSort,
    required this.onChanged,
    required this.labelBuilder,
  });

  final TaskSort activeSort;
  final ValueChanged<TaskSort> onChanged;
  final String Function(TaskSort sort) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4DACD)),
      ),
      child: DropdownButton<TaskSort>(
        value: activeSort,
        borderRadius: BorderRadius.circular(14),
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.swap_vert, size: 18),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
        items: TaskSort.values
            .map(
              (sort) => DropdownMenuItem<TaskSort>(
                value: sort,
                child: Text(labelBuilder(sort)),
              ),
            )
            .toList(),
      ),
    );
  }
}
