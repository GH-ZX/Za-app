import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';
import 'package:TaskVerse/src/screens/edit_profile_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editProfile,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text(l10n.loginRequired))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Center(child: Text(l10n.errorLoadingProfile));
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final displayName = userData['displayName'] ?? user.displayName ?? l10n.unnamed;
                final email = user.email ?? l10n.unassigned;
                final photoURL = userData['photoURL'] ?? user.photoURL;
                final role = userData['role'] as String?;
                final branch = userData['branch'] as String?;
                final birthDate = (userData['birthDate'] as Timestamp?)?.toDate();
                
                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                            child: photoURL == null ? const Icon(Icons.person, size: 50) : null,
                          ),
                          const SizedBox(height: 16),
                          Text(displayName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          if (role != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Chip(
                                label: Text(role == 'admin' ? l10n.admin : l10n.user, style: const TextStyle(fontWeight: FontWeight.bold)),
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, l10n.details),
                    Card(
                      elevation: 0,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
                      child: Column(
                        children: [
                          _InfoTile(icon: Icons.email_outlined, title: l10n.email, subtitle: email),
                          if (branch != null)
                            _InfoTile(icon: Icons.business_outlined, title: l10n.branch, subtitle: branch),
                          if (birthDate != null)
                            _InfoTile(icon: Icons.cake_outlined, title: l10n.birthDate, subtitle: DateFormat.yMMMd().format(birthDate)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, l10n.statistics),
                     Card(
                      elevation: 0,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
                       child: _ProjectsCount(userId: user.uid, l10n: l10n),
                    ),
                  ],
                );
              },
            ),
    );
  }
   Padding _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _ProjectsCount extends StatelessWidget {
  final String userId;
  final AppLocalizations l10n;

  const _ProjectsCount({required this.userId, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where('members', arrayContains: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(trailing: CircularProgressIndicator());
        }
        final count = snapshot.data?.docs.length ?? 0;
        return _InfoTile(icon: Icons.folder_copy_outlined, title: l10n.projects, subtitle: count.toString());
      },
    );
  }
}
