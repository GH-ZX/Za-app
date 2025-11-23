import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/generated/l10n/app_localizations.dart';

import 'package:myapp/src/screens/kanban_screen.dart';
import 'package:myapp/src/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('projects').add({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'ownerId': user.uid,
      'createdAt': Timestamp.now(),
      'members': [user.uid],
    });

    if (!mounted) return;

    _titleController.clear();
    _descriptionController.clear();
    Navigator.of(context).pop(); // Close the dialog
  }

  void _showCreateProjectDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newProject),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: l10n.projectTitle),
                validator: (value) =>
                    value!.isEmpty ? l10n.pleaseEnterProjectTitle : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: l10n.projectDescription),
                validator: (value) =>
                    value!.isEmpty ? l10n.pleaseEnterProjectDescription : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(onPressed: _createProject, child: Text(l10n.create)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.projects),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: l10n.profile,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .where('members', arrayContains: user!.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                l10n.noProjects,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          var projects = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              var project = projects[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    project['title'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    project['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => KanbanScreen(
                          projectId: project.id,
                          projectTitle: project['title'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(context),
        label: Text(l10n.newProject),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
