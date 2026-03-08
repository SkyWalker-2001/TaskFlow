import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/task_editor_result.dart';
import '../../../models/task_model.dart';

Future<TaskEditorResult?> showTaskEditorSheet(
  BuildContext context, {
  TaskItem? existing,
  required String Function(TaskPriority) priorityLabelBuilder,
}) async {
  var title = existing?.title ?? '';
  var notes = existing?.notes ?? '';
  TaskPriority priority = existing?.priority ?? TaskPriority.medium;
  DateTime? dueDate = existing?.dueDate;

  final result = await showModalBottomSheet<TaskEditorResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFBF2),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);

      return StatefulBuilder(
        builder: (sheetContext, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFD6CB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    existing == null ? 'Add task' : 'Edit task',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: title,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'What needs to be done?',
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (value) {
                      setModalState(() {
                        title = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: notes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional details',
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        notes = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<TaskPriority>(
                    initialValue: priority,
                    items: TaskPriority.values
                        .map(
                          (value) => DropdownMenuItem<TaskPriority>(
                            value: value,
                            child: Text(priorityLabelBuilder(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() {
                          priority = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Priority'),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE3D7)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dueDate == null
                                ? 'No due date'
                                : 'Due: ${DateFormat('MMM d, yyyy').format(dueDate!)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final firstDate = DateTime(2000, 1, 1);
                            final lastDate = DateTime(2100, 12, 31);
                            final rawInitialDate = dueDate ?? DateTime.now();
                            final initialDate =
                                rawInitialDate.isBefore(firstDate)
                                ? firstDate
                                : rawInitialDate.isAfter(lastDate)
                                ? lastDate
                                : rawInitialDate;

                            final selected = await showDatePicker(
                              context: sheetContext,
                              initialDate: initialDate,
                              firstDate: firstDate,
                              lastDate: lastDate,
                              useRootNavigator: true,
                            );
                            if (!sheetContext.mounted || selected == null) {
                              return;
                            }
                            setModalState(() {
                              dueDate = selected;
                            });
                          },
                          icon: const Icon(Icons.event),
                          label: const Text('Pick date'),
                        ),
                        if (dueDate != null)
                          IconButton(
                            onPressed: () {
                              setModalState(() {
                                dueDate = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        final trimmedTitle = title.trim();
                        if (trimmedTitle.isEmpty) {
                          return;
                        }
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.pop(
                          sheetContext,
                          TaskEditorResult(
                            title: trimmedTitle,
                            notes: notes.trim(),
                            priority: priority,
                            dueDate: dueDate,
                          ),
                        );
                      },
                      child: Text(
                        existing == null ? 'Create task' : 'Save changes',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  return result;
}
