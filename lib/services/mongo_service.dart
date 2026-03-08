import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../models/task_model.dart';

class MongoService {
  MongoService();

  static const String _mongoUri = String.fromEnvironment(
    'MONGO_URI',
    defaultValue:
        'mongodb+srv://gagansingh:gagansingh@taskflowcluster.vjv7yu4.mongodb.net/taskflow?retryWrites=true&w=majority',
  );

  static const String usersCollectionName = 'users';
  static const String tasksCollectionName = 'tasks';
  static const String listsCollectionName = 'task_lists';

  Db? _db;
  DbCollection? _users;
  DbCollection? _tasks;
  DbCollection? _lists;
  String? _lastError;

  String? get lastError => _lastError;

  Future<bool> _ensureConnected() async {
    _lastError = null;
    if (_db != null && _db!.isConnected) {
      return true;
    }

    try {
      _db = await Db.create(_mongoUri);
      await _db!.open();
      _users = _db!.collection(usersCollectionName);
      _tasks = _db!.collection(tasksCollectionName);
      _lists = _db!.collection(listsCollectionName);
      return true;
    } catch (error, stackTrace) {
      _lastError = 'Mongo connect failed. Check MONGO_URI/network access.';
      debugPrint('Mongo connect failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final isReady = await _ensureConnected();
    if (!isReady || _users == null) {
      return null;
    }

    final normalizedEmail = email.trim().toLowerCase();

    try {
      final user = await _users!.findOne(where.eq('email', normalizedEmail));
      return user == null ? null : Map<String, dynamic>.from(user);
    } catch (error, stackTrace) {
      _lastError = 'Failed to query user by email';
      debugPrint('Mongo findUserByEmail failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<bool> createUser({
    required String userId,
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    final isReady = await _ensureConnected();
    if (!isReady || _users == null) {
      return false;
    }

    final normalizedEmail = email.trim().toLowerCase();

    try {
      final existing = await _users!.findOne(
        where.eq('email', normalizedEmail),
      );
      if (existing != null) {
        _lastError = 'Email already exists';
        return false;
      }

      await _users!.insertOne({
        '_id': userId,
        'name': name,
        'email': normalizedEmail,
        'password': passwordHash,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (error, stackTrace) {
      _lastError = 'Failed to create user';
      debugPrint('Mongo createUser failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> updateUserPassword({
    required String email,
    required String passwordHash,
  }) async {
    final isReady = await _ensureConnected();
    if (!isReady || _users == null) {
      return false;
    }

    final normalizedEmail = email.trim().toLowerCase();

    try {
      final result = await _users!.updateOne(
        where.eq('email', normalizedEmail),
        {
          r'$set': {'password': passwordHash},
        },
      );

      if (!result.isSuccess || result.nMatched == 0) {
        _lastError = 'Email not found';
        return false;
      }

      return true;
    } catch (error, stackTrace) {
      _lastError = 'Failed to update password';
      debugPrint('Mongo updateUserPassword failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> upsertList({
    required String userId,
    required TaskGroup group,
  }) async {
    final isReady = await _ensureConnected();
    if (!isReady || _lists == null) {
      return false;
    }

    final payload = {
      'userId': userId,
      'name': group.name,
      'createdAt': group.createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

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

  Future<bool> deleteList({
    required String userId,
    required String groupId,
  }) async {
    final isReady = await _ensureConnected();
    if (!isReady || _lists == null || _tasks == null) {
      return false;
    }

    try {
      await _lists!.deleteOne(where.eq('_id', groupId).eq('userId', userId));
      await _tasks!.deleteMany(
        where.eq('listId', groupId).eq('userId', userId),
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Mongo deleteList failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> upsertTask({
    required String userId,
    required String listId,
    required TaskItem task,
  }) async {
    final isReady = await _ensureConnected();
    if (!isReady || _tasks == null) {
      return false;
    }

    final payload = {
      'userId': userId,
      'listId': listId,
      'title': task.title,
      'notes': task.notes,
      'isCompleted': task.isCompleted,
      'dueDate': task.dueDate?.toIso8601String(),
      'priority': task.priority.name,
      'createdAt': task.createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

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

  Future<bool> deleteTask({
    required String userId,
    required String taskId,
  }) async {
    final isReady = await _ensureConnected();
    if (!isReady || _tasks == null) {
      return false;
    }

    try {
      await _tasks!.deleteOne(where.eq('_id', taskId).eq('userId', userId));
      return true;
    } catch (error, stackTrace) {
      debugPrint('Mongo deleteTask failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<TaskDatabase?> fetchDatabase(String userId) async {
    final isReady = await _ensureConnected();
    if (!isReady || _tasks == null || _lists == null) {
      return null;
    }

    try {
      final listDocs = await _lists!.find(where.eq('userId', userId)).toList();
      final taskDocs = await _tasks!.find(where.eq('userId', userId)).toList();

      if (listDocs.isEmpty && taskDocs.isEmpty) {
        return null;
      }

      final groupsById = <String, TaskGroup>{};

      for (final raw in listDocs) {
        final doc = Map<String, dynamic>.from(raw);
        final listId = doc['_id']?.toString();
        if (listId == null || listId.isEmpty) {
          continue;
        }
        groupsById[listId] = TaskGroup(
          id: listId,
          name: (doc['name'] as String?) ?? 'My Tasks',
          createdAt:
              DateTime.tryParse((doc['createdAt'] as String?) ?? '') ??
              DateTime.now(),
          tasks: [],
        );
      }

      for (final raw in taskDocs) {
        final doc = Map<String, dynamic>.from(raw);
        final listId = doc['listId']?.toString();
        final taskId = doc['_id']?.toString();
        if (listId == null || taskId == null) {
          continue;
        }

        final group = groupsById.putIfAbsent(
          listId,
          () => TaskGroup(
            id: listId,
            name: 'My Tasks',
            createdAt: DateTime.now(),
            tasks: [],
          ),
        );

        group.tasks.add(
          TaskItem(
            id: taskId,
            userId: userId,
            title: (doc['title'] as String?) ?? 'Untitled Task',
            notes: (doc['notes'] as String?) ?? '',
            isCompleted: doc['isCompleted'] == true,
            dueDate: DateTime.tryParse((doc['dueDate'] as String?) ?? ''),
            priority: TaskPriority.values.firstWhere(
              (value) => value.name == doc['priority'],
              orElse: () => TaskPriority.medium,
            ),
            createdAt:
                DateTime.tryParse((doc['createdAt'] as String?) ?? '') ??
                DateTime.now(),
          ),
        );
      }

      final groups = groupsById.values.toList();
      if (groups.isEmpty) {
        return null;
      }

      groups.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return TaskDatabase(groups: groups, selectedGroupId: groups.first.id);
    } catch (error, stackTrace) {
      debugPrint('Mongo fetchDatabase failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}
