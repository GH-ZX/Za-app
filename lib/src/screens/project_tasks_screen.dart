import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';
import 'package:TaskVerse/src/screens/task_details_screen.dart';
import 'package:TaskVerse/src/widgets/assigned_user_chip.dart';
import 'package:TaskVerse/src/utils/constants.dart';

class ProjectTasksScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const ProjectTasksScreen({super.key, required this.projectId, required this.projectTitle});

  @override
  State<ProjectTasksScreen> createState() => _ProjectTasksScreenState();
}

class _ProjectTasksScreenState extends State<ProjectTasksScreen> {
  Future<void> _updateTaskStatus(String taskId, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    final updates = {'status': newStatus, 'updatedAt': Timestamp.now()};
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
        .doc(taskId)
        .update(updates);
  }

  Future<void> _showAssignDialog(BuildContext context, String taskId) async {
    final l10n = AppLocalizations.of(context)!;
    String? selectedUser;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.assignTo),
        content: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('users').get(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final users = snap.data!.docs;
            return StatefulBuilder(builder: (context, setState) => DropdownButtonFormField<String?>(
                  value: selectedUser,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: users.map((u) {
                    final data = u.data() as Map<String, dynamic>?;
                    final displayName = data?['displayName'] as String?;
                    final email = data?['email'] as String?;
                    final display = (displayName != null && displayName.isNotEmpty) ? displayName : (email ?? u.id);
                    return DropdownMenuItem<String?>(value: u.id, child: Text(display));
                  }).toList(),
                  onChanged: (v) => setState(() => selectedUser = v),
                ));
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('projects').doc(widget.projectId).collection('tasks').doc(taskId).update({'assignedTo': selectedUser});
            if (mounted) Navigator.of(context).pop();
          }, child: Text('Assign')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.projectTitle)),
      body: Column(children: [
        // Project header area — fetch minimal project data
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('projects').doc(widget.projectId).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final project = snap.data!.data() as Map<String, dynamic>;
              return Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project['title'] ?? widget.projectTitle, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(project['description'] ?? '', style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  )),
                  // Quick stats
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('projects').doc(widget.projectId).collection('tasks').snapshots(),
                    builder: (c, s) {
                      if (!s.hasData) return const SizedBox(width: 52);
                      final tasks = s.data!.docs;
                      final todo = tasks.where((d) => (d.data() as Map<String, dynamic>)['status'] == TaskStatus.todo).length;
                      final inProgress = tasks.where((d) => (d.data() as Map<String, dynamic>)['status'] == TaskStatus.inProgress).length;
                      final done = tasks.where((d) => (d.data() as Map<String, dynamic>)['status'] == TaskStatus.done).length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _statPill(context, todo.toString(), Colors.blue, 'To Do'),
                          const SizedBox(height: 6),
                          _statPill(context, inProgress.toString(), Colors.orange, 'In Progress'),
                          const SizedBox(height: 6),
                          _statPill(context, done.toString(), Colors.green, 'Done'),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),

        const Divider(height: 1),

        // List of tasks for the project — mobile-friendly
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.projectId)
                .collection('tasks')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text(l10n.noTasks));

              final tasks = snapshot.data!.docs;
              return ListView.separated(
                padding: const EdgeInsets.all(12.0),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = tasks[index];
                  final d = doc.data() as Map<String, dynamic>;
                  final statusLabel = TaskStatus.label(d['status']);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailsScreen(projectId: widget.projectId, taskId: doc.id))),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(d['title'] ?? '', style: Theme.of(context).textTheme.titleMedium)),
                            Chip(
                              backgroundColor: TaskStatus.color(d['status']),
                              label: Text(statusLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              avatar: Icon(
                                statusLabel.toLowerCase().contains('done') ? Icons.check_circle : (statusLabel.toLowerCase().contains('progress') ? Icons.hourglass_top : Icons.list),
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ]),
                          if ((d['description'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(d['description'] ?? '', style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 8),
                          // show assigned user if exists
                          Row(children: [
                            AssignedUserChip(userId: d['assignedTo'] as String?),
                          ]),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(DateTime.tryParse((d['createdAt']?.toDate() ?? DateTime.now()).toString()) != null ? '' : '', style: Theme.of(context).textTheme.bodySmall),
                            Wrap(spacing: 8.0, children: [
                              // quick action buttons
                              if ((d['status'] ?? '').toString().toLowerCase().contains('todo'))
                                ElevatedButton.icon(
                                  onPressed: () async => _updateTaskStatus(doc.id, TaskStatus.inProgress),
                                  icon: const Icon(Icons.play_arrow),
                                  label: Text(l10n.start),
                                ),
                              if ((d['status'] ?? '').toString().toLowerCase().contains('in')) ...[
                                ElevatedButton.icon(
                                  onPressed: () async => _updateTaskStatus(doc.id, TaskStatus.done),
                                  icon: const Icon(Icons.check),
                                  label: Text(l10n.complete),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                                ),
                                   OutlinedButton.icon(
                                     onPressed: () async => _updateTaskStatus(doc.id, TaskStatus.todo),
                                     icon: const Icon(Icons.pause),
                                     label: Text(l10n.pause),
                                   ),
                              ],
                              if ((d['status'] ?? '').toString().toLowerCase().contains('done'))
                                OutlinedButton.icon(
                                  onPressed: () async => _updateTaskStatus(doc.id, TaskStatus.todo),
                                  icon: const Icon(Icons.restart_alt),
                                  label: Text(l10n.reopen),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (choice) async {
                                  if (choice == 'edit') {
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailsScreen(projectId: widget.projectId, taskId: doc.id)));
                                  } else if (choice == 'assign') {
                                    await _showAssignDialog(context, doc.id);
                                  } else if (choice == 'delete') {
                                    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                                      title: Text(l10n.deleteTask),
                                      content: Text(l10n.areYouSureDeleteTask),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
                                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.delete, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                                      ],
                                    ));
                                    if (ok == true) {
                                      await FirebaseFirestore.instance.collection('projects').doc(widget.projectId).collection('tasks').doc(doc.id).delete();
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'assign', child: Text('Assign')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ]),
                          ])
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        )
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(context),
        label: Text(l10n.newTask),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _statPill(BuildContext c, String count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: color.withOpacity(0.15)),
      child: Row(children: [
        CircleAvatar(radius: 8, backgroundColor: color),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(count, style: const TextStyle(fontWeight: FontWeight.bold)), Text(label, style: Theme.of(c).textTheme.bodySmall)]),
      ]),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final _formKey = GlobalKey<FormState>();

    String? selectedUserId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.newTask),
          content: Form(
            key: _formKey,
            child: StatefulBuilder(builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: l10n.taskTitle),
                    validator: (v) => v!.isEmpty ? l10n.pleaseEnterTaskTitle : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: descriptionController, decoration: InputDecoration(labelText: l10n.taskDescription)),
                  const SizedBox(height: 12),

                  // assignee selector — load all registered users (previously limited to project members)
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('users').get(),
                    builder: (ctx, snap) {
                      if (!snap.hasData) return const SizedBox.shrink();
                      final users = snap.data!.docs;
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
                  ),
                ],
              );
            }),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                await FirebaseFirestore.instance.collection('projects').doc(widget.projectId).collection('tasks').add({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'status': TaskStatus.todo,
                  'createdAt': Timestamp.now(),
                  'createdBy': FirebaseAuth.instance.currentUser?.uid,
                  'assignedTo': selectedUserId,
                });

                if (mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.add),
            )
          ],
        );
      },
    );
  }
}
