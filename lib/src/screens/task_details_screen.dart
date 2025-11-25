import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:TaskVerse/src/utils/constants.dart';
import 'package:TaskVerse/src/widgets/assigned_user_chip.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String projectId;
  final String taskId;

  const TaskDetailsScreen({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final _commentController = TextEditingController();

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userName = userData.data()?['displayName'] ?? 'Anonymous';

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(widget.taskId)
        .collection('comments')
        .add({
      'text': _commentController.text.trim(),
      'authorId': user.uid,
      'authorName': userName,
      'createdAt': Timestamp.now(),
    });

    _commentController.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _updateStatus(String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    final updates = <String, dynamic>{'status': newStatus, 'updatedAt': Timestamp.now()};
    if (user != null) updates['updatedBy'] = user.uid;

    if (newStatus == TaskStatus.inProgress) {
      updates['startedAt'] = Timestamp.now();
      if (user != null) updates['startedBy'] = user.uid;
    }

    if (newStatus == TaskStatus.done) {
      updates['completedAt'] = Timestamp.now();
      if (user != null) updates['completedBy'] = user.uid;
    }

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(widget.taskId)
        .update(updates);
  }

  void _showEditTaskDialog(Map<String, dynamic> taskData) {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: taskData['title']);
    final descriptionController = TextEditingController(text: taskData['description']);
    String? selectedUserId = taskData['assignedTo'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editTask),
        content: StatefulBuilder(builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: l10n.taskTitle),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: l10n.taskDescription),
              ),
              const SizedBox(height: 12),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('projects').doc(widget.projectId).get(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final project = snap.data!.data() as Map<String, dynamic>?;
                  final members = List<String>.from(project?['members'] ?? []);
                  if (members.isEmpty) return const SizedBox.shrink();

                  return FutureBuilder<List<DocumentSnapshot>>(
                    future: Future.wait(members.map((id) => FirebaseFirestore.instance.collection('users').doc(id).get())),
                    builder: (ctx2, userSnap) {
                      if (!userSnap.hasData) return const SizedBox.shrink();
                      final users = userSnap.data!;
                      return DropdownButtonFormField<String?>(
                        value: selectedUserId,
                        decoration: InputDecoration(labelText: l10n.assignTo, border: const OutlineInputBorder()),
                        items: users.map((u) {
                          final data = u.data() as Map<String, dynamic>?;
                          final displayName = data?['displayName'] as String?;
                          final email = data?['email'] as String?;
                          final display = (displayName != null && displayName.isNotEmpty) ? displayName : (email ?? u.id);
                          return DropdownMenuItem<String?>(value: u.id, child: Text(display));
                        }).toList(),
                        onChanged: (v) => setState(() => selectedUserId = v),
                      );
                    },
                  );
                },
              ),
            ],
          );
        }),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('projects')
                  .doc(widget.projectId)
                  .collection('tasks')
                  .doc(widget.taskId)
                  .update({
                'title': titleController.text,
                'description': descriptionController.text,
                'assignedTo': selectedUserId,
              });
              if (mounted) Navigator.of(context).pop();
            },
            child: Text(l10n.saveChanges),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfirmation),
        content: Text(l10n.areYouSureDeleteTask),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('projects')
                  .doc(widget.projectId)
                  .collection('tasks')
                  .doc(widget.taskId)
                  .delete();
              if (mounted) {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back from TaskDetailsScreen
              }
            },
            child: Text(l10n.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('tasks')
          .doc(widget.taskId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final taskData = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.taskDetails),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditTaskDialog(taskData),
                tooltip: l10n.editTask,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _showDeleteConfirmationDialog,
                tooltip: l10n.deleteTask,
              ),
            ],
          ),
          body: Column(
            children: [
              // Task Details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: Text(taskData['title'] ?? '', style: textTheme.headlineSmall)),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: Icon(
                            TaskStatus.label(taskData['status']).toLowerCase().contains('done')
                                ? Icons.check_circle
                                : (TaskStatus.label(taskData['status']).toLowerCase().contains('progress') ? Icons.hourglass_top : Icons.list),
                            color: Colors.white,
                            size: 18,
                          ),
                          backgroundColor: TaskStatus.color(taskData['status']),
                          label: Text(TaskStatus.label(taskData['status']), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(taskData['description'] ?? '', style: textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Row(children: [AssignedUserChip(userId: taskData['assignedTo'] as String?)],),
                    const SizedBox(height: 12),
                    // Small helper line beneath description for UX
                    if ((taskData['status'] ?? '').toString().toLowerCase().contains('in'))
                      Builder(builder: (c) {
                        final startedBy = taskData['startedBy'];
                        final startedAt = taskData['startedAt'] as Timestamp?;
                        final when = startedAt != null ? DateFormat.yMMMd().add_jm().format(startedAt.toDate()) : null;
                        final subtitle = when != null ? 'Started ${when}${startedBy != null ? ' • by ${startedBy == FirebaseAuth.instance.currentUser?.uid ? 'you' : startedBy}' : ''}' : 'In progress';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(children: [
                            Icon(Icons.info_outline, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                            const SizedBox(width: 6),
                            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                          ]),
                        );
                      }),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Action area for task controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Determine contextual controls based on status
                    if ((taskData['status'] ?? '').toString().toLowerCase().contains('todo')) ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _updateStatus(TaskStatus.inProgress);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work started')));
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start work'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showEditTaskDialog(taskData),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ] else if ((taskData['status'] ?? '').toString().toLowerCase().contains('in')) ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _updateStatus(TaskStatus.done);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task marked done')));
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          // pause -> put back to todo
                          await _updateStatus(TaskStatus.todo);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task paused')));
                        },
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _updateStatus(TaskStatus.todo);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reopened task')));
                        },
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reopen'),
                      ),
                    ],
                  ],
                ),
              ),
              // Comments
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('projects')
                      .doc(widget.projectId)
                      .collection('tasks')
                      .doc(widget.taskId)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text(l10n.noCommentsYet));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final comment = snapshot.data!.docs[index];
                        final commentData = comment.data() as Map<String, dynamic>;
                        final createdAt = (commentData['createdAt'] as Timestamp).toDate();
                        final formattedDate = DateFormat.yMd().add_jm().format(createdAt);

                        return ListTile(
                          title: Text(commentData['authorName'] ?? 'Anonymous'),
                          subtitle: Text(commentData['text'] ?? ''),
                          trailing: Text(formattedDate),
                        );
                      },
                    );
                  },
                ),
              ),
              // Add Comment
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          labelText: l10n.addComment,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
