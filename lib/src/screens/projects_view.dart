import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// single import kept above
import 'package:TaskVerse/generated/l10n/app_localizations.dart';
import 'package:TaskVerse/src/screens/project_tasks_screen.dart';
import 'package:TaskVerse/src/widgets/assigned_user_chip.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectsView extends StatefulWidget {
  const ProjectsView({super.key});

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  bool _useFallbackQuery = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot>(
      stream: _useFallbackQuery
          ? FirebaseFirestore.instance
              .collection('projects')
              .where('members', arrayContains: user!.uid)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('projects')
              .where('members', arrayContains: user!.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error loading projects: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _useFallbackQuery = true; // try an unordered query as a fallback
                      });
                    },
                    child: const Text('Retry without ordering'),
                  ),
                ],
              ),
            ),
          );
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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // owner and members
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(project['ownerId']).get(),
                      builder: (ctx, ownerSnap) {
                        final members = List<String>.from(project['members'] ?? []);
                            // We show all people as chips (assigned user chip) — this avoids showing
                            // the owner twice (once as a simple text and again as a chip).
                            // Ensure owner appears among members so they are visible in the chips row.
                            if (!members.contains(project['ownerId'])) members.insert(0, project['ownerId']);

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(children: members.map((m) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: AssignedUserChip(userId: m, avatarRadius: 10),
                                  );
                                }).toList()),
                              ),
                            );
                      },
                    )
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProjectTasksScreen(
                        projectId: project.id,
                        projectTitle: project['title'],
                      ),
                    ),
                  );
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _showEditDialog(context, project.id, project);
                    } else if (value == 'delete') {
                      // owner builder
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(l10n.deleteTask),
                          content: Text(l10n.areYouSureDeleteTask),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
                            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.delete, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await FirebaseFirestore.instance.collection('projects').doc(project.id).delete();
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, String projectId, DocumentSnapshot projectDoc) {
    final data = projectDoc.data() as Map<String, dynamic>? ?? {};
    final titleController = TextEditingController(text: data['title'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    String? selectedOwner = data['ownerId'] as String?;
    final selectedMembers = <String>{ ...List<String>.from(data['members'] ?? []) };

    showDialog(context: context, builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return AlertDialog(
        title: Text('Edit project'),
        content: StatefulBuilder(builder: (context, setState) {
          return SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: titleController, decoration: InputDecoration(labelText: l10n.projectTitle)),
                const SizedBox(height: 8),
                TextField(controller: descriptionController, decoration: InputDecoration(labelText: l10n.projectDescription)),
                const SizedBox(height: 12),
                // owner selector and members list
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').get(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator();
                    final users = snap.data!.docs;
                    return Column(children: [
                      DropdownButtonFormField<String?>(
                        value: selectedOwner,
                        decoration: InputDecoration(labelText: 'Owner', border: const OutlineInputBorder()),
                        items: users.map((u) {
                          final map = u.data() as Map<String, dynamic>?;
                          final displayName = (map?['displayName'] as String?) ?? u.id;
                          return DropdownMenuItem(value: u.id, child: Text(displayName));
                        }).toList(),
                        onChanged: (v) => setState(() => selectedOwner = v),
                      ),
                      const SizedBox(height: 8),
                      const Align(alignment: Alignment.centerLeft, child: Text('Members')),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 160,
                        child: ListView(
                          children: users.map((u) {
                            final map = u.data() as Map<String, dynamic>?;
                            final displayName = (map?['displayName'] as String?) ?? u.id;
                            final uid = u.id;
                            return CheckboxListTile(
                              value: selectedMembers.contains(uid),
                              title: Text(displayName),
                              onChanged: (v) => setState(() => v == true ? selectedMembers.add(uid) : selectedMembers.remove(uid)),
                            );
                          }).toList(),
                        ),
                      ),
                    ]);
                  },
                )
              ]),
            ),
          );
        }),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('projects').doc(projectId).update({
              'title': titleController.text.trim(),
              'description': descriptionController.text.trim(),
              'ownerId': selectedOwner,
              'members': selectedMembers.toList(),
            });
            if (mounted) Navigator.of(context).pop();
          }, child: Text('Save')),
        ],
      );
    });
  }
}
