import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';
import 'package:TaskVerse/src/providers/theme_provider.dart';
import 'package:TaskVerse/src/providers/locale_provider.dart';
import 'package:TaskVerse/src/screens/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // SettingsScreen delegates profile editing to ProfileScreen — no direct upload or update here.

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: user == null
          ? Center(child: Text(l10n.loginRequired))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final displayName = data?['displayName'] ?? user.displayName ?? '';
                if (_nameController.text != displayName) _nameController.text = displayName;

                return ListView(padding: const EdgeInsets.all(16.0), children: [
                  // header — big, tappable profile area
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.uid, readOnly: true))),
                    child: Row(children: [
                      CircleAvatar(radius: 40, backgroundImage: (data?['photoURL'] ?? user.photoURL) != null ? NetworkImage((data?['photoURL'] ?? user.photoURL) as String) : null, child: ((data?['photoURL'] ?? user.photoURL) == null) ? const Icon(Icons.person, size: 40) : null),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(displayName, style: Theme.of(context).textTheme.titleLarge)),
                          if ((data?['role'] ?? '') != '') Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Text((data?['role'] ?? '').toString(), style: Theme.of(context).textTheme.bodySmall)),
                        ]),
                        const SizedBox(height: 6),
                        Text(user.email ?? '', style: Theme.of(context).textTheme.bodySmall),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 18),

                  // Profile quick actions
                  Card(elevation: 1, child: Column(children: [
                    ListTile(title: Text(l10n.profile)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal:16.0, vertical:8.0), child: Row(children: [
                      Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.uid, readOnly: true))), icon: const Icon(Icons.visibility), label: Text(l10n.viewProfile))),
                      const SizedBox(width: 12),
                      Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())), icon: const Icon(Icons.edit), label: Text(l10n.editProfile))),
                    ]))
                  ])),

                  const SizedBox(height: 12),

                  // Preferences section
                  Card(elevation: 1, child: Column(children: [
                    ListTile(title: Text(l10n.preferences)),
                    StreamBuilder<DocumentSnapshot>(stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(), builder: (ctx, snap) {
                      final udata = snap.data?.data() as Map<String, dynamic>?;
                      final notifications = udata?['notificationsEnabled'] ?? true;
                      final analytics = udata?['analyticsEnabled'] ?? true;
                      final compact = udata?['compactMode'] ?? false;

                      return Column(children: [
                        SwitchListTile(value: notifications == true, title: Text(l10n.notifications), secondary: const Icon(Icons.notifications_active_outlined), onChanged: (val) => FirebaseFirestore.instance.collection('users').doc(user.uid).update({'notificationsEnabled': val})),
                        SwitchListTile(value: analytics == true, title: Text(l10n.analytics), secondary: const Icon(Icons.analytics_outlined), onChanged: (val) => FirebaseFirestore.instance.collection('users').doc(user.uid).update({'analyticsEnabled': val})),
                        SwitchListTile(value: compact == true, title: Text(l10n.compactMode), secondary: const Icon(Icons.format_align_left), onChanged: (val) => FirebaseFirestore.instance.collection('users').doc(user.uid).update({'compactMode': val})),
                      ]);
                    })
                  ])),

                  const SizedBox(height: 12),

                  // Account & privacy + helpers
                  Card(elevation: 1, child: Column(children: [
                    ListTile(title: Text(l10n.appAndPrivacy)),
                    ListTile(leading: const Icon(Icons.file_download_outlined), title: Text(l10n.exportData), subtitle: Text(l10n.exportDataDescription), onTap: () async { await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'dataExportRequestedAt': Timestamp.now()}); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.exportRequested))); }),
                    ListTile(leading: const Icon(Icons.help_outline), title: Text(l10n.helpAndFeedback), subtitle: Text(l10n.contactSupport), onTap: () => _showSupportDialog()),
                    ListTile(leading: const Icon(Icons.info_outline), title: Text(l10n.about), subtitle: Text('${l10n.appTitle} • ${l10n.versionLabel}'), onTap: () => _showAboutDialog()),
                  ])),

                  const SizedBox(height: 12),

                  // Appearance & Language
                  Card(elevation: 1, child: Column(children: [
                    ListTile(title: Text(l10n.displayOptions)),
                    ListTile(leading: const Icon(Icons.language), title: Text(l10n.language), trailing: DropdownButton<Locale>(value: localeProvider.locale, onChanged: (Locale? newLocale) { if (newLocale != null) localeProvider.setLocale(newLocale); }, items: AppLocalizations.supportedLocales.map((Locale locale) => DropdownMenuItem(value: locale, child: Text(locale.languageCode == 'ar' ? l10n.languageNameArabic : l10n.languageNameEnglish))).toList())),
                    ListTile(leading: const Icon(Icons.color_lens), title: Text(l10n.theme), trailing: DropdownButton<ThemeMode>(value: themeProvider.themeMode, onChanged: (ThemeMode? newMode) { if (newMode != null) themeProvider.setThemeMode(newMode); }, items: [DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.system)), DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light)), DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark))])),
                  ])),

                  const SizedBox(height: 12),

                  ListTile(leading: const Icon(Icons.exit_to_app, color: Colors.red), title: Text(l10n.logout, style: const TextStyle(color: Colors.red)), onTap: () async { await FirebaseAuth.instance.signOut(); }),
                ]);
              },
            ),
    );
  }

  // Edit handled by ProfileScreen — removed local edit dialog helper.

  void _showSupportDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (_) => AlertDialog(title: Text(l10n.helpAndFeedback), content: Text(l10n.contactSupport), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel))]));
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showAboutDialog(context: context, applicationName: l10n.appTitle, applicationVersion: '1.0.0', children: [Text(l10n.aboutDescription)]);
  }
}