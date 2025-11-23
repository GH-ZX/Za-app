import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/generated/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'package:myapp/src/providers/locale_provider.dart';
import 'package:myapp/src/providers/theme_provider.dart';
import 'package:myapp/src/screens/login_screen.dart';
import 'package:myapp/src/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        const Color primarySeedColor = Colors.blueGrey;

        final TextTheme appTextTheme = TextTheme(
          displayLarge: GoogleFonts.cairo(fontSize: 57, fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w500),
          bodyMedium: GoogleFonts.cairo(fontSize: 16),
          labelLarge: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
        );

        final ThemeData lightTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primarySeedColor,
            brightness: Brightness.light,
          ),
          textTheme: appTextTheme,
          appBarTheme: AppBarTheme(
            backgroundColor: primarySeedColor,
            foregroundColor: Colors.white,
            titleTextStyle: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        );

        final ThemeData darkTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primarySeedColor,
            brightness: Brightness.dark,
          ),
          textTheme: appTextTheme,
        );

        return MaterialApp(
          title: 'Task Manager',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          // User is logged in
          return const HomeScreen();
        } else {
          // User is logged out
          return const LoginScreen();
        }
      },
    );
  }
}
