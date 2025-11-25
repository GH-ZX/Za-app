import 'package:flutter_test/flutter_test.dart';
import 'package:TaskVerse/generated/l10n/app_localizations_en.dart';
import 'package:TaskVerse/generated/l10n/app_localizations_ar.dart';

void main() {
  test('English localization contains settings/profile keys', () {
    final en = AppLocalizationsEn();
    expect(en.viewProfile, 'View profile');
    expect(en.preferences, 'Preferences');
    expect(en.appAndPrivacy, 'App & Privacy');
    expect(en.displayOptions, 'Display options');
  });

  test('Arabic localization contains settings/profile keys', () {
    final ar = AppLocalizationsAr();
    expect(ar.viewProfile, 'عرض الملف الشخصي');
    expect(ar.preferences, 'التفضيلات');
    expect(ar.appAndPrivacy, 'التطبيق والخصوصية');
    expect(ar.displayOptions, 'خيارات العرض');
  });
}
