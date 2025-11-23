import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';
import 'package:TaskVerse/src/screens/forgot_password_screen.dart';
import 'package:TaskVerse/src/screens/signup_screen.dart';
import 'dart:io' show Platform;
import 'dart:developer' as developer;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // 1. Initialize GoogleSignIn object
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );

  @override
  void initState() {
    super.initState();
    _setupGoogleSignIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. Add the required initialization for v7+
  Future<void> _setupGoogleSignIn() async {
    try {
      // Try to sign in silently on startup to restore the session
      await _googleSignIn.signInSilently();
    } catch (e) {
      developer.log('Google Sign-In silent initialization failed: $e', name: 'com.TaskVerse.login');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // AuthGate will handle navigation
    } on FirebaseAuthException catch (e) {
      final l10n = AppLocalizations.of(context)!;
      String errorMessage = l10n.loginFailed;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = l10n.error_user_not_found;
          break;
        case 'wrong-password':
          errorMessage = l10n.error_wrong_password;
          break;
        case 'invalid-email':
          errorMessage = l10n.pleaseEnterValidEmail;
          break;
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context)!.loginFailed);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // 1. Trigger the Google authentication flow.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Obtain the auth details from the request.
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential for Firebase.
      // idToken is the crucial piece for Firebase Auth.
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential.
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      // 5. If it's a new user, create a document in Firestore.
      if (user != null) {
        final usersCollection = FirebaseFirestore.instance.collection('users');
        final userDoc = await usersCollection.doc(user.uid).get();

        if (!userDoc.exists) {
          final allUsers = await usersCollection.limit(1).get();
          // The first user ever to sign up becomes an admin.
          final String role = allUsers.docs.isEmpty ? 'admin' : 'user';
          await usersCollection.doc(user.uid).set({
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      // AuthGate will handle navigation
    } catch (e) {
      developer.log('Google Sign-In failed: $e', name: 'com.TaskVerse.login');
      _showErrorSnackBar(AppLocalizations.of(context)!.loginFailed);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isDesktop() {
      if (kIsWeb) return false;
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/images/zaapp_icon.png', height: 100),
                const SizedBox(height: 20),
                Text(
                  l10n.welcomeBack,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginSubheading,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return l10n.pleaseEnterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ));
                          },
                    child: Text(l10n.forgotPassword),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _loginWithEmail,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(l10n.login),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(l10n.or),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                _buildGoogleSignInButton(l10n),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const SignupScreen()),
                          );
                        },
                  child: Text(l10n.dontHaveAccountRegister),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(AppLocalizations l10n) {
    bool isSupportedPlatform = kIsWeb || !(_isDesktop() && !Platform.isMacOS); // supported on web, iOS, Android, macOS
    
    if (!isSupportedPlatform) {
      return const SizedBox.shrink(); // Hide on Windows/Linux
    }

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _signInWithGoogle,
      icon: Image.asset('assets/images/google_logo.png', height: 24.0),
      label: Text(l10n.signInWithGoogle),
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ).copyWith(
          elevation: ButtonStyleButton.allOrNull(0.0) // flatter look
      ),
    );
  }
}
