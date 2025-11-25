import 'package:flutter/material.dart';

class TaskStatus {
  static const String todo = 'todo';
  static const String inProgress = 'in_progress';
  static const String done = 'done';

  /// Return a human-friendly label for many common stored variants.
  static String label(String? status) {
    if (status == null) return 'Unknown';
    final normalized = status.toLowerCase().replaceAll('_', ' ').trim();
    if (normalized.contains('todo') || normalized == 'to do') return 'To Do';
    if (normalized.contains('in progress') || normalized == 'inprogress' || normalized.contains('working')) return 'In Progress';
    if (normalized.contains('done') || normalized.contains('completed')) return 'Done';
    return status;
  }

  /// Recommended color for the given status. Uses material colors so it's theme-friendly.
  static Color color(String? status) {
    if (status == null) return Colors.grey;
    final normalized = status.toLowerCase();
    if (normalized.contains('todo')) return Colors.blue.shade600;
    if (normalized.contains('in_progress') || normalized.contains('in progress') || normalized.contains('working')) return Colors.orange.shade700;
    if (normalized.contains('done') || normalized.contains('completed')) return Colors.green.shade700;
    return Colors.grey;
  }
}
