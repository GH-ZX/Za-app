import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

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

  void _showEditTaskDialog(Map<String, dynamic> taskData) {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: taskData['title']);
    final descriptionController = TextEditingController(text: taskData['description']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editTask),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: l10n.taskTitle),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: l10n.taskDescription),
            ),
          ],
        ),
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
                    Text(taskData['title'] ?? '', style: textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(taskData['description'] ?? '', style: textTheme.bodyLarge),
                  ],
                ),
              ),
              const Divider(height: 1),
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
