import 'package:flutter/material.dart';

import '../../models/task_model.dart';

class TaskFilterChips extends StatelessWidget {
  const TaskFilterChips({
    super.key,
    required this.activeFilter,
    required this.onChanged,
    required this.labelBuilder,
  });

  final TaskFilter activeFilter;
  final ValueChanged<TaskFilter> onChanged;
  final String Function(TaskFilter filter) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TaskFilter.values.map((filter) {
          final selected = activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: selected
                  ? const Icon(Icons.check_rounded, size: 18)
                  : null,
              label: Text(
                labelBuilder(filter),
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: selected,
              onSelected: (_) => onChanged(filter),
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              selectedColor: const Color(0xFF0C6B58).withValues(alpha: 0.18),
              side: BorderSide(
                color: selected
                    ? const Color(0xFF0C6B58)
                    : const Color(0xFFD2D8CA),
              ),
              showCheckmark: false,
              visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
