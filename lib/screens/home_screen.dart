import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_editor_result.dart';
import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../services/app_home_widget_service.dart';
import '../services/mongo_service.dart';
import '../services/task_storage.dart';
import '../widgets/home/dashboard_card.dart';
import '../widgets/home/filter_chips.dart';
import '../widgets/home/home_background.dart';
import '../widgets/home/lists_drawer.dart';
import '../widgets/home/search_field.dart';
import '../widgets/home/sheets/list_name_sheet.dart';
import '../widgets/home/sheets/task_editor_sheet.dart';
import '../widgets/home/sort_menu.dart';
import '../widgets/home/task_empty_state.dart';
import '../widgets/home/task_tile_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskStorage _storage = TaskStorage();
  final AppHomeWidgetService _homeWidgetService = AppHomeWidgetService();
  final MongoService _mongoService = MongoService();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TaskDatabase _database = TaskDatabase.createDefault();
  bool _isLoading = true;
  TaskFilter _activeFilter = TaskFilter.all;
  TaskSort _activeSort = TaskSort.custom;
  String _query = '';
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    unawaited(_homeWidgetService.initialize());
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TaskGroup get _selectedGroup {
    return _database.groups.firstWhere(
      (group) => group.id == _database.selectedGroupId,
      orElse: () => _database.groups.first,
    );
  }

  List<TaskItem> get _visibleTasks {
    final tasks = List<TaskItem>.from(_selectedGroup.tasks);

    final filtered = tasks.where((task) {
      final isMatchingFilter = switch (_activeFilter) {
        TaskFilter.all => true,
        TaskFilter.active => !task.isCompleted,
        TaskFilter.completed => task.isCompleted,
        TaskFilter.dueToday => task.isDueToday,
        TaskFilter.overdue => task.isOverdue,
      };

      final text = '${task.title} ${task.notes}'.toLowerCase();
      final isMatchingQuery = _query.isEmpty || text.contains(_query);

      return isMatchingFilter && isMatchingQuery;
    }).toList();

    if (_activeSort == TaskSort.custom) {
      return filtered;
    }

    filtered.sort((a, b) {
      return switch (_activeSort) {
        TaskSort.custom => 0,
        TaskSort.createdAt => b.createdAt.compareTo(a.createdAt),
        TaskSort.priority => _priorityWeight(
          b.priority,
        ).compareTo(_priorityWeight(a.priority)),
        TaskSort.dueDate => _compareDueDate(a, b),
      };
    });

    return filtered;
  }

  int _priorityWeight(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => 3,
      TaskPriority.medium => 2,
      TaskPriority.low => 1,
    };
  }

  int _compareDueDate(TaskItem a, TaskItem b) {
    if (a.dueDate == null && b.dueDate == null) {
      return 0;
    }
    if (a.dueDate == null) {
      return 1;
    }
    if (b.dueDate == null) {
      return -1;
    }

    return a.dueDate!.compareTo(b.dueDate!);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_activeUserId != user.userId) {
      _activeUserId = user.userId;
      _isLoading = true;
      unawaited(_loadDataForUser(user.userId));
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedGroup = _selectedGroup;
    final visibleTasks = _visibleTasks;
    final completedCount = selectedGroup.completedCount;
    final totalCount = selectedGroup.tasks.length;

    return Scaffold(
      key: _scaffoldKey,
      drawer: ListsDrawer(
        groups: _database.groups,
        selectedGroupId: _database.selectedGroupId,
        onAddList: () => unawaited(_closeDrawerThen(_showAddListDialog)),
        onSelectGroup: (group) {
          unawaited(
            _closeDrawerThen(() async {
              setState(() {
                _database.selectedGroupId = group.id;
              });
              await _persistAndSyncWidget();
            }),
          );
        },
        onRenameGroup: (group) {
          unawaited(_closeDrawerThen(() => _showRenameListDialog(group)));
        },
        onDeleteGroup: (group) {
          unawaited(_closeDrawerThen(() => _deleteList(group)));
        },
      ),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(selectedGroup.name),
        leading: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD7DDD1)),
            ),
            child: const Icon(Icons.menu_rounded),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => unawaited(context.read<AuthProvider>().logout()),
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            tooltip: 'Clear completed tasks',
            onPressed: completedCount == 0 ? null : _clearCompleted,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTaskEditor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add task'),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      body: Stack(
        children: [
          const HomeBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Column(
                    children: [
                      DashboardCard(
                        completed: completedCount,
                        total: totalCount,
                      ),
                      const SizedBox(height: 12),
                      TaskSearchField(
                        controller: _searchController,
                        hasQuery: _query.isNotEmpty,
                        onClear: _searchController.clear,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TaskFilterChips(
                              activeFilter: _activeFilter,
                              onChanged: (filter) {
                                setState(() {
                                  _activeFilter = filter;
                                });
                              },
                              labelBuilder: _filterLabel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TaskSortMenu(
                            activeSort: _activeSort,
                            onChanged: (sort) {
                              setState(() {
                                _activeSort = sort;
                              });
                            },
                            labelBuilder: _sortLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: visibleTasks.isEmpty
                        ? TaskEmptyState(
                            hasTasks: _selectedGroup.tasks.isNotEmpty,
                          )
                        : ListView.builder(
                            key: ValueKey(
                              '${_activeFilter.name}-${_query.length}',
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                            itemCount: visibleTasks.length,
                            itemBuilder: (context, index) {
                              final task = visibleTasks[index];
                              return TaskTileCard(
                                task: task,
                                priorityLabel: _priorityLabel(task.priority),
                                priorityColor: _priorityColor(task.priority),
                                onToggle: () => _toggleTask(task),
                                onDelete: () => _deleteTask(task),
                                onEdit: () => _showTaskEditor(existing: task),
                                onClearDueDate: () {
                                  final userId = _requireUserId();
                                  final listId = _selectedGroup.id;
                                  setState(() {
                                    task.dueDate = null;
                                  });
                                  unawaited(_persistAndSyncWidget());
                                  unawaited(
                                    _mongoService.upsertTask(
                                      userId: userId,
                                      listId: listId,
                                      task: task,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDataForUser(String userId) async {
    final localData = await _storage.load(userId);
    if (!mounted) {
      return;
    }

    setState(() {
      _database = localData;
      _isLoading = false;
    });
    unawaited(_syncHomeWidget());
    unawaited(_syncFromRemoteOnStartup(localData));
  }

  Future<void> _showTaskEditor({TaskItem? existing}) async {
    final userId = _requireUserId();
    final selectedListId = _selectedGroup.id;
    final TaskEditorResult? result = await showTaskEditorSheet(
      context,
      existing: existing,
      priorityLabelBuilder: _priorityLabel,
    );

    if (!mounted || result == null) {
      return;
    }

    await _waitForNextFrame();
    if (!mounted) {
      return;
    }

    late TaskItem taskToSync;
    setState(() {
      if (existing == null) {
        final newTask = TaskItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          userId: userId,
          title: result.title,
          notes: result.notes,
          priority: result.priority,
          dueDate: result.dueDate,
          createdAt: DateTime.now(),
        );
        _selectedGroup.tasks.insert(0, newTask);
        taskToSync = newTask;
      } else {
        existing
          ..userId = userId
          ..title = result.title
          ..notes = result.notes
          ..priority = result.priority
          ..dueDate = result.dueDate;
        taskToSync = existing;
      }
    });

    await _persistAndSyncWidget();
    unawaited(_syncTaskToMongo(listId: selectedListId, task: taskToSync));
  }

  Future<void> _showAddListDialog() async {
    final userId = _requireUserId();
    final name = await showListNameSheet(
      context,
      title: 'Create task list',
      actionLabel: 'Create',
    );

    if (!mounted || name == null || name.isEmpty) {
      return;
    }

    await _waitForNextFrame();
    if (!mounted) {
      return;
    }

    final newGroup = TaskGroup(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );

    setState(() {
      _database.groups.add(newGroup);
      _database.selectedGroupId = newGroup.id;
    });

    await _persistAndSyncWidget();
    unawaited(_mongoService.upsertList(userId: userId, group: newGroup));
  }

  Future<void> _showRenameListDialog(TaskGroup group) async {
    final userId = _requireUserId();
    final name = await showListNameSheet(
      context,
      title: 'Rename list',
      actionLabel: 'Save',
      initialValue: group.name,
    );

    if (!mounted || name == null || name.isEmpty) {
      return;
    }

    await _waitForNextFrame();
    if (!mounted) {
      return;
    }

    setState(() {
      group.name = name;
    });

    await _persistAndSyncWidget();
    unawaited(_mongoService.upsertList(userId: userId, group: group));
  }

  Future<void> _deleteList(TaskGroup group) async {
    final userId = _requireUserId();
    if (_database.groups.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one list is required')),
      );
      return;
    }

    setState(() {
      _database.groups.removeWhere((item) => item.id == group.id);
      if (_database.selectedGroupId == group.id) {
        _database.selectedGroupId = _database.groups.first.id;
      }
    });

    await _persistAndSyncWidget();
    unawaited(_mongoService.deleteList(userId: userId, groupId: group.id));
  }

  Future<void> _clearCompleted() async {
    final userId = _requireUserId();
    final completedTaskIds = _selectedGroup.tasks
        .where((task) => task.isCompleted)
        .map((task) => task.id)
        .toList();

    setState(() {
      _selectedGroup.tasks.removeWhere((task) => task.isCompleted);
    });

    await _persistAndSyncWidget();
    for (final taskId in completedTaskIds) {
      unawaited(_mongoService.deleteTask(userId: userId, taskId: taskId));
    }
  }

  Future<void> _toggleTask(TaskItem task) async {
    final userId = _requireUserId();
    final listId = _selectedGroup.id;
    setState(() {
      task.isCompleted = !task.isCompleted;
    });

    await _persistAndSyncWidget();
    unawaited(
      _mongoService.upsertTask(userId: userId, listId: listId, task: task),
    );
  }

  Future<void> _deleteTask(TaskItem task) async {
    final userId = _requireUserId();
    final taskId = task.id;
    setState(() {
      _selectedGroup.tasks.removeWhere((item) => item.id == task.id);
    });

    await _persistAndSyncWidget();
    unawaited(_mongoService.deleteTask(userId: userId, taskId: taskId));
  }

  String _filterLabel(TaskFilter filter) {
    return switch (filter) {
      TaskFilter.all => 'All',
      TaskFilter.active => 'Active',
      TaskFilter.completed => 'Completed',
      TaskFilter.dueToday => 'Today',
      TaskFilter.overdue => 'Overdue',
    };
  }

  String _sortLabel(TaskSort sort) {
    return switch (sort) {
      TaskSort.custom => 'Custom',
      TaskSort.createdAt => 'Newest',
      TaskSort.priority => 'Priority',
      TaskSort.dueDate => 'Due date',
    };
  }

  String _priorityLabel(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => 'Low',
      TaskPriority.medium => 'Medium',
      TaskPriority.high => 'High',
    };
  }

  Color _priorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => const Color(0xFF2D8F5C),
      TaskPriority.medium => const Color(0xFFCB7A23),
      TaskPriority.high => const Color(0xFFC44642),
    };
  }

  Future<void> _closeDrawerThen(FutureOr<void> Function() action) async {
    final isDrawerOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
    if (isDrawerOpen) {
      _scaffoldKey.currentState?.closeDrawer();
      await Future<void>.delayed(const Duration(milliseconds: 280));
      await Future<void>.delayed(Duration.zero);
      if (!mounted) {
        return;
      }
    }
    await action();
  }

  Future<void> _syncTaskToMongo({
    required String listId,
    required TaskItem task,
  }) async {
    final userId = _requireUserId();
    try {
      await _mongoService
          .upsertTask(userId: userId, listId: listId, task: task)
          .timeout(const Duration(seconds: 8), onTimeout: () => false);
    } catch (_) {
      // Keep UI stable; local save already succeeded.
    }
  }

  Future<void> _waitForNextFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });
    return completer.future;
  }

  Future<void> _persistAndSyncWidget() async {
    await _persist();
    await _syncHomeWidget();
  }

  Future<void> _syncHomeWidget() async {
    if (_isLoading) {
      return;
    }
    await _homeWidgetService.syncFromGroup(_selectedGroup);
  }

  Future<void> _syncFromRemoteOnStartup(TaskDatabase localData) async {
    final userId = _requireUserId();
    final remoteData = await _mongoService
        .fetchDatabase(userId)
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
    if (!mounted || remoteData == null) {
      return;
    }

    final merged = _mergeDatabases(localData, remoteData);
    await _storage.save(userId, merged);
    if (!mounted) {
      return;
    }

    setState(() {
      _database = merged;
    });
    await _syncHomeWidget();
  }

  TaskDatabase _mergeDatabases(TaskDatabase local, TaskDatabase remote) {
    final mergedById = <String, TaskGroup>{};

    for (final group in local.groups) {
      mergedById[group.id] = TaskGroup(
        id: group.id,
        name: group.name,
        createdAt: group.createdAt,
        tasks: List<TaskItem>.from(group.tasks),
      );
    }

    for (final group in remote.groups) {
      mergedById[group.id] = group;
    }

    final groups = mergedById.values.toList();
    if (groups.isEmpty) {
      return TaskDatabase.createDefault();
    }

    final selectedId = groups.any((group) => group.id == remote.selectedGroupId)
        ? remote.selectedGroupId
        : groups.first.id;

    return TaskDatabase(groups: groups, selectedGroupId: selectedId);
  }

  Future<void> _persist() async {
    final userId = _requireUserId();
    await _storage.save(userId, _database);
  }

  String _requireUserId() {
    final userId = _activeUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('Missing authenticated user id');
    }
    return userId;
  }
}
