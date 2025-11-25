import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';

import 'package:TaskVerse/src/screens/profile_screen.dart';
import 'package:TaskVerse/src/screens/projects_view.dart';
import 'package:TaskVerse/src/screens/tasks_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _currentIndex = 0;

  // project creation is handled inside the create dialog (allows owner & members selection)

  void _showCreateProjectDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String? selectedOwnerId = FirebaseAuth.instance.currentUser?.uid;
    final Set<String> selectedMembers = <String>{};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newProject),
        content: Form(
          key: _formKey,
          child: StatefulBuilder(builder: (context, setState) {
                return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: l10n.projectTitle),
                  validator: (value) => value!.isEmpty ? l10n.pleaseEnterProjectTitle : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: l10n.projectDescription),
                  validator: (value) => value!.isEmpty ? l10n.pleaseEnterProjectDescription : null,
                ),
                const SizedBox(height: 12),
                // Owner selector + members list (all users)
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').get(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator();
                    final users = snap.data!.docs;

                    // If there are no users in the system, we cannot pick an owner or members.
                    if (users.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('No users found — please invite or create a user first.', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            Text('Projects require at least one user to be the owner.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    // ensure selectedOwnerId and members are valid when users are available
                    if (users.isNotEmpty && (selectedOwnerId == null || !users.any((u) => u.id == selectedOwnerId))) {
                      selectedOwnerId = users.first.id;
                    }
                    if (selectedMembers.isEmpty && FirebaseAuth.instance.currentUser?.uid != null && users.any((u) => u.id == FirebaseAuth.instance.currentUser!.uid)) {
                      selectedMembers.add(FirebaseAuth.instance.currentUser!.uid);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String?>(
                          value: selectedOwnerId,
                          decoration: InputDecoration(labelText: 'Owner', border: const OutlineInputBorder()),
                          items: users.map((u) {
                            final map = u.data() as Map<String, dynamic>?;
                            final displayName = (map?['displayName'] as String?) ?? u.id;
                            return DropdownMenuItem(value: u.id, child: Text(displayName));
                          }).toList(),
                          onChanged: (v) => setState(() => selectedOwnerId = v),
                        ),
                        const SizedBox(height: 8),
                        const Text('Members'),
                        SizedBox(
                          height: 160,
                          child: ListView(
                            children: users.map((u) {
                              final map = u.data() as Map<String, dynamic>?;
                              final displayName = (map?['displayName'] as String?) ?? u.id;
                              final uid = u.id;
                              final isSelected = selectedMembers.contains(uid);
                              return CheckboxListTile(
                                title: Text(displayName),
                                value: isSelected,
                                onChanged: (v) => setState(() => v == true ? selectedMembers.add(uid) : selectedMembers.remove(uid)),
                              );
                            }).toList(),
                          ),
                        )
                      ],
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

              // Ensure we have a valid owner
              if (selectedOwnerId == null) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an owner for the project.')));
                return;
              }

              // Ensure members list includes the owner at minimum
              if (!selectedMembers.contains(selectedOwnerId)) selectedMembers.add(selectedOwnerId!);

              try {
                if (!_formKey.currentState!.validate()) return;
                await FirebaseFirestore.instance.collection('projects').add({
                  'title': _titleController.text.trim(),
                  'description': _descriptionController.text.trim(),
                  'ownerId': selectedOwnerId,
                  'createdAt': Timestamp.now(),
                  'members': selectedMembers.toList(),
                });

                _titleController.clear();
                _descriptionController.clear();
                if (mounted) Navigator.of(context).pop();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create project: $e')));
              }
              
            },
            child: Text(l10n.create),
          ),
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
        title: Text(_currentIndex == 0
            ? l10n.projects
            : _currentIndex == 1
                ? l10n.tasks
                : l10n.profile),
        elevation: 0,
      ),
      body: _buildBody(user, l10n),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.folder_open), label: l10n.projects),
          BottomNavigationBarItem(icon: const Icon(Icons.task_alt), label: l10n.tasks),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.profile),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateProjectDialog(context),
              label: Text(l10n.newProject),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(User? user, AppLocalizations l10n) {
    switch (_currentIndex) {
      case 1:
        return const TasksView();
      case 2:
        return const ProfileScreen();
      default:
        return const ProjectsView();
    }
  }
}
