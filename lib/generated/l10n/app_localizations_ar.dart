// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مدير المهام';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get home => 'الرئيسية';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get system => 'النظام';

  @override
  String get projects => 'المشاريع';

  @override
  String get newProject => 'مشروع جديد';

  @override
  String get projectTitle => 'عنوان المشروع';

  @override
  String get projectDescription => 'وصف المشروع';

  @override
  String get create => 'إنشاء';

  @override
  String get cancel => 'إلغاء';

  @override
  String get noProjects => 'لا توجد مشاريع بعد.\nابدأ بإنشاء مشروع جديد!';

  @override
  String get tasks => 'المهام';

  @override
  String get newTask => 'مهمة جديدة';

  @override
  String get taskTitle => 'عنوان المهمة';

  @override
  String get taskDescription => 'وصف المهمة';

  @override
  String get add => 'إضافة';

  @override
  String get todo => 'لم تبدأ';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String get done => 'تم الانتهاء';

  @override
  String get welcome => 'أهلاً بك،';

  @override
  String get noTasks => 'لا توجد مهام بعد.';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get displayName => 'الاسم المعروض';

  @override
  String get update => 'تحديث';

  @override
  String kanbanBoard(Object projectName) {
    return 'لوحة Kanban لمشروع: $projectName';
  }

  @override
  String get pleaseEnterValidEmail => 'الرجاء إدخال بريد إلكتروني صحيح';

  @override
  String get error_invalid_password =>
      'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get error_user_not_found => 'لا يوجد مستخدم بهذا البريد الإلكتروني.';

  @override
  String get error_wrong_password => 'كلمة المرور غير صحيحة.';

  @override
  String get taskDetails => 'تفاصيل المهمة';

  @override
  String get comments => 'التعليقات';

  @override
  String get addComment => 'أضف تعليقاً...';

  @override
  String get noCommentsYet => 'لا توجد تعليقات بعد.';

  @override
  String get editTask => 'تعديل المهمة';

  @override
  String get deleteTask => 'حذف المهمة';

  @override
  String get deleteConfirmation => 'تأكيد الحذف';

  @override
  String get areYouSureDeleteTask => 'هل أنت متأكد من رغبتك في حذف هذه المهمة؟';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get delete => 'حذف';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get forgotPasswordInstruction =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور الخاصة بك.';

  @override
  String get sendResetEmail => 'إرسال بريد إعادة التعيين';

  @override
  String get passwordResetEmailSent =>
      'تم إرسال بريد إعادة تعيين كلمة المرور. يرجى التحقق من صندوق الوارد الخاص بك.';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get loginSubheading => 'سجل الدخول للمتابعة إلى نظام إدارة المهام';

  @override
  String get pleaseEnterPassword => 'الرجاء إدخال كلمة المرور';

  @override
  String get dontHaveAccountRegister => 'ليس لديك حساب؟ إنشاء حساب جديد';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get unassigned => 'غير معين';

  @override
  String get assignTo => 'تعيين إلى';

  @override
  String get loading => 'جار التحميل...';

  @override
  String get pleaseEnterProjectTitle => 'الرجاء إدخال عنوان المشروع';

  @override
  String get pleaseEnterProjectDescription => 'الرجاء إدخال وصف المشروع';

  @override
  String get pleaseEnterTaskTitle => 'الرجاء إدخال عنوان المهمة';

  @override
  String get nameUpdated => 'تم تحديث الاسم بنجاح!';

  @override
  String get role => 'الدور';

  @override
  String get admin => 'مسؤول';

  @override
  String get user => 'مستخدم';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameArabic => 'العربية';

  @override
  String get pleaseEnterEmail => 'الرجاء إدخال بريدك الإلكتروني';

  @override
  String get createAccount => 'إنشاء حساب جديد';

  @override
  String get name => 'الاسم';

  @override
  String get pleaseEnterName => 'الرجاء إدخال اسمك';

  @override
  String get haveAccount => 'هل لديك حساب بالفعل؟ تسجيل الدخول';

  @override
  String get emailInUse =>
      'عنوان البريد الإلكتروني مستخدم بالفعل من قبل حساب آخر.';

  @override
  String get signupErrorTitle => 'فشل إنشاء الحساب';
}
