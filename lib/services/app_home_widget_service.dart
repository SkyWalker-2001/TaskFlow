import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';

import '../models/task_model.dart';

class AppHomeWidgetService {
  static const String _androidWidgetName = 'TaskflowWidgetProvider';
  static const String _iosWidgetName = 'TaskflowWidget';
  static const String _iOSAppGroupId = 'group.com.example.taskflow';

  Future<void> initialize() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await HomeWidget.setAppGroupId(_iOSAppGroupId);
      } catch (_) {
        // iOS widget extension may not be configured yet.
      }
    }
  }

  Future<void> syncFromGroup(TaskGroup group) async {
    final activeTasks = group.tasks.where((task) => !task.isCompleted).toList();
    final orderedTasks = <TaskItem>[
      ...activeTasks,
      ...group.tasks.where((task) => task.isCompleted),
    ];
    final taskLines = orderedTasks.map((task) {
      final title = task.title.trim().isEmpty
          ? 'Untitled task'
          : task.title.trim();
      return '${task.isCompleted ? '✓' : '○'} $title';
    }).toList();
    final taskText = taskLines.isEmpty
        ? 'No tasks in this list'
        : taskLines.join('\n');

    try {
      await HomeWidget.saveWidgetData<String>('widget_list_name', group.name);
      await HomeWidget.saveWidgetData<int>('widget_total', group.tasks.length);
      await HomeWidget.saveWidgetData<int>('widget_done', group.completedCount);
      await HomeWidget.saveWidgetData<int>('widget_active', activeTasks.length);
      await HomeWidget.saveWidgetData<String>('widget_tasks_text', taskText);
      await HomeWidget.saveWidgetData<String>(
        'widget_tasks_json',
        jsonEncode(taskLines),
      );

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
    } catch (_) {
      // Keep app flow stable if platform widget is not fully configured.
    }
  }
}
