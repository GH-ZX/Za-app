import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';
import 'package:TaskVerse/src/providers/theme_provider.dart';
import 'package:TaskVerse/src/providers/locale_provider.dart';
import 'package:TaskVerse/src/screens/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          if (user != null)
            _UserProfileSection(user: user, l10n: l10n),
          const Divider(height: 32),
          _buildSectionTitle(context, l10n.preferences),
          _AppearanceGroup(l10n: l10n),
          const Divider(height: 32),
          _buildSectionTitle(context, l10n.activity),
          _ActivityHistory(l10n: l10n, userId: user?.uid),
          const Divider(height: 32),
          if (user != null)
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                label: Text(l10n.logout, style: const TextStyle(color: Colors.redAccent)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Padding _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

class _UserProfileSection extends StatelessWidget {
  final User user;
  final AppLocalizations l10n;

  const _UserProfileSection({required this.user, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final displayName = userData['displayName'] ?? user.displayName ?? l10n.unnamed;
        final photoURL = userData['photoURL'] ?? user.photoURL;
        final role = userData['role'] as String?;

        return ListTile(
          leading: CircleAvatar(
            radius: 30,
            backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
            child: photoURL == null ? const Icon(Icons.person, size: 30) : null,
          ),
          title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: role != null ? Text(role == 'admin' ? l10n.admin : l10n.user) : null,
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        );
      },
    );
  }
}

class _AppearanceGroup extends StatelessWidget {
  final AppLocalizations l10n;

  const _AppearanceGroup({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: localeProvider.locale,
                items: AppLocalizations.supportedLocales.map((locale) {
                  return DropdownMenuItem<Locale>(
                    value: locale,
                    child: Text(locale.languageCode == 'ar' ? l10n.languageNameArabic : l10n.languageNameEnglish),
                  );
                }).toList(),
                onChanged: (newLocale) {
                  if (newLocale != null) {
                    localeProvider.setLocale(newLocale);
                  }
                },
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: Text(l10n.theme),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<ThemeMode>(
                value: themeProvider.themeMode,
                items: [
                  DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.system)),
                  DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light)),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
                ],
                onChanged: (newMode) {
                  if (newMode != null) {
                    themeProvider.setThemeMode(newMode);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityHistory extends StatelessWidget {
  final AppLocalizations l10n;
  final String? userId;

  const _ActivityHistory({required this.l10n, this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(l10n.noRecentActivity));
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          elevation: 0,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
          child: Column(
            children: snapshot.data!.docs.map((doc) {
              final task = doc.data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text(task['title'] ?? l10n.unassigned),
                subtitle: Text(l10n.taskCompleted),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
