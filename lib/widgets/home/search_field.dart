import 'package:flutter/material.dart';

class TaskSearchField extends StatelessWidget {
  const TaskSearchField({
    super.key,
    required this.controller,
    required this.hasQuery,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search tasks or notes',
          prefixIcon: const Icon(Icons.search_rounded, size: 30),
          suffixIcon: hasQuery
              ? IconButton(onPressed: onClear, icon: const Icon(Icons.close))
              : null,
        ),
      ),
    );
  }
}
