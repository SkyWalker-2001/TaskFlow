import 'package:flutter/material.dart';

import '../../models/task_model.dart';

class ListsDrawer extends StatelessWidget {
  const ListsDrawer({
    super.key,
    required this.groups,
    required this.selectedGroupId,
    required this.onAddList,
    required this.onSelectGroup,
    required this.onRenameGroup,
    required this.onDeleteGroup,
  });

  final List<TaskGroup> groups;
  final String selectedGroupId;
  final VoidCallback onAddList;
  final ValueChanged<TaskGroup> onSelectGroup;
  final ValueChanged<TaskGroup> onRenameGroup;
  final ValueChanged<TaskGroup> onDeleteGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: const Color(0xFFF8F5EC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF135447), Color(0xFF0C6B58)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C6B58).withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset('assets/icons/app_icon.png'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Lists',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${groups.length} lists',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onAddList,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final selected = group.id == selectedGroupId;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF0C6B58)
                            : const Color(0xFFD9DED2),
                      ),
                    ),
                    tileColor: selected
                        ? const Color(0xFF0C6B58).withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.78),
                    selected: selected,
                    title: Text(
                      group.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? const Color(0xFF0C6B58)
                            : const Color(0xFF1C2B21),
                      ),
                    ),
                    subtitle: Text(
                      '${group.completedCount}/${group.tasks.length} complete',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selected
                            ? const Color(0xFF117362)
                            : const Color(0xFF35443A),
                      ),
                    ),
                    onTap: () => onSelectGroup(group),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: selected
                            ? const Color(0xFF0C6B58)
                            : const Color(0xFF23342A),
                      ),
                      onSelected: (value) {
                        if (value == 'rename') {
                          onRenameGroup(group);
                          return;
                        }
                        if (value == 'delete') {
                          onDeleteGroup(group);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
