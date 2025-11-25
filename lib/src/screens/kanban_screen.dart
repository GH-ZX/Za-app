import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';
import 'package:TaskVerse/src/screens/task_details_screen.dart';
import 'package:TaskVerse/src/utils/constants.dart';

// Data model for a user
class AppUser {
  final String id;
  final String displayName;
  final String email;

  AppUser({required this.id, required this.displayName, required this.email});

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
    );
  }
}

// Data model for our tasks
class Task {
  final String id;
  final String title;
  final String description;
  final String status;
  final Timestamp createdAt;
  final String? createdBy;
  final String? assignedTo;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.createdBy,
    this.assignedTo,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? TaskStatus.todo,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      createdBy: data['createdBy'] as String?,
      assignedTo: data['assignedTo'] as String?,
    );
  }
}

class KanbanScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const KanbanScreen({super.key, required this.projectId, required this.projectTitle});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Task> _todoTasks = [];
  List<Task> _inProgressTasks = [];
  List<Task> _doneTasks = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.kanbanBoard(widget.projectTitle)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .collection('tasks')
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(l10n.noTasks));
          }

          List<Task> allTasks = snapshot.data!.docs.map((doc) => Task.fromFirestore(doc)).toList();

          _todoTasks = allTasks.where((t) => t.status == TaskStatus.todo).toList();
          _inProgressTasks = allTasks.where((t) => t.status == TaskStatus.inProgress).toList();
          _doneTasks = allTasks.where((t) => t.status == TaskStatus.done).toList();

          List<DragAndDropList> taskColumns = [
            DragAndDropList(header: _buildHeader(l10n.todo, _todoTasks.length), children: _todoTasks.map(_buildTaskItem).toList()),
            DragAndDropList(header: _buildHeader(l10n.inProgress, _inProgressTasks.length), children: _inProgressTasks.map(_buildTaskItem).toList()),
            DragAndDropList(header: _buildHeader(l10n.done, _doneTasks.length), children: _doneTasks.map(_buildTaskItem).toList()),
          ];

          return DragAndDropLists(
            children: taskColumns,
            onItemReorder: _onItemReorder,
            onListReorder: (oldListIndex, newListIndex) {},
            axis: Axis.horizontal,
            listWidth: 320,
            listPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            listInnerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskDialog,
        label: Text(l10n.newTask),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Chip(
            label: Text(count.toString()),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        ],
      ),
    );
  }

  DragAndDropItem _buildTaskItem(Task task) {
    return DragAndDropItem(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TaskDetailsScreen(projectId: widget.projectId, taskId: task.id),
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (task.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (task.assignedTo != null)
                  AssignedUserChip(userId: task.assignedTo!)
                    else
                      Chip(label: Text(AppLocalizations.of(context)!.unassigned), avatar: Icon(Icons.person_outline)),

                    // Status indicator
                    Chip(
                      avatar: Icon(
                        TaskStatus.label(task.status).toLowerCase().contains('done') ? Icons.check_circle : (TaskStatus.label(task.status).toLowerCase().contains('progress') ? Icons.hourglass_top : Icons.list),
                        color: Colors.white,
                        size: 16,
                      ),
                      label: Text(TaskStatus.label(task.status), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: TaskStatus.color(task.status),
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) async {
    Task movedTask;
    switch(oldListIndex) {
      case 0: movedTask = _todoTasks.removeAt(oldItemIndex); break;
      case 1: movedTask = _inProgressTasks.removeAt(oldItemIndex); break;
      case 2: movedTask = _doneTasks.removeAt(oldItemIndex); break;
      default: return;
    }

    String newStatus;
    switch (newListIndex) {
      case 0: newStatus = TaskStatus.todo; _todoTasks.insert(newItemIndex, movedTask); break;
      case 1: newStatus = TaskStatus.inProgress; _inProgressTasks.insert(newItemIndex, movedTask); break;
      case 2: newStatus = TaskStatus.done; _doneTasks.insert(newItemIndex, movedTask); break;
      default: return;
    }

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(movedTask.id)
        .update({'status': newStatus});

    setState(() {});
  }

  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedUserId;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newTask),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: l10n.taskTitle),
                      validator: (value) => value!.isEmpty ? l10n.pleaseEnterTaskTitle : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: descriptionController, decoration: InputDecoration(labelText: l10n.taskDescription)),
                    const SizedBox(height: 24),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        
                        List<AppUser> users = snapshot.data!.docs.map((doc) => AppUser.fromFirestore(doc)).toList();

                        return DropdownButtonFormField<String>(
                          value: selectedUserId,
                          hint: Text(l10n.assignTo),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_add_alt_1),
                          ),
                          items: users.map((user) {
                            return DropdownMenuItem<String>(
                              value: user.id,
                              child: Text(user.displayName.isNotEmpty ? user.displayName : user.email),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedUserId = value;
                            });
                          },
                          isExpanded: true,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await FirebaseFirestore.instance
                    .collection('projects')
                    .doc(widget.projectId)
                    .collection('tasks')
                    .add({
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'status': TaskStatus.todo,
                  'createdAt': Timestamp.now(),
                  'createdBy': FirebaseAuth.instance.currentUser?.uid,
                  'assignedTo': selectedUserId,
                });
                if (mounted) {
                  Navigator.of(context).pop();
                  // Ensure parent state refreshes so the new task appears immediately
                  setState(() {});
                }
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }
}

class AssignedUserChip extends StatelessWidget {
  final String userId;
  const AssignedUserChip({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Chip(label: Text(AppLocalizations.of(context)!.loading));
        }
        final user = AppUser.fromFirestore(snapshot.data!);
        final displayName = user.displayName.isNotEmpty ? user.displayName : user.email;
        
        return Chip(
          avatar: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U', style: TextStyle(color: Colors.white)),
          ),
          label: Text(displayName),
        );
      },
    );
  }
}
