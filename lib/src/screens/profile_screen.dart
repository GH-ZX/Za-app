import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/generated/l10n/app_localizations.dart';

import 'package:myapp/src/providers/theme_provider.dart';
import 'package:myapp/src/providers/locale_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted) {
          setState(() {
            _nameController.text = userData.data()?['displayName'] ?? user.displayName ?? '';
            _userRole = userData.data()?['role'];
          });
        }
      } catch (e) {
        // Handle error
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
       if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
    }
  }

  Future<void> _updateUserName() async {
    final user = _auth.currentUser;
    if (user != null && _nameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'displayName': _nameController.text,
      });
      await user.updateDisplayName(_nameController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.nameUpdated)),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (user != null) ...[
                  Text(l10n.displayName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: l10n.displayName,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _updateUserName,
                    child: Text(l10n.saveChanges),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
                const Divider(height: 32),
                 if (_userRole != null) ...[
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(l10n.role),
                    subtitle: Text(_userRole == 'admin' ? l10n.admin : l10n.user, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  ),
                   const Divider(height: 32),
                ],
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
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
    );
  }
}
