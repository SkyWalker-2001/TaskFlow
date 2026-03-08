import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_model.dart';

class TaskStorage {
  static const _storageKeyPrefix = 'taskflow.db.v1';

  String _storageKey(String userId) => '$_storageKeyPrefix.$userId';

  Future<TaskDatabase> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey(userId));

    if (data == null || data.isEmpty) {
      return TaskDatabase.createDefault();
    }

    try {
      final parsed = TaskDatabase.fromJson(data);
      if (parsed.groups.isEmpty) {
        return TaskDatabase.createDefault();
      }
      return parsed;
    } catch (_) {
      return TaskDatabase.createDefault();
    }
  }

  Future<void> save(String userId, TaskDatabase database) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(userId), database.toJson());
  }
}
