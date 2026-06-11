import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ru'), Locale('ky')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _values = <String, Map<String, String>>{
    'en': {
      'appTitle': 'Sacred KG',
      'tagline': 'Sacred routes of Kyrgyzstan',
      'onboardingTitle': 'Sacred places, respectful routes, living stories.',
      'onboardingBody':
          'Explore Kyrgyzstan through mock cultural guides, region cards, local posts, booking requests, and an assistant ready for a future AI backend.',
      'login': 'Log in',
      'createAccount': 'Create account',
      'continueAsGuest': 'Continue as guest',
      'welcomeBack': 'Welcome back',
      'loginSubtitle':
          'Use any non-empty email and password for the mock session.',
      'email': 'Email',
      'password': 'Password',
      'bothFieldsRequired': 'Both fields are required.',
      'registerSubtitle': 'A local profile is enough for the prototype.',
      'name': 'Name',
      'register': 'Register',
      'alreadyHaveAccount': 'I already have an account',
      'allFieldsRequired': 'All fields are required.',
      'invalidEmail': 'Please enter a valid email address.',
      'passwordTooShort': 'Password must be at least 4 characters.',
      'systemTheme': 'System theme',
      'lightTheme': 'Light theme',
      'aiOfflineHint':
          'Offline guide — ask about Kyrgyz sacred and tourist places only.',
      'commentPlaceholder': 'Write a comment…',
      'send': 'Send',
      'noComments': 'No comments yet. Be the first to share!',
      'place_not_found': 'This place is not available in the catalog.',
      'back_to_catalog': 'Back to catalog',
      'home': 'Home',
      'regions': 'Regions',
      'places': 'Places',
      'ai': 'AI',
      'account': 'Account',
      'settings': 'Settings',
      'darkTheme': 'Dark theme',
      'savedLocally': 'Saved locally',
      'language': 'Language',
      'english': 'English',
      'russian': 'Russian',
      'kyrgyz': 'Kyrgyz',
      'music': 'Music',
      'mockSettingOnly': 'Mock setting only',
      'contactDevelopers': 'Contact developers',
      'about': 'About',
      'aboutText':
          'A Flutter mock MVP for sacred places in Kyrgyzstan, built for demo review and future backend migration.',
      'favorites': 'Favorites',
      'favoritePlacesEmpty': 'Favorite places will appear here.',
      'myBookings': 'My bookings',
      'shortcuts': 'Shortcuts',
      'communityFeed': 'Community feed',
      'visitorTips': 'Visitor tips and local updates',
      'bookingRequests': 'Booking requests',
      'planAnotherVisit': 'Plan another visit',
      'themeLanguageMusic': 'Theme, language, music',
      'logout': 'Logout',
      'deleteAccountQuestion': 'Delete account?',
      'deleteAccountBody':
          'This clears the local mock session and saved settings on this device.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'deleteAccount': 'Delete account',
    },
    'ru': {
      'appTitle': 'Sacred KG',
      'tagline': 'Священные маршруты Кыргызстана',
      'onboardingTitle':
          'Священные места, уважительные маршруты, живые истории.',
      'onboardingBody':
          'Изучайте Кыргызстан через демо-гидов, карточки регионов, местные публикации, заявки на посещение и ассистента для будущего AI-бэкенда.',
      'login': 'Войти',
      'createAccount': 'Создать аккаунт',
      'continueAsGuest': 'Продолжить как гость',
      'welcomeBack': 'С возвращением',
      'loginSubtitle':
          'Для демо-сессии подойдут любые непустые email и пароль.',
      'email': 'Email',
      'password': 'Пароль',
      'bothFieldsRequired': 'Заполните оба поля.',
      'registerSubtitle': 'Для прототипа достаточно локального профиля.',
      'name': 'Имя',
      'register': 'Зарегистрироваться',
      'alreadyHaveAccount': 'У меня уже есть аккаунт',
      'allFieldsRequired': 'Заполните все поля.',
      'invalidEmail': 'Введите корректный email.',
      'passwordTooShort': 'Пароль должен быть не короче 4 символов.',
      'systemTheme': 'Системная тема',
      'lightTheme': 'Светлая тема',
      'aiOfflineHint':
          'Офлайн-гид — спрашивайте только про святые и туристические места Кыргызстана.',
      'commentPlaceholder': 'Напишите комментарий…',
      'send': 'Отправить',
      'noComments': 'Комментариев пока нет. Напишите первым!',
      'place_not_found': 'Этого места нет в каталоге.',
      'back_to_catalog': 'В каталог',
      'home': 'Главная',
      'regions': 'Регионы',
      'places': 'Места',
      'ai': 'AI',
      'account': 'Аккаунт',
      'settings': 'Настройки',
      'darkTheme': 'Темная тема',
      'savedLocally': 'Сохраняется локально',
      'language': 'Язык',
      'english': 'Английский',
      'russian': 'Русский',
      'kyrgyz': 'Кыргызский',
      'music': 'Музыка',
      'mockSettingOnly': 'Только демо-настройка',
      'contactDevelopers': 'Связаться с разработчиками',
      'about': 'О приложении',
      'aboutText':
          'Демо MVP на Flutter о священных местах Кыргызстана для просмотра и будущей миграции на бэкенд.',
      'favorites': 'Избранное',
      'favoritePlacesEmpty': 'Избранные места появятся здесь.',
      'myBookings': 'Мои заявки',
      'shortcuts': 'Быстрые действия',
      'communityFeed': 'Лента сообщества',
      'visitorTips': 'Советы посетителей и местные новости',
      'bookingRequests': 'Заявки на посещение',
      'planAnotherVisit': 'Запланировать еще один визит',
      'themeLanguageMusic': 'Тема, язык, музыка',
      'logout': 'Выйти',
      'deleteAccountQuestion': 'Удалить аккаунт?',
      'deleteAccountBody':
          'Это очистит локальную демо-сессию и сохраненные настройки на устройстве.',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'deleteAccount': 'Удалить аккаунт',
    },
    'ky': {
      'appTitle': 'Sacred KG',
      'tagline': 'Кыргызстандын ыйык маршруттары',
      'onboardingTitle': 'Ыйык жерлер, урматтуу маршруттар, жандуу окуялар.',
      'onboardingBody':
          'Кыргызстанды демо маданий гиддер, регион карталары, жергиликтүү билдирүүлөр, зыяратка өтүнмөлөр жана келечектеги AI бэкендге даяр ассистент аркылуу изилдеңиз.',
      'login': 'Кирүү',
      'createAccount': 'Аккаунт түзүү',
      'continueAsGuest': 'Конок катары улантуу',
      'welcomeBack': 'Кайра кош келиңиз',
      'loginSubtitle': 'Демо-сессия үчүн бош эмес email жана сыр сөз жетиштүү.',
      'email': 'Email',
      'password': 'Сыр сөз',
      'bothFieldsRequired': 'Эки талааны тең толтуруңуз.',
      'registerSubtitle': 'Прототип үчүн локалдык профиль жетиштүү.',
      'name': 'Аты',
      'register': 'Катталуу',
      'alreadyHaveAccount': 'Менде аккаунт бар',
      'allFieldsRequired': 'Бардык талааларды толтуруңуз.',
      'invalidEmail': 'Туура email киргизиңиз.',
      'passwordTooShort': 'Сыр сөз 4 белгиден көп болуусу керек.',
      'systemTheme': 'Системалык тема',
      'lightTheme': 'Ачык тема',
      'aiOfflineHint':
          'Офлайн жол көрсөткүч — Кыргызстандын ыйык жана туристтик жерлери жөнүндө гана сураңыз.',
      'commentPlaceholder': 'Пикир жазыңыз…',
      'send': 'Жөнөтүү',
      'noComments': 'Азырча пикир жок. Биринчи болууга мүмкүнчүлүк!',
      'place_not_found': 'Бул жер каталогдо жок.',
      'back_to_catalog': 'Каталогго',
      'home': 'Башкы',
      'regions': 'Региондор',
      'places': 'Жерлер',
      'ai': 'AI',
      'account': 'Аккаунт',
      'settings': 'Орнотуулар',
      'darkTheme': 'Караңгы тема',
      'savedLocally': 'Локалдык сакталат',
      'language': 'Тил',
      'english': 'Англисче',
      'russian': 'Орусча',
      'kyrgyz': 'Кыргызча',
      'music': 'Музыка',
      'mockSettingOnly': 'Демо жөндөө гана',
      'contactDevelopers': 'Иштеп чыгуучулар менен байланыш',
      'about': 'Тиркеме тууралуу',
      'aboutText':
          'Кыргызстандын ыйык жерлери тууралуу Flutter демо MVP, кароо жана келечекте бэкендге көчүрүү үчүн.',
      'favorites': 'Тандалгандар',
      'favoritePlacesEmpty': 'Тандалган жерлер бул жерде көрүнөт.',
      'myBookings': 'Менин өтүнмөлөрүм',
      'shortcuts': 'Ыкчам өтүүлөр',
      'communityFeed': 'Коомчулук лентасы',
      'visitorTips': 'Зыяратчылардын кеңештери жана жергиликтүү жаңылыктар',
      'bookingRequests': 'Зыярат өтүнмөлөрү',
      'planAnotherVisit': 'Дагы бир зыярат пландаңыз',
      'themeLanguageMusic': 'Тема, тил, музыка',
      'logout': 'Чыгуу',
      'deleteAccountQuestion': 'Аккаунтту өчүрөсүзбү?',
      'deleteAccountBody':
          'Бул түзмөктөгү локалдык демо-сессияны жана сакталган жөндөөлөрдү тазалайт.',
      'cancel': 'Жокко чыгаруу',
      'delete': 'Өчүрүү',
      'deleteAccount': 'Аккаунтту өчүрүү',
    },
  };

  String text(String key) {
    return _values[locale.languageCode]?[key] ?? _values['en']![key]!;
  }

  String get appTitle => text('appTitle');
  String get tagline => text('tagline');
  String get onboardingTitle => text('onboardingTitle');
  String get onboardingBody => text('onboardingBody');
  String get login => text('login');
  String get createAccount => text('createAccount');
  String get continueAsGuest => text('continueAsGuest');
  String get welcomeBack => text('welcomeBack');
  String get loginSubtitle => text('loginSubtitle');
  String get email => text('email');
  String get password => text('password');
  String get bothFieldsRequired => text('bothFieldsRequired');
  String get registerSubtitle => text('registerSubtitle');
  String get name => text('name');
  String get register => text('register');
  String get alreadyHaveAccount => text('alreadyHaveAccount');
  String get allFieldsRequired => text('allFieldsRequired');
  String get invalidEmail => text('invalidEmail');
  String get passwordTooShort => text('passwordTooShort');
  String get systemTheme => text('systemTheme');
  String get lightTheme => text('lightTheme');
  String get aiOfflineHint => text('aiOfflineHint');
  String get commentPlaceholder => text('commentPlaceholder');
  String get send => text('send');
  String get noComments => text('noComments');
  String get placeNotFound => text('place_not_found');
  String get backToCatalog => text('back_to_catalog');
  String get home => text('home');
  String get regions => text('regions');
  String get places => text('places');
  String get ai => text('ai');
  String get account => text('account');
  String get settings => text('settings');
  String get darkTheme => text('darkTheme');
  String get savedLocally => text('savedLocally');
  String get language => text('language');
  String get english => text('english');
  String get russian => text('russian');
  String get kyrgyz => text('kyrgyz');
  String get music => text('music');
  String get mockSettingOnly => text('mockSettingOnly');
  String get contactDevelopers => text('contactDevelopers');
  String get about => text('about');
  String get aboutText => text('aboutText');
  String get favorites => text('favorites');
  String get favoritePlacesEmpty => text('favoritePlacesEmpty');
  String get myBookings => text('myBookings');
  String get shortcuts => text('shortcuts');
  String get communityFeed => text('communityFeed');
  String get visitorTips => text('visitorTips');
  String get bookingRequests => text('bookingRequests');
  String get planAnotherVisit => text('planAnotherVisit');
  String get themeLanguageMusic => text('themeLanguageMusic');
  String get logout => text('logout');
  String get deleteAccountQuestion => text('deleteAccountQuestion');
  String get deleteAccountBody => text('deleteAccountBody');
  String get cancel => text('cancel');
  String get delete => text('delete');
  String get deleteAccount => text('deleteAccount');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(Locale(normalizeLanguageCode(locale.languageCode)));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String normalizeLanguageCode(String? value) {
  switch (value?.toLowerCase()) {
    case 'en':
      return 'en';
    case 'ru':
      return 'ru';
    case 'kg':
    case 'ky':
      return 'ky';
    default:
      return 'ky';
  }
}

String languageLabel(BuildContext context, String code) {
  final l10n = context.l10n;
  switch (code) {
    case 'ru':
      return l10n.russian;
    case 'ky':
      return l10n.kyrgyz;
    default:
      return l10n.english;
  }
}
