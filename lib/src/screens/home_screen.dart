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

  void _showCreateProjectDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String? selectedOwnerId = FirebaseAuth.instance.currentUser?.uid;
    final Set<String> selectedMembers = {if (selectedOwnerId != null) selectedOwnerId};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newProject),
        content: _CreateProjectDialogContent(
          formKey: _formKey,
          titleController: _titleController,
          descriptionController: _descriptionController,
          initialOwnerId: selectedOwnerId,
          initialMembers: selectedMembers,
          onOwnerChanged: (newOwnerId) {
            selectedOwnerId = newOwnerId;
          },
          onMembersChanged: (newMembers) {
            selectedMembers.clear();
            selectedMembers.addAll(newMembers);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _titleController.clear();
              _descriptionController.clear();
              Navigator.of(context).pop();
            },
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              if (selectedOwnerId == null) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an owner for the project.')));
                return;
              }

              if (!selectedMembers.contains(selectedOwnerId)) {
                selectedMembers.add(selectedOwnerId!);
              }

              try {
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

class _CreateProjectDialogContent extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final void Function(String?) onOwnerChanged;
  final void Function(Set<String>) onMembersChanged;
  final String? initialOwnerId;
  final Set<String> initialMembers;

  const _CreateProjectDialogContent({
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.onOwnerChanged,
    required this.onMembersChanged,
    required this.initialOwnerId,
    required this.initialMembers,
  });

  @override
  _CreateProjectDialogContentState createState() => _CreateProjectDialogContentState();
}

class _CreateProjectDialogContentState extends State<_CreateProjectDialogContent> {
  late Future<QuerySnapshot> _usersFuture;
  late String? _selectedOwnerId;
  late Set<String> _selectedMembers;

  @override
  void initState() {
    super.initState();
    _usersFuture = FirebaseFirestore.instance.collection('users').get();
    _selectedOwnerId = widget.initialOwnerId;
    _selectedMembers = widget.initialMembers;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: widget.formKey,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: widget.titleController,
                decoration: InputDecoration(labelText: l10n.projectTitle),
                validator: (value) => value!.isEmpty ? l10n.pleaseEnterProjectTitle : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: widget.descriptionController,
                decoration: InputDecoration(labelText: l10n.projectDescription),
                validator: (value) => value!.isEmpty ? l10n.pleaseEnterProjectDescription : null,
              ),
              const SizedBox(height: 12),
              FutureBuilder<QuerySnapshot>(
                future: _usersFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError || !snap.hasData) {
                    return const Text('Error loading users.');
                  }
                  final users = snap.data!.docs;
                  if (users.isEmpty) {
                    return const Text('No users found.');
                  }

                  if (_selectedOwnerId == null || !users.any((u) => u.id == _selectedOwnerId)) {
                    _selectedOwnerId = users.first.id;
                    widget.onOwnerChanged(_selectedOwnerId);
                  }

                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  if (_selectedMembers.isEmpty && currentUserId != null && users.any((u) => u.id == currentUserId)) {
                    _selectedMembers.add(currentUserId);
                    widget.onMembersChanged(_selectedMembers);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String?>(
                        value: _selectedOwnerId,
                        decoration: const InputDecoration(labelText: 'Owner', border: OutlineInputBorder()),
                        items: users.map((u) {
                          final map = u.data() as Map<String, dynamic>?;
                          final displayName = (map?['displayName'] as String?) ?? u.id;
                          return DropdownMenuItem(value: u.id, child: Text(displayName));
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedOwnerId = v;
                          });
                          widget.onOwnerChanged(v);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Members', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final userDoc = users[index];
                            final map = userDoc.data() as Map<String, dynamic>?;
                            final displayName = (map?['displayName'] as String?) ?? userDoc.id;
                            final uid = userDoc.id;
                            final isSelected = _selectedMembers.contains(uid);
                            return CheckboxListTile(
                              title: Text(displayName),
                              value: isSelected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedMembers.add(uid);
                                  } else {
                                    _selectedMembers.remove(uid);
                                  }
                                });
                                widget.onMembersChanged(_selectedMembers);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
