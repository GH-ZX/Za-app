import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;

import 'package:TaskVerse/src/providers/theme_provider.dart';
import 'package:TaskVerse/src/providers/locale_provider.dart';

class ProfileScreen extends StatefulWidget {
  /// If [userId] is provided the screen shows that user's profile in read-only mode
  /// unless it's the current signed-in user — then editing is allowed.
  const ProfileScreen({super.key, this.userId, this.readOnly = false});

  final String? userId;
  final bool readOnly;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String? _userRole;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateUserName() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && _nameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'displayName': _nameController.text,
      });
      await currentUser.updateDisplayName(_nameController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.nameUpdated)),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 80);
      if (picked == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final file = File(picked.path);
      final ref = fb_storage.FirebaseStorage.instance.ref().child('users/${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'photoURL': url});
      await user.updatePhotoURL(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile photo updated')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final currentUser = _auth.currentUser;
    final targetUid = widget.userId ?? currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
        body: targetUid == null
          ? Center(child: Text(l10n.loginRequired))
          : StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(targetUid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final displayName = data?['displayName'] ?? currentUser?.displayName ?? '';
                _userRole = data?['role'];

                // Only populate controller when different — avoids overriding user's edits
                if (_nameController.text != displayName) {
                  _nameController.text = displayName;
                }

                final viewingOtherUser = targetUid != currentUser?.uid || widget.readOnly;

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Profile picture + upload controls
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: (data != null && (data['photoURL'] ?? currentUser?.photoURL) != null && (data['photoURL'] ?? currentUser?.photoURL) != '')
                              ? NetworkImage((data['photoURL'] ?? currentUser?.photoURL) as String)
                              : null,
                          child: (data == null || (data['photoURL'] ?? currentUser?.photoURL) == null || (data['photoURL'] ?? currentUser?.photoURL) == '')
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data?['email'] ?? currentUser?.email ?? '', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              if (!viewingOtherUser)
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _isUploadingImage ? null : () => _pickAndUploadImage(ImageSource.gallery),
                                      icon: const Icon(Icons.photo_library),
                                      label: const Text('Upload'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: _isUploadingImage ? null : () => _pickAndUploadImage(ImageSource.camera),
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Camera'),
                                    ),
                                  ],
                                )
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.displayName, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    // If viewing another user, show read-only
                    viewingOtherUser
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(8)),
                            child: Text(displayName.isNotEmpty ? displayName : l10n.unassigned),
                          )
                        : TextField(
                            controller: _nameController,
                            decoration: InputDecoration(border: const OutlineInputBorder(), hintText: l10n.displayName),
                          ),
                    const SizedBox(height: 16),
                    if (!viewingOtherUser)
                      ElevatedButton(
                        onPressed: _updateUserName,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                        child: Text(l10n.saveChanges),
                      ),
                    const SizedBox(height: 18),
                    // Account actions
                    Card(
                      elevation: 1,
                      child: Column(children: [
                        ListTile(title: Text('Account', style: Theme.of(context).textTheme.titleMedium)),
                        if (!viewingOtherUser)
                          ListTile(
                            leading: const Icon(Icons.email_outlined),
                            title: Text(l10n.changeEmail),
                            subtitle: Text(currentUser?.email ?? ''),
                            onTap: () => _showChangeEmailDialog(currentUser?.email),
                          ),
                        if (!viewingOtherUser)
                          ListTile(
                            leading: const Icon(Icons.lock_outline),
                            title: Text(l10n.changePassword),
                            subtitle: Text(l10n.changePasswordDescription),
                            onTap: () async {
                              // send password reset
                              if (currentUser?.email != null) {
                                try {
                                  await FirebaseAuth.instance.sendPasswordResetEmail(email: currentUser!.email!);
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordResetEmailSent)));
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send reset email: $e')));
                                }
                              }
                            },
                          ),
                        const Divider(height: 1),
                        if (!viewingOtherUser)
                          ListTile(
                            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                            title: Text(l10n.deleteAccount, style: const TextStyle(color: Colors.redAccent)),
                            subtitle: Text(l10n.deleteAccountWarning),
                            onTap: () => _confirmDeleteAccount(currentUser!.uid),
                          ),
                      ]),
                    ),
                    const Divider(height: 32),
                    if (_userRole != null) ...[
                      ListTile(
                        leading: const Icon(Icons.verified_user_outlined),
                        title: Text(l10n.role),
                        subtitle: Text(_userRole == 'admin' ? l10n.admin : l10n.user, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                      ),
                      const Divider(height: 32),
                    ],
                    const SizedBox(height: 12),
                    Card(
                      elevation: 1,
                      child: Column(children: [
                        ListTile(title: Text('Preferences', style: Theme.of(context).textTheme.titleMedium)),
                          // Notifications toggle persisted to user doc
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection('users').doc(targetUid).snapshots(),
                          builder: (ctx, snap) {
                            final udata = snap.data?.data() as Map<String, dynamic>?;
                            final notifications = udata?['notificationsEnabled'] ?? true;
                            final analytics = udata?['analyticsEnabled'] ?? true;
                            final compact = udata?['compactMode'] ?? false;

                            return Column(children: [
                                          SwitchListTile(
                                            value: notifications == true,
                                            title: Text(l10n.notifications),
                                            onChanged: viewingOtherUser ? null : (val) => FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'notificationsEnabled': val}),
                                secondary: const Icon(Icons.notifications_active_outlined),
                              ),
                              SwitchListTile(
                                value: analytics == true,
                                title: Text(l10n.analytics),
                                onChanged: viewingOtherUser ? null : (val) => FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'analyticsEnabled': val}),
                                secondary: const Icon(Icons.analytics_outlined),
                              ),
                              SwitchListTile(
                                value: compact == true,
                                title: Text(l10n.compactMode),
                                onChanged: viewingOtherUser ? null : (val) => FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'compactMode': val}),
                                secondary: const Icon(Icons.format_align_left),
                              ),
                            ]);
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 1,
                      child: Column(children: [
                        ListTile(title: Text('App & Privacy', style: Theme.of(context).textTheme.titleMedium)),
                        ListTile(
                          leading: const Icon(Icons.file_download_outlined),
                          title: Text(l10n.exportData),
                          subtitle: Text(l10n.exportDataDescription),
                          onTap: () async {
                            // Only allow export for the current user
                            if (currentUser == null || viewingOtherUser) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.loginRequired)));
                              return;
                            }

                            // mark export request on user document
                            await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({'dataExportRequestedAt': Timestamp.now()});
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.exportRequested)));
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: Text(l10n.helpAndFeedback),
                          subtitle: Text(l10n.contactSupport),
                          onTap: () => _showSupportDialog(),
                        ),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: Text(l10n.about),
                          subtitle: Text('${l10n.appTitle} • ${l10n.versionLabel}'),
                          onTap: () => _showAboutDialog(),
                        ),
                      ]),
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l10n.language),
                      trailing: DropdownButton<Locale>(
                        value: localeProvider.locale,
                        onChanged: (Locale? newLocale) {
                          if (newLocale != null) {
                            localeProvider.setLocale(newLocale);
                          }
                        },
                        items: AppLocalizations.supportedLocales.map((Locale locale) {
                          return DropdownMenuItem<Locale>(
                            value: locale,
                            child: Text(locale.languageCode == 'ar' ? l10n.languageNameArabic : l10n.languageNameEnglish),
                          );
                        }).toList(),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.color_lens),
                      title: Text(l10n.theme),
                      trailing: DropdownButton<ThemeMode>(
                        value: themeProvider.themeMode,
                        onChanged: (ThemeMode? newMode) {
                          if (newMode != null) {
                            themeProvider.setThemeMode(newMode);
                          }
                        },
                        items: [
                          DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.system)),
                          DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light)),
                          DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
                        ],
                      ),
                    ),
                    const Divider(),
                    if (!viewingOtherUser) ListTile(leading: const Icon(Icons.exit_to_app, color: Colors.red), title: Text(l10n.logout, style: const TextStyle(color: Colors.red)), onTap: () async { await FirebaseAuth.instance.signOut(); }),
                  ],
                );
              },
            ),
    );
  }

  void _showChangeEmailDialog(String? currentEmail) {
    final controller = TextEditingController(text: currentEmail ?? '');
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.changeEmail),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.email)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(onPressed: () async {
            final newEmail = controller.text.trim();
            try {
              await FirebaseAuth.instance.currentUser?.updateEmail(newEmail);
              await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({'email': newEmail});
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email updated')));
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update email: $e')));
            }
          }, child: Text(AppLocalizations.of(context)!.saveChanges))
        ],
      );
    });
  }

  Future<void> _confirmDeleteAccount(String uid) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(l10n.deleteAccount),
      content: Text(l10n.deleteAccountWarning),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.delete, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      ],
    ));

    if (confirmed != true) return;

    try {
      // Delete any user data we store
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      // Attempt to delete the Firebase user - may fail if not recently authenticated
      await FirebaseAuth.instance.currentUser?.delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
    }
  }

  void _showSupportDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(l10n.helpAndFeedback),
      content: Text(l10n.contactSupport),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel))],
    ));
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showAboutDialog(context: context, applicationName: l10n.appTitle, applicationVersion: '1.0.0', children: [Text(l10n.aboutDescription)]);
  }
}
