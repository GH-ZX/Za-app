import 'package:flutter/material.dart';
import 'package:TaskVerse/generated/l10n/app_localizations.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('ar'); // Default to Arabic

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    // Check if the new locale is supported
    if (AppLocalizations.supportedLocales.contains(newLocale)) {
      _locale = newLocale;
      notifyListeners();
    }
  }
}
