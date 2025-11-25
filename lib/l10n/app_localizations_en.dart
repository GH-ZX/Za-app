// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TaskVerse';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get projects => 'Projects';

  @override
  String get newProject => 'New Project';

  @override
  String get projectTitle => 'Project Title';

  @override
  String get projectDescription => 'Project Description';

  @override
  String get create => 'Create';

  @override
  String get cancel => 'Cancel';

  @override
  String get noProjects => 'No projects yet.\nStart by creating a new one!';

  @override
  String get tasks => 'Tasks';

  @override
  String get newTask => 'New Task';

  @override
  String get taskTitle => 'Task Title';

  @override
  String get taskDescription => 'Task Description';

  @override
  String get add => 'Add';

  @override
  String get todo => 'To Do';

  @override
  String get inProgress => 'In Progress';

  @override
  String get done => 'Done';

  @override
  String get welcome => 'Welcome,';

  @override
  String get noTasks => 'No tasks yet.';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get displayName => 'Display Name';

  @override
  String get update => 'Update';

  @override
  String kanbanBoard(Object projectName) {
    return 'Kanban Board for project: $projectName';
  }

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get error_invalid_password => 'Password must be at least 6 characters';

  @override
  String get error_user_not_found => 'No user found for that email.';

  @override
  String get error_wrong_password => 'Wrong password provided for that user.';

  @override
  String get taskDetails => 'Task Details';

  @override
  String get comments => 'Comments';

  @override
  String get addComment => 'Add a comment...';

  @override
  String get noCommentsYet => 'No comments yet.';

  @override
  String get editTask => 'Edit Task';

  @override
  String get deleteTask => 'Delete Task';

  @override
  String get deleteConfirmation => 'Delete Confirmation';

  @override
  String get areYouSureDeleteTask => 'Are you sure you want to delete this task?';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get delete => 'Delete';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get forgotPasswordInstruction => 'Enter your email address and we will send you a link to reset your password.';

  @override
  String get sendResetEmail => 'Send Reset Email';

  @override
  String get passwordResetEmailSent => 'Password reset email sent. Please check your inbox.';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginSubheading => 'Login to continue to the Task Management System';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get dontHaveAccountRegister => 'Don\'t have an account? Create a new one';

  @override
  String get loginFailed => 'Login Failed';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get assignTo => 'Assign to';

  @override
  String get loading => 'Loading...';

  @override
  String get pleaseEnterProjectTitle => 'Please enter a project title';

  @override
  String get pleaseEnterProjectDescription => 'Please enter a project description';

  @override
  String get pleaseEnterTaskTitle => 'Please enter a task title';

  @override
  String get nameUpdated => 'Name updated successfully!';

  @override
  String get role => 'Role';

  @override
  String get admin => 'Administrator';

  @override
  String get user => 'User';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameArabic => 'العربية';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get createAccount => 'Create a new account';

  @override
  String get name => 'Name';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get haveAccount => 'Already have an account? Login';

  @override
  String get emailInUse => 'The email address is already in use by another account.';

  @override
  String get signupErrorTitle => 'Signup Failed';

  @override
  String get or => 'OR';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get loginRequired => 'Login required';
}
