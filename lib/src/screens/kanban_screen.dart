
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:firebase_auth/firebase_auth.dart';

// A data model for our tasks
class Task {
  final String id;
  final String title;
  final String description;
  final String status;
  final Timestamp createdAt;

  Task({required this.id, required this.title, required this.description, required this.status, required this.createdAt});

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'todo',
      createdAt: data['createdAt'] ?? Timestamp.now(),
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
  List<DragAndDropList> _taskLists = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectTitle),
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
          if (!snapshot.hasData) {
            return const Center(child: Text('لا توجد مهام بعد'));
          }

          List<Task> tasks = snapshot.data!.docs.map((doc) => Task.fromFirestore(doc)).toList();

          // Separate tasks into lists based on status
          List<DragAndDropItem> todoItems = tasks.where((t) => t.status == 'todo').map(_buildTaskItem).toList();
          List<DragAndDropItem> inProgressItems = tasks.where((t) => t.status == 'in_progress').map(_buildTaskItem).toList();
          List<DragAndDropItem> doneItems = tasks.where((t) => t.status == 'done').map(_buildTaskItem).toList();

          _taskLists = [
            DragAndDropList(header: _buildHeader('لم تبدأ', todoItems.length), children: todoItems),
            DragAndDropList(header: _buildHeader('قيد التنفيذ', inProgressItems.length), children: inProgressItems),
            DragAndDropList(header: _buildHeader('تم الانتهاء', doneItems.length), children: doneItems),
          ];

          return DragAndDropLists(
            children: _taskLists,
            onItemReorder: _onItemReorder,
            onListReorder: (oldListIndex, newListIndex) {}, // List reordering is disabled
            axis: Axis.horizontal, // Horizontal scrolling for columns
            listWidth: 300, // Width of each column
            listPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            listDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        tooltip: 'إضافة مهمة جديدة',
        child: const Icon(Icons.add_task),
      ),
    );
  }

  Widget _buildHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
          )
        ],
      ),
    );
  }

  DragAndDropItem _buildTaskItem(Task task) {
    return DragAndDropItem(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        elevation: 2,
        child: ListTile(
          title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          // You can add more details or actions here
        ),
      ),
    );
  }

  void _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) async {
    // Find the task that was moved
    DragAndDropItem movedItem = _taskLists[oldListIndex].children.removeAt(oldItemIndex);
    _taskLists[newListIndex].children.insert(newItemIndex, movedItem);
    
    // Find the task ID - this is a bit tricky, we need to get it from the original list
    // This assumes the order is preserved from the stream
    final tasks = (await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .collection('tasks')
            .get())
        .docs;
    
    Task? targetTask;
    int currentItemIndex = -1;
    for (var list in _taskLists) {
        for (var item in list.children) {
            currentItemIndex++;
            if (currentItemIndex == oldItemIndex) {
                targetTask = Task.fromFirestore(tasks[currentItemIndex]);
                break;
            }
        }
    }

    if (targetTask == null) return;

    // Determine new status
    String newStatus;
    switch (newListIndex) {
      case 0: newStatus = 'todo'; break;
      case 1: newStatus = 'in_progress'; break;
      case 2: newStatus = 'done'; break;
      default: return;
    }

    // Update the task status in Firestore
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(targetTask.id)
        .update({'status': newStatus});

    setState(() {});
  }

  void _showCreateTaskDialog() {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مهمة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'عنوان المهمة')),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'الوصف')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('projects')
                    .doc(widget.projectId)
                    .collection('tasks')
                    .add({
                  'title': _titleController.text,
                  'description': _descriptionController.text,
                  'status': 'todo', // Default status
                  'createdAt': Timestamp.now(),
                  'createdBy': FirebaseAuth.instance.currentUser?.uid,
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
