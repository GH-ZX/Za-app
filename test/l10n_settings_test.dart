import 'package:flutter_test/flutter_test.dart';
import 'package:TaskVerse/generated/l10n/app_localizations_en.dart';
import 'package:TaskVerse/generated/l10n/app_localizations_ar.dart';

void main() {
  group('AppLocalizations', () {
    test('English translations are correct', () {
      final en = AppLocalizationsEn();
      expect(en.settings, 'Settings');
      expect(en.viewProfile, 'View Profile');
      expect(en.appAndPrivacy, 'App & Privacy');
      expect(en.displayOptions, 'Display options');
    });

    test('Arabic translations are correct', () {
      final ar = AppLocalizationsAr();
      expect(ar.settings, 'الإعدادات');
      expect(ar.viewProfile, 'عرض الملف الشخصي');
      expect(ar.appAndPrivacy, 'التطبيق والخصوصية');
      expect(ar.displayOptions, 'خيارات العرض');
    });
  });
}
