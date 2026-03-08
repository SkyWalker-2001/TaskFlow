import 'task_model.dart';

class TaskEditorResult {
  const TaskEditorResult({
    required this.title,
    required this.notes,
    required this.priority,
    required this.dueDate,
  });

  final String title;
  final String notes;
  final TaskPriority priority;
  final DateTime? dueDate;
}
