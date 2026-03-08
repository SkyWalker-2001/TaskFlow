import 'dart:convert';

enum TaskPriority { low, medium, high }

enum TaskFilter { all, active, completed, dueToday, overdue }

enum TaskSort { custom, dueDate, priority, createdAt }

class TaskItem {
  TaskItem({
    required this.id,
    this.userId,
    required this.title,
    this.notes = '',
    this.isCompleted = false,
    this.dueDate,
    this.priority = TaskPriority.medium,
    required this.createdAt,
  });

  final String id;
  String? userId;
  String title;
  String notes;
  bool isCompleted;
  DateTime? dueDate;
  TaskPriority priority;
  final DateTime createdAt;

  bool get isOverdue {
    if (isCompleted || dueDate == null) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return taskDate.isBefore(today);
  }

  bool get isDueToday {
    if (dueDate == null) {
      return false;
    }

    final now = DateTime.now();
    return now.year == dueDate!.year &&
        now.month == dueDate!.month &&
        now.day == dueDate!.day;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'notes': notes,
    'isCompleted': isCompleted,
    'dueDate': dueDate?.toIso8601String(),
    'priority': priority.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] as String,
      userId: map['userId'] as String?,
      title: map['title'] as String,
      notes: map['notes'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      dueDate: map['dueDate'] != null
          ? DateTime.tryParse(map['dueDate'] as String)
          : null,
      priority: TaskPriority.values.firstWhere(
        (value) => value.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class TaskGroup {
  TaskGroup({
    required this.id,
    required this.name,
    required this.createdAt,
    List<TaskItem>? tasks,
  }) : tasks = tasks ?? [];

  final String id;
  String name;
  final DateTime createdAt;
  final List<TaskItem> tasks;

  int get completedCount => tasks.where((task) => task.isCompleted).length;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'tasks': tasks.map((task) => task.toMap()).toList(),
  };

  factory TaskGroup.fromMap(Map<String, dynamic> map) {
    final rawTasks = (map['tasks'] as List<dynamic>? ?? []);

    return TaskGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      tasks: rawTasks
          .whereType<Map<String, dynamic>>()
          .map(TaskItem.fromMap)
          .toList(),
    );
  }
}

class TaskDatabase {
  TaskDatabase({required this.groups, required this.selectedGroupId});

  final List<TaskGroup> groups;
  String selectedGroupId;

  Map<String, dynamic> toMap() => {
    'groups': groups.map((group) => group.toMap()).toList(),
    'selectedGroupId': selectedGroupId,
  };

  String toJson() => jsonEncode(toMap());

  factory TaskDatabase.fromJson(String source) {
    final raw = jsonDecode(source) as Map<String, dynamic>;
    final rawGroups = (raw['groups'] as List<dynamic>? ?? []);
    final groups = rawGroups
        .whereType<Map<String, dynamic>>()
        .map(TaskGroup.fromMap)
        .toList();

    final fallbackId = groups.isEmpty ? '' : groups.first.id;

    return TaskDatabase(
      groups: groups,
      selectedGroupId: raw['selectedGroupId'] as String? ?? fallbackId,
    );
  }

  factory TaskDatabase.createDefault() {
    final now = DateTime.now();
    final group = TaskGroup(
      id: now.microsecondsSinceEpoch.toString(),
      name: 'My Tasks',
      createdAt: now,
    );

    return TaskDatabase(groups: [group], selectedGroupId: group.id);
  }
}
