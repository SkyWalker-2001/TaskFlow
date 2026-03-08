import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart';

import '../models/task_model.dart';

class MongoSyncService {
  MongoSyncService();

  static const String _mongoUri = String.fromEnvironment(
    'MONGO_URI',
    defaultValue:
        'mongodb+srv://gagansingh:gagansingh@taskflowcluster.vjv7yu4.mongodb.net/taskflow?retryWrites=true&w=majority',
  );
  static const String _tasksCollectionName = 'tasks';
  static const String _listsCollectionName = 'task_lists';

  Db? _db;
  DbCollection? _tasks;
  DbCollection? _lists;

  bool get isConfigured => _mongoUri.trim().isNotEmpty;

  Future<bool> _ensureConnected() async {
    if (!isConfigured) {
      return false;
    }

    if (_db != null && _db!.isConnected) {
      return true;
    }

    try {
      _db = await Db.create(_mongoUri);
      await _db!.open();
      _tasks = _db!.collection(_tasksCollectionName);
      _lists = _db!.collection(_listsCollectionName);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Mongo connect failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> upsertList(TaskGroup group) async {
    final isReady = await _ensureConnected();
    if (!isReady || _lists == null) {
      return false;
    }

    final payload = group.toMap()
      ..remove('id')
      ..['updatedAt'] = DateTime.now().toIso8601String();

    try {
      await _lists!.updateOne(where.eq('_id', group.id), {
        r'$set': payload,
      }, upsert: true);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Mongo upsertList failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> deleteList(String groupId) async {
    final isReady = await _ensureConnected();
    if (!isReady || _lists == null || _tasks == null) {
      return false;
    }

    try {
      await _lists!.deleteOne(where.eq('_id', groupId));
      await _tasks!.deleteMany(where.eq('listId', groupId));
      return true;
    } catch (error, stackTrace) {
      debugPrint('Mongo deleteList failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> upsertTask({
    required String listId,
    required TaskItem task,
  }) async {
    final isReady = await _ensureConnected();
    if (!isReady || _tasks == null) {
      return false;
    }

    final payload = task.toMap()
      ..remove('id')
      ..['listId'] = listId
      ..['updatedAt'] = DateTime.now().toIso8601String();

    try {
      await _tasks!.updateOne(where.eq('_id', task.id), {
        r'$set': payload,
      }, upsert: true);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Mongo upsertTask failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    final isReady = await _ensureConnected();
    if (!isReady || _tasks == null) {
      return false;
    }

    try {
      await _tasks!.deleteOne(where.eq('_id', taskId));
      return true;
    } catch (error, stackTrace) {
      debugPrint('Mongo deleteTask failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<TaskDatabase?> fetchDatabase() async {
    final isReady = await _ensureConnected();
    if (!isReady || _tasks == null || _lists == null) {
      return null;
    }

    try {
      final listDocs = await _lists!.find().toList();
      final taskDocs = await _tasks!.find().toList();

      if (listDocs.isEmpty && taskDocs.isEmpty) {
        return null;
      }

      final groupsById = <String, TaskGroup>{};
      for (final raw in listDocs) {
        final doc = Map<String, dynamic>.from(raw);
        final listId = _stringValue(doc['_id']) ?? _stringValue(doc['id']);
        if (listId == null || listId.isEmpty) {
          continue;
        }
        final createdAt = _dateValue(doc['createdAt']) ?? DateTime.now();
        final name = _stringValue(doc['name']) ?? 'My Tasks';
        groupsById[listId] = TaskGroup(
          id: listId,
          name: name,
          createdAt: createdAt,
          tasks: [],
        );
      }

      for (final raw in taskDocs) {
        final doc = Map<String, dynamic>.from(raw);
        final taskId = _stringValue(doc['_id']) ?? _stringValue(doc['id']);
        final listId = _stringValue(doc['listId']);
        if (taskId == null || listId == null) {
          continue;
        }

        final group = groupsById.putIfAbsent(
          listId,
          () => TaskGroup(
            id: listId,
            name: 'Imported',
            createdAt: DateTime.now(),
            tasks: [],
          ),
        );

        group.tasks.add(
          TaskItem(
            id: taskId,
            title: _stringValue(doc['title']) ?? 'Untitled Task',
            notes: _stringValue(doc['notes']) ?? '',
            isCompleted: doc['isCompleted'] == true,
            dueDate: _dateValue(doc['dueDate']),
            priority: _priorityValue(doc['priority']),
            createdAt: _dateValue(doc['createdAt']) ?? DateTime.now(),
          ),
        );
      }

      final groups = groupsById.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (groups.isEmpty) {
        return null;
      }

      final selectedGroupId = groups.first.id;
      return TaskDatabase(groups: groups, selectedGroupId: selectedGroupId);
    } catch (error, stackTrace) {
      debugPrint('Mongo fetchDatabase failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  String? _stringValue(dynamic value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  DateTime? _dateValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  TaskPriority _priorityValue(dynamic value) {
    final input = value?.toString();
    return TaskPriority.values.firstWhere(
      (priority) => priority.name == input,
      orElse: () => TaskPriority.medium,
    );
  }
}
