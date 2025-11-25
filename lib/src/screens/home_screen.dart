import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';
import 'package:TaskVerse/src/screens/create_project_screen.dart'; // Import the new screen
import 'package:TaskVerse/src/screens/settings_screen.dart';
import 'package:TaskVerse/src/screens/projects_view.dart';
import 'package:TaskVerse/src/screens/tasks_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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
                : l10n.settings),
        elevation: 0,
      ),
      body: _buildBody(user, l10n),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.folder_open), label: l10n.projects),
          BottomNavigationBarItem(icon: const Icon(Icons.task_alt), label: l10n.tasks),
          BottomNavigationBarItem(icon: const Icon(Icons.settings_outlined), label: l10n.settings),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navigate to the new CreateProjectScreen
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const CreateProjectScreen(),
                ));
              },
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
        return const SettingsScreen();
      default:
        return const ProjectsView();
    }
  }
}
