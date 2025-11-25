import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:TaskVerse/src/utils/constants.dart';

void main() {
  group('TaskStatus helpers', () {
    test('labels map various inputs', () {
      expect(TaskStatus.label('todo'), 'To Do');
      expect(TaskStatus.label('To Do'), 'To Do');
      expect(TaskStatus.label('in_progress'), 'In Progress');
      expect(TaskStatus.label('In Progress'), 'In Progress');
      expect(TaskStatus.label('done'), 'Done');
      expect(TaskStatus.label('completed'), 'Done');
      expect(TaskStatus.label(null), 'Unknown');
    });

    test('colors return non-null color', () {
      expect(TaskStatus.color('todo'), isA<Color>());
      expect(TaskStatus.color('in_progress'), isA<Color>());
      expect(TaskStatus.color('done'), isA<Color>());
      expect(TaskStatus.color(null), isA<Color>());
    });
  });
}
