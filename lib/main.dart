import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';
import 'local_ai.dart';
import 'localized_content.dart';
import 'place_image.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize date formatting for the supported locales so that DateFormat
  // works in any language without an additional async call later.
  await initializeDateFormatting();
  runApp(const ProviderScope(child: SacredKgApp()));
}

String t(String value) => LocalizedContent.phrase(value);

String tWith(String value, Map<String, Object> args) {
  var result = t(value);
  for (final entry in args.entries) {
    result = result.replaceAll('{${entry.key}}', entry.value.toString());
  }
  return result;
}

final authProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController();
});

final settingsProvider = ChangeNotifierProvider<SettingsController>((ref) {
  return SettingsController();
});

final appStateProvider = ChangeNotifierProvider<MockAppState>((ref) {
  return MockAppState();
});

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evaluate guards whenever auth state changes.
  final auth = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      // While the saved session is still being loaded, hold on the splash so
      // that authenticated users are not flashed the onboarding screen.
      if (!auth.loaded) {
        return state.matchedLocation == '/' ? null : '/';
      }
      const publicRoutes = {'/', '/onboarding', '/login', '/register'};
      final loggedIn = auth.isLoggedIn;
      final atPublic = publicRoutes.contains(state.matchedLocation);
      if (!loggedIn && !atPublic) {
        return '/onboarding';
      }
      if (loggedIn && atPublic) {
        return '/home';
      }
      return null;
    },
    routes: [
      _appRoute('/', (_, __) => const SplashScreen()),
      _appRoute('/onboarding', (_, __) => const OnboardingScreen()),
      _appRoute('/login', (_, __) => const LoginScreen()),
      _appRoute('/register', (_, __) => const RegisterScreen()),
      _appRoute('/home', (_, __) => const HomeScreen()),
      _appRoute('/map', (_, __) => const RegionsScreen()),
      _appRoute(
        '/region/:id',
        (_, state) => CatalogScreen(regionId: state.pathParameters['id']),
      ),
      _appRoute('/catalog', (_, __) => const CatalogScreen()),
      _appRoute(
        '/place/:id',
        (_, state) => PlaceDetailScreen(placeId: state.pathParameters['id']!),
      ),
      _appRoute(
        '/ai',
        (_, state) =>
            AiAssistantScreen(placeId: state.uri.queryParameters['place']),
      ),
      _appRoute('/feed', (_, __) => const FeedScreen()),
      _appRoute('/feed/create', (_, __) => const CreatePostScreen()),
      _appRoute(
        '/booking',
        (_, state) =>
            BookingScreen(placeId: state.uri.queryParameters['place']),
      ),
      _appRoute('/settings', (_, __) => const SettingsScreen()),
      _appRoute('/account', (_, __) => const AccountScreen()),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});

GoRoute _appRoute(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder,
) {
  return GoRoute(path: path, pageBuilder: _animatedPage(builder));
}

Page<void> Function(BuildContext, GoRouterState) _animatedPage(
  Widget Function(BuildContext context, GoRouterState state) builder,
) {
  return (context, state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 190),
      child: builder(context, state),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.035, 0.015),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  };
}

class SacredKgApp extends ConsumerWidget {
  const SacredKgApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: router,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: Locale(settings.language),
    );
  }
}

class AppTheme {
  static const ink = Color(0xFF202721);
  static const leaf = Color(0xFF2D6A4F);
  static const mint = Color(0xFFB7E4C7);
  static const clay = Color(0xFF9B4D2E);
  static const gold = Color(0xFFE0A02E);
  static const rose = Color(0xFFB93F55);
  static const cloud = Color(0xFFF4F7F2);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: leaf,
      brightness: Brightness.light,
      primary: leaf,
      secondary: clay,
      tertiary: rose,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cloud,
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      chipTheme: ChipThemeData(
        selectedColor: mint,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: leaf,
      brightness: Brightness.dark,
      primary: mint,
      secondary: gold,
      tertiary: rose,
      surface: const Color(0xFF18201A),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF101510),
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF18201A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }
}

enum PlaceType {
  sacredPlace('Sacred place'),
  petroglyphSite('Petroglyph site'),
  mausoleum('Mausoleum'),
  sacredSpring('Sacred spring'),
  historicalComplex('Historical complex'),
  archaeologicalSite('Archaeological site'),
  naturalSacredPlace('Natural sacred place');

  const PlaceType(this._label);
  final String _label;

  String get label => LocalizedContent.enumLabel('placeType', name, _label);
}

enum PostType {
  review('Review'),
  issue('Issue'),
  tip('Tip'),
  experience('Experience');

  const PostType(this._label);
  final String _label;

  String get label => LocalizedContent.enumLabel('postType', name, _label);
}

enum BookingStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const BookingStatus(this._label);
  final String _label;

  String get label => LocalizedContent.enumLabel('bookingStatus', name, _label);
}

class Region {
  const Region({
    required this.id,
    required String name,
    required String subtitle,
    required this.color,
    required List<String> highlights,
    this.imageAsset,
  }) : _name = name,
       _subtitle = subtitle,
       _highlights = highlights;

  final String id;
  final String _name;
  final String _subtitle;
  final Color color;
  final List<String> _highlights;
  final String? imageAsset;

  String get name => LocalizedContent.regionField(id, 'name', _name);
  String get subtitle =>
      LocalizedContent.regionField(id, 'subtitle', _subtitle);
  List<String> get highlights =>
      LocalizedContent.regionHighlights(id, _highlights);
}

class Place {
  const Place({
    required this.id,
    required String title,
    required this.regionId,
    required this.type,
    required this.rating,
    required this.popularity,
    required this.reviewsCount,
    required String shortDescription,
    required String description,
    required String culturalNote,
    required String visitingRules,
    required String route,
    required this.colors,
    this.imageAsset,
    this.aliases = const <String>[],
    this.isPopularTouristPlace = false,
  }) : _title = title,
       _shortDescription = shortDescription,
       _description = description,
       _culturalNote = culturalNote,
       _visitingRules = visitingRules,
       _route = route;

  final String id;
  final String _title;
  final String regionId;
  final PlaceType type;
  final double rating;
  final int popularity;
  final int reviewsCount;
  final String _shortDescription;
  final String _description;
  final String _culturalNote;
  final String _visitingRules;
  final String _route;
  final List<Color> colors;
  final String? imageAsset;
  final List<String> aliases;
  final bool isPopularTouristPlace;

  String get title => LocalizedContent.placeField(id, 'title', _title);
  String get shortDescription =>
      LocalizedContent.placeField(id, 'shortDescription', _shortDescription);
  String get description =>
      LocalizedContent.placeField(id, 'description', _description);
  String get culturalNote =>
      LocalizedContent.placeField(id, 'culturalNote', _culturalNote);
  String get visitingRules =>
      LocalizedContent.placeField(id, 'visitingRules', _visitingRules);
  String get route => LocalizedContent.placeField(id, 'route', _route);

  /// Aliases used by the offline AI assistant to match the place from
  /// free-form questions.
  Iterable<String> aliasesForAi() sync* {
    yield title;
    yield* aliases;
    final ru = LocalizedContent.placeFieldFor(id, 'title', 'ru');
    if (ru != null) yield ru;
    final ky = LocalizedContent.placeFieldFor(id, 'title', 'ky');
    if (ky != null) yield ky;
  }
}

class Review {
  const Review({
    required this.placeId,
    required this.user,
    required this.rating,
    required String text,
  }) : _text = text;

  final String placeId;
  final String user;
  final double rating;
  final String _text;

  String get text => LocalizedContent.reviewText(placeId, user, _text);
}

class CommunityPost {
  CommunityPost({
    required this.id,
    required String userName,
    required String text,
    required this.timestamp,
    required this.type,
    required this.likeCount,
    required this.commentCount,
    this.placeId,
    this.color = AppTheme.leaf,
  }) : _userName = userName,
       _text = text;

  final String id;
  final String _userName;
  final String _text;
  final DateTime timestamp;
  final PostType type;
  int commentCount;
  final String? placeId;
  final Color color;
  int likeCount;
  bool liked = false;

  String get userName => LocalizedContent.phrase(_userName);
  String get text => LocalizedContent.postText(id, _text);
}

class Booking {
  Booking({
    required this.id,
    required this.placeId,
    required String placeTitle,
    required this.date,
    required this.peopleCount,
    required String notes,
    required this.rulesConfirmed,
    required this.status,
    required this.createdAt,
  }) : _placeTitle = placeTitle,
       _notes = notes;

  final String id;
  final String placeId;
  final String _placeTitle;
  final DateTime date;
  final int peopleCount;
  final String _notes;
  final bool rulesConfirmed;
  final BookingStatus status;
  final DateTime createdAt;

  String get placeTitle =>
      LocalizedContent.placeField(placeId, 'title', _placeTitle);
  String get notes => LocalizedContent.bookingNote(id, _notes);
}

class AiCharacter {
  const AiCharacter({
    required this.id,
    required String name,
    required String role,
    required this.color,
  }) : _name = name,
       _role = role;

  final String id;
  final String _name;
  final String _role;
  final Color color;

  String get name => LocalizedContent.characterField(id, 'name', _name);
  String get role => LocalizedContent.characterField(id, 'role', _role);
}

class ChatMessage {
  const ChatMessage({
    required String text,
    required this.fromUser,
    required this.timestamp,
  }) : _text = text;

  final String _text;
  final bool fromUser;
  final DateTime timestamp;

  String get text => fromUser ? _text : LocalizedContent.phrase(_text);
}

class MockData {
  static const regions = [
    Region(
      id: 'chuy',
      name: 'Chuy',
      subtitle: 'Towers, valleys, and old caravan roads',
      color: Color(0xFF2D6A4F),
      highlights: ['Burana', 'Ala-Archa', 'pilgrim routes'],
      imageAsset: 'assets/images/regions/chuy.jpg',
    ),
    Region(
      id: 'issyk_kul',
      name: 'Issyk-Kul',
      subtitle: 'Lake legends and ancient stones',
      color: Color(0xFF1D7D73),
      highlights: ['Cholpon-Ata', 'Manjyly-Ata', 'lake shrines'],
      imageAsset: 'assets/images/regions/issyk_kul.jpg',
    ),
    Region(
      id: 'naryn',
      name: 'Naryn',
      subtitle: 'High passes and caravan memory',
      color: Color(0xFF5B7C46),
      highlights: ['Tash Rabat', 'Son-Kul', 'mountain trails'],
      imageAsset: 'assets/images/regions/naryn.jpg',
    ),
    Region(
      id: 'talas',
      name: 'Talas',
      subtitle: 'Epic heritage and open valleys',
      color: Color(0xFF9B4D2E),
      highlights: ['Manas Ordo', 'Kirov valley', 'oral history'],
      imageAsset: 'assets/images/regions/talas.jpg',
    ),
    Region(
      id: 'osh',
      name: 'Osh',
      subtitle: 'Sulaiman-Too and Silk Road layers',
      color: Color(0xFFB93F55),
      highlights: ['Sulaiman-Too', 'old city', 'springs'],
      imageAsset: 'assets/images/regions/osh.jpg',
    ),
    Region(
      id: 'jalal_abad',
      name: 'Jalal-Abad',
      subtitle: 'Walnut forests and healing waters',
      color: Color(0xFFE0A02E),
      highlights: ['Arslanbob', 'springs', 'forest paths'],
      imageAsset: 'assets/images/regions/jalal_abad.jpg',
    ),
    Region(
      id: 'batken',
      name: 'Batken',
      subtitle: 'Rock, flowers, and southern legends',
      color: Color(0xFF8064A2),
      highlights: ['Aigul-Tash', 'caves', 'borderland stories'],
      imageAsset: 'assets/images/regions/batken.jpg',
    ),
  ];

  static final places = [
    Place(
      id: 'burana',
      title: 'Burana Tower',
      regionId: 'chuy',
      type: PlaceType.historicalComplex,
      rating: 4.8,
      popularity: 96,
      reviewsCount: 42,
      shortDescription:
          'A minaret and open-air museum near the ancient city of Balasagun.',
      description:
          'Burana Tower is one of the most recognizable heritage sites in northern Kyrgyzstan. The demo story frames it as a calm starting point for learning about caravan routes, stone balbals, and city life on the Silk Road.',
      culturalNote:
          'Visitors often connect the site with memory, travel, and the long exchange of languages and crafts across the valley.',
      visitingRules:
          'Walk carefully around stones, do not climb restricted areas, keep voices low near memorial objects, and leave no marks.',
      route:
          'From Bishkek, take the road toward Tokmok. Local transport or a short taxi ride can complete the route.',
      colors: [Color(0xFF2D6A4F), Color(0xFFE0A02E), Color(0xFF9B4D2E)],
      imageAsset: 'assets/images/places/burana.jpg',
      aliases: ['burana', 'башня бурана', 'бурана', 'бурана мунарасы', 'balasagun'],
    ),
    Place(
      id: 'ala_archa',
      title: 'Ala-Archa Sacred Valley',
      regionId: 'chuy',
      type: PlaceType.naturalSacredPlace,
      rating: 4.7,
      popularity: 88,
      reviewsCount: 31,
      shortDescription:
          'Mountain paths, clear water, and quiet places for reflection.',
      description:
          'This prototype treats Ala-Archa as a nature-centered sacred route, focusing on respectful hiking, water sources, and the feeling of entering a protected mountain space.',
      culturalNote:
          'Mountain valleys are often treated with care because water, stones, and paths carry family and seasonal memory.',
      visitingRules:
          'Stay on marked paths, respect wildlife, avoid loud music, and pack out all waste.',
      route:
          'Reach the park from Bishkek by car or organized transport, then follow marked trails.',
      colors: [Color(0xFF1D7D73), Color(0xFFB7E4C7), Color(0xFF5B7C46)],
      imageAsset: 'assets/images/places/ala_archa.jpg',
      aliases: ['ala-archa', 'ala archa', 'ала-арча', 'ала арча', 'ала-арча'],
    ),
    Place(
      id: 'cholpon_ata',
      title: 'Cholpon-Ata Petroglyphs',
      regionId: 'issyk_kul',
      type: PlaceType.petroglyphSite,
      rating: 4.9,
      popularity: 93,
      reviewsCount: 58,
      shortDescription:
          'Open-air stone drawings near Issyk-Kul with animal and hunting scenes.',
      description:
          'The petroglyph field gives the MVP a strong visual anchor: ancient stones, symbolic animals, and a route that can be explored as a gallery.',
      culturalNote:
          'Rock drawings are presented as fragile records of observation, belief, and movement through the landscape.',
      visitingRules:
          'Do not touch or trace carvings, keep to paths, photograph without flash where requested, and avoid stepping on marked stones.',
      route:
          'Travel to Cholpon-Ata on the north shore of Issyk-Kul, then follow local museum signage.',
      colors: [Color(0xFF1D7D73), Color(0xFFE0A02E), Color(0xFF202721)],
      imageAsset: 'assets/images/places/cholpon_ata.jpg',
      aliases: ['cholpon-ata', 'cholpon ata', 'чолпон-ата', 'чолпон ата', 'петроглиф'],
    ),
    Place(
      id: 'manjyly_ata',
      title: 'Manjyly-Ata Springs',
      regionId: 'issyk_kul',
      type: PlaceType.sacredSpring,
      rating: 4.6,
      popularity: 82,
      reviewsCount: 27,
      shortDescription:
          'A spring area connected with blessings, quiet walks, and family visits.',
      description:
          'The screen content emphasizes a mindful visit: water, dry hills, lake air, and small rituals that should be approached respectfully.',
      culturalNote:
          'Springs are commonly associated with healing, gratitude, and careful behavior around water.',
      visitingRules:
          'Dress respectfully, keep the spring clean, avoid interrupting private prayers, and ask before photographing people.',
      route:
          'Approach from the south shore road of Issyk-Kul; local guides can help find the spring area.',
      colors: [Color(0xFF2D6A4F), Color(0xFF1D7D73), Color(0xFFF4F7F2)],
      imageAsset: 'assets/images/places/manjyly_ata.jpg',
      aliases: ['manjyly-ata', 'manjyly ata', 'манжылы-ата', 'манжылы ата', 'манжылы'],
    ),
    Place(
      id: 'jeti_oguz',
      title: 'Jeti-Oguz Red Rocks',
      regionId: 'issyk_kul',
      type: PlaceType.naturalSacredPlace,
      rating: 4.7,
      popularity: 86,
      reviewsCount: 36,
      shortDescription: 'Red cliffs, legends, and mountain air near Karakol.',
      description:
          'Jeti-Oguz is used as a dramatic nature story in the prototype, with attention to local legends and careful movement around fragile slopes.',
      culturalNote:
          'Landscape legends help visitors understand why a natural formation can hold emotional and cultural meaning.',
      visitingRules:
          'Avoid climbing unstable slopes, keep picnic areas clean, and treat local stories with respect.',
      route:
          'Travel from Karakol toward Jeti-Oguz village, then continue to the main rock viewpoints.',
      colors: [Color(0xFFB93F55), Color(0xFF9B4D2E), Color(0xFFE0A02E)],
      imageAsset: 'assets/images/places/jeti_oguz.jpg',
      aliases: ['jeti-oguz', 'jeti oguz', 'seven bulls', 'жети-огуз', 'жети огуз', 'джеты-огуз', 'жети-өгүз'],
    ),
    Place(
      id: 'tash_rabat',
      title: 'Tash Rabat Caravanserai',
      regionId: 'naryn',
      type: PlaceType.archaeologicalSite,
      rating: 4.8,
      popularity: 79,
      reviewsCount: 22,
      shortDescription: 'A stone caravanserai in a high mountain valley.',
      description:
          'The demo presents Tash Rabat as a place for understanding shelter, trade, weather, and mountain hospitality.',
      culturalNote:
          'Stone architecture in high valleys speaks to endurance and the care given to travelers.',
      visitingRules:
          'Follow local guidance inside the structure, avoid smoke or candles, and protect the surrounding pasture.',
      route:
          'From Naryn, take the road toward At-Bashy and continue by mountain road with suitable transport.',
      colors: [Color(0xFF5B7C46), Color(0xFF9B4D2E), Color(0xFF2D6A4F)],
      imageAsset: 'assets/images/places/tash_rabat.jpg',
      aliases: ['tash rabat', 'tash-rabat', 'таш-рабат', 'таш рабат', 'таш-рабат'],
    ),
    Place(
      id: 'saimaluu_tash',
      title: 'Saimaluu-Tash',
      regionId: 'naryn',
      type: PlaceType.petroglyphSite,
      rating: 4.9,
      popularity: 90,
      reviewsCount: 19,
      shortDescription:
          'A high-altitude petroglyph landscape with thousands of rock images.',
      description:
          'Saimaluu-Tash is treated as a premium heritage route for the app: remote, powerful, and visually distinct.',
      culturalNote:
          'The drawings are framed as a mountain archive of movement, ritual, animals, and sky observation.',
      visitingRules:
          'Use a guide, never scratch or chalk carvings, prepare for weather, and leave the site exactly as found.',
      route:
          'Access is seasonal and remote. The prototype recommends guided travel from Jalal-Abad or Naryn routes.',
      colors: [Color(0xFF202721), Color(0xFF8064A2), Color(0xFFE0A02E)],
      imageAsset: 'assets/images/places/saimaluu_tash.jpg',
      aliases: ['saimaluu-tash', 'saimaluu tash', 'саймалуу-таш', 'саймалуу таш', 'саймалуу-таш'],
    ),
    Place(
      id: 'manas_ordo',
      title: 'Manas Ordo',
      regionId: 'talas',
      type: PlaceType.mausoleum,
      rating: 4.7,
      popularity: 84,
      reviewsCount: 25,
      shortDescription: 'A memorial complex connected with the epic of Manas.',
      description:
          'The mock content makes this a place for epic memory, respectful storytelling, and learning through guided stops.',
      culturalNote:
          'The Manas epic is central to identity, oral history, and shared cultural memory.',
      visitingRules:
          'Keep a respectful tone, follow museum rules, and avoid interrupting ceremonies or guided groups.',
      route:
          'Travel from Talas city toward the complex by road; signage and local transport are available.',
      colors: [Color(0xFF9B4D2E), Color(0xFFE0A02E), Color(0xFF2D6A4F)],
      imageAsset: 'assets/images/places/manas_ordo.jpg',
      aliases: ['manas ordo', 'манас ордо', 'манас', 'мавзолей манаса'],
    ),
    Place(
      id: 'sulaiman_too',
      title: 'Sulaiman-Too',
      regionId: 'osh',
      type: PlaceType.sacredPlace,
      rating: 5.0,
      popularity: 99,
      reviewsCount: 73,
      shortDescription: 'A sacred mountain rising from the heart of Osh.',
      description:
          'Sulaiman-Too is the centerpiece of the prototype: routes, viewpoints, museum stops, and etiquette around sacred spaces.',
      culturalNote:
          'The mountain connects pilgrimage, urban life, memory, and the layered history of the Fergana Valley.',
      visitingRules:
          'Dress modestly, respect prayer spaces, keep pathways clear, and ask before photographing visitors.',
      route:
          'Start from central Osh and use marked walking routes around the mountain and museum areas.',
      colors: [Color(0xFFB93F55), Color(0xFFE0A02E), Color(0xFF1D7D73)],
      imageAsset: 'assets/images/places/sulaiman_too.jpg',
      aliases: ['sulaiman-too', 'sulaiman too', 'sulayman', 'сулайман-тоо', 'сулайман тоо', 'сулейман', 'сулейман гора'],
    ),
    Place(
      id: 'osh_spring',
      title: 'Ak-Buura Old Spring',
      regionId: 'osh',
      type: PlaceType.sacredSpring,
      rating: 4.5,
      popularity: 70,
      reviewsCount: 14,
      shortDescription: 'A local water stop in an old urban route.',
      description:
          'This mock entry adds a smaller sacred water location to show that the catalog can handle famous and neighborhood-scale places.',
      culturalNote:
          'Water places often carry everyday traditions: greeting elders, sharing shade, and keeping the area clean.',
      visitingRules:
          'Do not pollute water, keep containers orderly, and give space to local residents.',
      route:
          'Use local directions from central Osh; the route is intended as a short city visit.',
      colors: [Color(0xFF1D7D73), Color(0xFFB7E4C7), Color(0xFFE0A02E)],
      imageAsset: 'assets/images/places/osh_city.jpg',
      aliases: ['osh spring', 'ак-буура', 'ак буура', 'осh', 'ош', 'осгород'],
    ),
    Place(
      id: 'arslanbob',
      title: 'Arslanbob Sacred Forest',
      regionId: 'jalal_abad',
      type: PlaceType.naturalSacredPlace,
      rating: 4.8,
      popularity: 91,
      reviewsCount: 44,
      shortDescription:
          'Walnut forests, waterfalls, and community-guided walks.',
      description:
          'The app frames Arslanbob as a living landscape where nature, local livelihood, and visitor care meet.',
      culturalNote:
          'Forest routes are connected with hospitality, harvest seasons, and stories passed through families.',
      visitingRules:
          'Use local paths, avoid damaging trees, respect private orchards, and support local guides where possible.',
      route:
          'Travel from Jalal-Abad toward Bazar-Korgon and continue to Arslanbob village.',
      colors: [Color(0xFF2D6A4F), Color(0xFF5B7C46), Color(0xFFE0A02E)],
      imageAsset: 'assets/images/places/arslanbob.jpg',
      aliases: ['arslanbob', 'arslan-bob', 'арсланбоб', 'арсланбап', 'арстанбоб'],
    ),
    Place(
      id: 'jalal_abad_springs',
      title: 'Jalal-Abad Springs',
      regionId: 'jalal_abad',
      type: PlaceType.sacredSpring,
      rating: 4.4,
      popularity: 68,
      reviewsCount: 18,
      shortDescription: 'Healing water traditions in a resort-town setting.',
      description:
          'This mock entry demonstrates how wellness, local history, and sacred-water etiquette can sit in one detail screen.',
      culturalNote:
          'People visit springs with hopes for health, gratitude, and quiet renewal.',
      visitingRules:
          'Observe posted rules, do not block water access, and keep bathing or drinking areas clean.',
      route: 'Reach the resort area from Jalal-Abad city by local road.',
      colors: [Color(0xFF1D7D73), Color(0xFF2D6A4F), Color(0xFFF4F7F2)],
      imageAsset: 'assets/images/places/jalal_abad.jpg',
      aliases: ['jalal-abad', 'jalal abad', 'джалал-абад', 'джалал абад', 'джалалабад', 'жалал-абад', 'жалалабад'],
    ),
    Place(
      id: 'aigul_tash',
      title: 'Aigul-Tash',
      regionId: 'batken',
      type: PlaceType.naturalSacredPlace,
      rating: 4.6,
      popularity: 74,
      reviewsCount: 16,
      shortDescription:
          'A rocky slope tied to the rare Aigul flower and local legend.',
      description:
          'Aigul-Tash gives the MVP a southern nature story with a seasonal rhythm and a strong conservation message.',
      culturalNote:
          'The Aigul flower is treated as a symbol of beauty, loss, and care for rare living heritage.',
      visitingRules:
          'Never pick flowers, stay on marked paths, visit with local guidance, and protect fragile slopes.',
      route:
          'Travel from Batken city toward the protected area during the permitted season.',
      colors: [Color(0xFFB93F55), Color(0xFF8064A2), Color(0xFF5B7C46)],
      imageAsset: 'assets/images/places/aigul_tash.jpg',
      aliases: ['aigul-tash', 'aigul tash', 'айгул-таш', 'айгуль', 'айгүл', 'айгуль-таш'],
    ),

    // ------------------------------------------------------------------
    // Popular tourist places of Kyrgyzstan added to the catalog.
    // These are not strictly sacred but are the most-visited natural and
    // cultural sites travellers ask the offline guide about.
    // ------------------------------------------------------------------

    Place(
      id: 'issyk_kul_lake',
      title: 'Issyk-Kul Lake',
      regionId: 'issyk_kul',
      type: PlaceType.naturalSacredPlace,
      rating: 4.9,
      popularity: 99,
      reviewsCount: 124,
      shortDescription:
          'A vast saline mountain lake — the second largest in the world.',
      description:
          'Issyk-Kul is the heart of Kyrgyz nature tourism: warm-water beaches, stone shrines, fish smokehouses on the shore, and quiet jailoo pastures around the lake.',
      culturalNote:
          'Locals call the lake "the warm sea" — its water is honoured in songs and family memories of summer pilgrimages.',
      visitingRules:
          'Do not litter on the shore, avoid driving on the beach, respect closed seasonal areas, and ask before photographing fishermen.',
      route:
          'From Bishkek take the road through Balykchy to either the north shore (Cholpon-Ata, Bosteri) or south shore (Bokonbaevo, Tamga, Tosor).',
      colors: [Color(0xFF1D7D73), Color(0xFFB7E4C7), Color(0xFFE0A02E)],
      imageAsset: 'assets/images/places/issyk_kul_lake.jpg',
      aliases: ['issyk-kul', 'issyk kul', 'иссык-куль', 'иссык куль', 'ысык-көл', 'ысык көл'],
      isPopularTouristPlace: true,
    ),
    Place(
      id: 'song_kul',
      title: 'Song-Kul Lake',
      regionId: 'naryn',
      type: PlaceType.naturalSacredPlace,
      rating: 4.9,
      popularity: 95,
      reviewsCount: 87,
      shortDescription:
          'High alpine lake on a summer pasture, reachable only in warm months.',
      description:
          'Song-Kul lies at over 3000 metres on a high jailoo. Yurt camps, free-grazing horses, and dark night skies make it one of the most photographed spots in Kyrgyzstan.',
      culturalNote:
          'Shepherd families spend the summer here following old transhumance routes; visitors are welcomed but expected to behave like guests in someone else\'s house.',
      visitingRules:
          'Do not chase animals, do not bathe with soap in the lake, ask before entering a yurt, and leave the high meadow exactly as you found it.',
      route:
          'From Naryn town a 4×4 reaches Song-Kul through the Kalmak-Ashuu pass; the lake is open roughly from June to early October.',
      colors: [Color(0xFF1D7D73), Color(0xFF5B7C46), Color(0xFFB7E4C7)],
      imageAsset: 'assets/images/places/song_kul.jpg',
      aliases: ['song-kul', 'song kul', 'сон-куль', 'сон куль', 'сон-көл', 'сон көл', 'сонкуль'],
      isPopularTouristPlace: true,
    ),
    Place(
      id: 'ala_kul',
      title: 'Ala-Kul Lake',
      regionId: 'issyk_kul',
      type: PlaceType.naturalSacredPlace,
      rating: 4.9,
      popularity: 91,
      reviewsCount: 64,
      shortDescription:
          'A turquoise glacial lake above Karakol — the prize of a 3-day trek.',
      description:
          'Ala-Kul sits at about 3500 metres in the Terskey Ala-Too range. Reaching it usually takes a multi-day trek from Karakol through alpine meadows, river crossings, and the Ala-Kul pass.',
      culturalNote:
          'Trekkers share the trail with herders and pilgrims who treat the high lakes with quiet respect; loud music and waste in camps is frowned upon.',
      visitingRules:
          'Pack out all rubbish, camp only in designated areas, never wash with soap in the lake, and check weather conditions before crossing the pass.',
      route:
          'From Karakol drive to Karakol Gorge, then trek via Sirota or Altyn-Arashan over 2–4 days.',
      colors: [Color(0xFF1D7D73), Color(0xFFB7E4C7), Color(0xFF202721)],
      imageAsset: 'assets/images/places/ala_kul.jpg',
      aliases: ['ala-kul', 'ala kul', 'ала-куль', 'ала куль', 'ала-көл', 'ала көл', 'ala-köl'],
      isPopularTouristPlace: true,
    ),
    Place(
      id: 'skazka_canyon',
      title: 'Skazka (Fairy-Tale) Canyon',
      regionId: 'issyk_kul',
      type: PlaceType.naturalSacredPlace,
      rating: 4.7,
      popularity: 89,
      reviewsCount: 53,
      shortDescription:
          'Red sandstone canyon shaped like castles and dragons near Tosor.',
      description:
          'Skazka Canyon is a short, easy hike just off the south shore of Issyk-Kul. Wind and rain have carved walls and ridges that look like fairy-tale animals — best at sunset when the rocks turn copper-red.',
      culturalNote:
          'Local guides tell children about each rock formation as a character from Kyrgyz tales — keep the stories in mind while walking the ridges.',
      visitingRules:
          'Do not climb fragile sandstone fins, stay on the formed paths, take all rubbish back to your car, and avoid touching painted shapes.',
      route:
          'On the south shore highway between Bokonbaevo and Tamga, look for the marked Skazka turn-off near Tosor.',
      colors: [Color(0xFFE0A02E), Color(0xFFB93F55), Color(0xFF9B4D2E)],
      imageAsset: 'assets/images/places/skazka_canyon.jpg',
      aliases: ['skazka', 'fairy tale canyon', 'каньон сказка', 'сказка', 'жомок капчыгайы'],
      isPopularTouristPlace: true,
    ),
    Place(
      id: 'kel_suu',
      title: 'Kel-Suu Lake',
      regionId: 'naryn',
      type: PlaceType.naturalSacredPlace,
      rating: 4.9,
      popularity: 84,
      reviewsCount: 31,
      shortDescription:
          'A remote turquoise lake near the Chinese border, surrounded by sheer cliffs.',
      description:
          'Kel-Suu is one of the most dramatic and least-visited lakes in Kyrgyzstan. Reaching it requires a border permit, a long 4×4 drive across the At-Bashy valley, and a short hike up to the lake itself.',
      culturalNote:
          'The valley is shared with semi-nomadic families and a small border post; respectful behaviour and patience with formalities are expected.',
      visitingRules:
          'Carry your border zone permit and passport at all times, do not fly drones near the border, leave no trash, and ask before photographing local families.',
      route:
          'From Naryn drive south to At-Bashy and continue to Sary-Belek; the lake is reached by 4×4 and a short walk during summer.',
      colors: [Color(0xFF1D7D73), Color(0xFF202721), Color(0xFFB7E4C7)],
      imageAsset: 'assets/images/places/kel_suu.jpg',
      aliases: ['kel-suu', 'kel suu', 'кель-су', 'кель су', 'көл-суу', 'көл суу'],
      isPopularTouristPlace: true,
    ),
    Place(
      id: 'ala_too_square',
      title: 'Ala-Too Square (Bishkek)',
      regionId: 'chuy',
      type: PlaceType.historicalComplex,
      rating: 4.5,
      popularity: 90,
      reviewsCount: 71,
      shortDescription:
          'The main public square of Bishkek with the Manas monument and changing of the guard.',
      description:
          'Ala-Too Square is the symbolic centre of Bishkek. The huge Kyrgyz flag, the Manas statue, the State History Museum, and the changing of the guard ceremony are the typical short stops for visitors.',
      culturalNote:
          'The square is used for national holidays, official ceremonies, and family evenings — behave as in any working city centre.',
      visitingRules:
          'Do not climb monuments, do not interrupt the guards, keep public order during ceremonies, and follow police instructions on holidays.',
      route:
          'Anywhere in central Bishkek you can walk to the square; metro-style buses and taxis stop nearby.',
      colors: [Color(0xFFB93F55), Color(0xFFE0A02E), Color(0xFF202721)],
      imageAsset: 'assets/images/places/ala_too_square.jpg',
      aliases: ['ala-too', 'ala too', 'площадь ала-тоо', 'манас', 'бишкек центр', 'ала-тоо аянты'],
      isPopularTouristPlace: true,
    ),
    Place(
      id: 'karakol',
      title: 'Karakol Old Town',
      regionId: 'issyk_kul',
      type: PlaceType.historicalComplex,
      rating: 4.6,
      popularity: 80,
      reviewsCount: 48,
      shortDescription:
          'A 19th-century town with a Russian wooden cathedral and a Dungan mosque.',
      description:
          'Karakol is the gateway town of the eastern Issyk-Kul region. The wooden Holy Trinity cathedral, the Dungan mosque without nails, the Sunday animal market, and homestay food are the usual cultural stops.',
      culturalNote:
          'Karakol mixes Kyrgyz, Russian, Dungan and Uyghur traditions — be respectful when visiting religious buildings.',
      visitingRules:
          'Cover heads and shoulders in religious sites, do not photograph people praying without permission, and follow local pricing at the animal market.',
      route:
          'Karakol is at the eastern end of Issyk-Kul, about 6 hours by car from Bishkek along the north shore.',
      colors: [Color(0xFFE0A02E), Color(0xFFB7E4C7), Color(0xFF2D6A4F)],
      imageAsset: 'assets/images/places/karakol.jpg',
      aliases: ['karakol', 'каракол', 'каракол шаары', 'свято-троицкий', 'дунганская мечеть'],
      isPopularTouristPlace: true,
    ),
    Place(
      id: 'bishkek',
      title: 'Bishkek City',
      regionId: 'chuy',
      type: PlaceType.historicalComplex,
      rating: 4.4,
      popularity: 88,
      reviewsCount: 102,
      shortDescription:
          'The capital of Kyrgyzstan — parks, bazaars, museums, and Soviet-era architecture.',
      description:
          'Bishkek is usually the first and last stop of a Kyrgyzstan trip. Walk the tree-lined Erkindik avenue, visit Osh Bazaar, the State History Museum, and small craft galleries before heading into the mountains.',
      culturalNote:
          'A capital that still feels like a quiet city — most monuments are walking distance from each other and locals are happy to give directions.',
      visitingRules:
          'Use crossings, follow rules in mosques and churches, agree on taxi prices in advance, and respect the rules of public parks.',
      route:
          'Bishkek is reached by air via Manas International Airport and overland from neighbouring countries; the city is best explored on foot or by taxi.',
      colors: [Color(0xFF2D6A4F), Color(0xFFE0A02E), Color(0xFFB7E4C7)],
      imageAsset: 'assets/images/places/bishkek.jpg',
      aliases: ['bishkek', 'бишкек', 'манас аэропорт', 'manas airport', 'столица', 'борбор'],
      isPopularTouristPlace: true,
    ),
  ];

  static const characters = [
    AiCharacter(
      id: 'atashka',
      name: 'Atashka',
      role: 'History keeper',
      color: AppTheme.clay,
    ),
    AiCharacter(
      id: 'apashka',
      name: 'Apashka',
      role: 'Tradition guide',
      color: AppTheme.rose,
    ),
  ];

  static const reviews = [
    Review(
      placeId: 'sulaiman_too',
      user: 'Aizada',
      rating: 5,
      text:
          'Sunset from the path felt unforgettable. Go early and bring water.',
    ),
    Review(
      placeId: 'cholpon_ata',
      user: 'Temir',
      rating: 4.8,
      text:
          'The stones need patience. A guide makes the drawings easier to read.',
    ),
    Review(
      placeId: 'burana',
      user: 'Nurai',
      rating: 4.7,
      text: 'A calm stop with strong history. The balbals are the best part.',
    ),
    Review(
      placeId: 'arslanbob',
      user: 'Daniel',
      rating: 4.9,
      text: 'Beautiful forest route and warm local guidance.',
    ),
  ];

  static final posts = [
    CommunityPost(
      id: 'p1',
      userName: 'Aizada',
      text:
          'Sulaiman-Too is best before the afternoon heat. The upper path is quiet at sunrise.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: PostType.tip,
      likeCount: 18,
      commentCount: 4,
      placeId: 'sulaiman_too',
      color: AppTheme.rose,
    ),
    CommunityPost(
      id: 'p2',
      userName: 'Bek',
      text:
          'The road after rain near Tash Rabat can be rough. High-clearance transport helped us.',
      timestamp: DateTime.now().subtract(const Duration(hours: 7)),
      type: PostType.issue,
      likeCount: 9,
      commentCount: 3,
      placeId: 'tash_rabat',
      color: AppTheme.gold,
    ),
    CommunityPost(
      id: 'p3',
      userName: 'Maya',
      text:
          'At Cholpon-Ata, the animal carvings become easier to see when the sun is lower.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      type: PostType.experience,
      likeCount: 27,
      commentCount: 6,
      placeId: 'cholpon_ata',
      color: AppTheme.leaf,
    ),
  ];

  static List<Booking> demoBookings() {
    return [
      Booking(
        id: 'b1',
        placeId: 'burana',
        placeTitle: 'Burana Tower',
        date: DateTime.now().add(const Duration(days: 9)),
        peopleCount: 3,
        notes: 'Need a guide for the stone museum.',
        rulesConfirmed: true,
        status: BookingStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  /// Looks up a region by id. Returns `null` when not found rather than
  /// throwing, so callers can render a friendly "not found" state.
  static Region? regionByIdOrNull(String? id) {
    if (id == null) return null;
    for (final region in regions) {
      if (region.id == id) return region;
    }
    return null;
  }

  /// Looks up a place by id. Returns `null` when not found rather than
  /// throwing.
  static Place? placeByIdOrNull(String? id) {
    if (id == null) return null;
    for (final place in places) {
      if (place.id == id) return place;
    }
    return null;
  }

  /// Compatibility wrapper for callers that expect a non-null result. Falls
  /// back to a generic placeholder region when [id] is unknown.
  static Region regionById(String id) {
    return regionByIdOrNull(id) ??
        const Region(
          id: '__missing__',
          name: 'Unknown region',
          subtitle: 'No data',
          color: Color(0xFF202721),
          highlights: <String>[],
        );
  }

  /// Compatibility wrapper for callers that expect a non-null result. Falls
  /// back to a generic placeholder place when [id] is unknown.
  static Place placeById(String id) {
    final found = placeByIdOrNull(id);
    if (found != null) return found;
    return Place(
      id: id,
      title: 'Unknown place',
      regionId: '__missing__',
      type: PlaceType.sacredPlace,
      rating: 0,
      popularity: 0,
      reviewsCount: 0,
      shortDescription: '',
      description: 'This place is not available in the catalog.',
      culturalNote: '',
      visitingRules: '',
      route: '',
      colors: const [Color(0xFF202721), Color(0xFFB7E4C7)],
    );
  }
}

class AuthController extends ChangeNotifier {
  bool loaded = false;
  bool isLoggedIn = false;
  String userName = 'Guest';
  String email = 'guest@sacred.kg';

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  // Cache the prefs handle so we don't re-fetch it on every operation.
  SharedPreferences? _prefsCache;

  AuthController() {
    unawaited(_load());
  }

  Future<SharedPreferences> _prefs() async {
    return _prefsCache ??= await SharedPreferences.getInstance();
  }

  Future<void> _load() async {
    final prefs = await _prefs();
    isLoggedIn = prefs.getBool('session') ?? false;
    userName = prefs.getString('userName') ?? 'Guest';
    email = prefs.getString('email') ?? 'guest@sacred.kg';
    loaded = true;
    notifyListeners();
  }

  /// Validates [emailValue] using a tolerant RFC-style pattern.
  static bool isValidEmail(String emailValue) {
    return _emailRegex.hasMatch(emailValue.trim());
  }

  /// Returns the localized error key for [emailValue]/[password], or `null`
  /// when the credentials are syntactically valid.
  static String? validateLogin(String emailValue, String password) {
    if (emailValue.trim().isEmpty || password.trim().isEmpty) {
      return 'auth.error.empty';
    }
    if (!isValidEmail(emailValue)) {
      return 'auth.error.email';
    }
    if (password.trim().length < 4) {
      return 'auth.error.password';
    }
    return null;
  }

  static String? validateRegister(
    String name,
    String emailValue,
    String password,
  ) {
    if (name.trim().isEmpty) return 'auth.error.empty';
    return validateLogin(emailValue, password);
  }

  Future<bool> login(String emailValue, String password) async {
    if (validateLogin(emailValue, password) != null) {
      return false;
    }
    final prefs = await _prefs();
    isLoggedIn = true;
    email = emailValue.trim();
    userName = email.split('@').first;
    await prefs.setBool('session', true);
    await prefs.setString('email', email);
    await prefs.setString('userName', userName);
    notifyListeners();
    return true;
  }

  Future<bool> register(String name, String emailValue, String password) async {
    if (validateRegister(name, emailValue, password) != null) {
      return false;
    }
    final prefs = await _prefs();
    isLoggedIn = true;
    userName = name.trim();
    email = emailValue.trim();
    await prefs.setBool('session', true);
    await prefs.setString('email', email);
    await prefs.setString('userName', userName);
    notifyListeners();
    return true;
  }

  Future<void> guest() async {
    final prefs = await _prefs();
    isLoggedIn = true;
    userName = 'Guest';
    email = 'guest@sacred.kg';
    await prefs.setBool('session', true);
    await prefs.setString('email', email);
    await prefs.setString('userName', userName);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await _prefs();
    await prefs.setBool('session', false);
    await prefs.remove('email');
    await prefs.remove('userName');
    isLoggedIn = false;
    userName = 'Guest';
    email = 'guest@sacred.kg';
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final prefs = await _prefs();
    await prefs.clear();
    isLoggedIn = false;
    userName = 'Guest';
    email = 'guest@sacred.kg';
    notifyListeners();
  }
}

class SettingsController extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  String language = 'ky';
  bool musicEnabled = false;
  bool loaded = false;

  static const _themeModeKey = 'themeMode';
  static const _legacyDarkModeKey = 'darkMode';

  SharedPreferences? _prefsCache;

  SettingsController() {
    unawaited(_load());
  }

  Future<SharedPreferences> _prefs() async {
    return _prefsCache ??= await SharedPreferences.getInstance();
  }

  Future<void> _load() async {
    final prefs = await _prefs();
    themeMode = _readThemeMode(prefs);
    language = normalizeLanguageCode(prefs.getString('language'));
    Intl.defaultLocale = language;
    musicEnabled = prefs.getBool('music') ?? false;
    loaded = true;
    notifyListeners();
  }

  ThemeMode _readThemeMode(SharedPreferences prefs) {
    final stored = prefs.getString(_themeModeKey);
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
    }
    // Migration: legacy boolean key.
    if (prefs.containsKey(_legacyDarkModeKey)) {
      return prefs.getBool(_legacyDarkModeKey) == true
          ? ThemeMode.dark
          : ThemeMode.light;
    }
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _prefs();
    String stored;
    switch (mode) {
      case ThemeMode.dark:
        stored = 'dark';
        break;
      case ThemeMode.light:
        stored = 'light';
        break;
      case ThemeMode.system:
        stored = 'system';
        break;
    }
    await prefs.setString(_themeModeKey, stored);
    await prefs.remove(_legacyDarkModeKey);
    themeMode = mode;
    notifyListeners();
  }

  /// Backwards-compatible toggle used by older UI; treats `true` as dark and
  /// `false` as light. Prefer [setThemeMode] for new code.
  Future<void> setDarkMode(bool value) async {
    await setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setLanguage(String value) async {
    final prefs = await _prefs();
    final normalized = normalizeLanguageCode(value);
    await prefs.setString('language', normalized);
    language = normalized;
    Intl.defaultLocale = language;
    notifyListeners();
  }

  Future<void> setMusic(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool('music', value);
    musicEnabled = value;
    notifyListeners();
  }
}

class MockAppState extends ChangeNotifier {
  final Set<String> favorites = {};
  final List<CommunityPost> posts = [...MockData.posts];
  final List<Booking> bookings = MockData.demoBookings();
  final Map<String, List<Comment>> comments = <String, List<Comment>>{};

  SharedPreferences? _prefsCache;

  MockAppState() {
    unawaited(_loadFavorites());
  }

  Future<SharedPreferences> _prefs() async {
    return _prefsCache ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFavorites() async {
    final prefs = await _prefs();
    favorites.addAll(prefs.getStringList('favorites') ?? []);
    notifyListeners();
  }

  Future<void> toggleFavorite(String placeId) async {
    if (favorites.contains(placeId)) {
      favorites.remove(placeId);
    } else {
      favorites.add(placeId);
    }
    final prefs = await _prefs();
    await prefs.setStringList('favorites', favorites.toList());
    notifyListeners();
  }

  void toggleLike(String postId) {
    final post = posts.firstWhere(
      (item) => item.id == postId,
      orElse: () => posts.first,
    );
    post.liked = !post.liked;
    post.likeCount += post.liked ? 1 : -1;
    notifyListeners();
  }

  void addPost(String text, PostType type, String? placeId) {
    posts.insert(
      0,
      CommunityPost(
        id: 'p${DateTime.now().microsecondsSinceEpoch}',
        userName: 'You',
        text: text,
        timestamp: DateTime.now(),
        type: type,
        likeCount: 0,
        commentCount: 0,
        placeId: placeId,
        color: AppTheme.leaf,
      ),
    );
    notifyListeners();
  }

  void addBooking(Booking booking) {
    bookings.insert(0, booking);
    notifyListeners();
  }

  /// Adds a comment to [postId] and increments the visible count.
  void addComment(String postId, String text, {required String userName}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final list = comments.putIfAbsent(postId, () => <Comment>[]);
    list.add(
      Comment(
        userName: userName,
        text: trimmed,
        timestamp: DateTime.now(),
      ),
    );
    final post = posts.firstWhere(
      (item) => item.id == postId,
      orElse: () => posts.first,
    );
    post.commentCount += 1;
    notifyListeners();
  }

  List<Comment> commentsFor(String postId) {
    return List.unmodifiable(comments[postId] ?? const <Comment>[]);
  }
}

/// Lightweight in-memory comment used by the feed bottom sheet.
@immutable
class Comment {
  const Comment({
    required this.userName,
    required this.text,
    required this.timestamp,
  });

  final String userName;
  final String text;
  final DateTime timestamp;
}

/// Reads the active language from the closest [Localizations] in [context]
/// and falls back to the [LocalizedContent.languageCode]. Used to drive the
/// offline AI engine so its replies follow the user's chosen language.
String aiLanguageFromContext(BuildContext context) {
  final localeCode = Localizations.localeOf(context).languageCode;
  return normalizeLanguageCode(localeCode);
}

/// Builds the [LocalAiEngine] using the catalog and current language.
LocalAiEngine buildAiEngine({required String language, AiCharacter? character}) {
  final infos = MockData.places.map((p) {
    final region = MockData.regionByIdOrNull(p.regionId);
    return AiPlaceInfo(
      id: p.id,
      title: p.title,
      shortDescription: p.shortDescription,
      description: p.description,
      culturalNote: p.culturalNote,
      visitingRules: p.visitingRules,
      route: p.route,
      regionId: p.regionId,
      regionName: region?.name ?? '',
      aliases: p.aliasesForAi().toList(),
    );
  }).toList();
  return LocalAiEngine(
    places: infos,
    language: language,
    aiName: character?.name ?? '',
  );
}

/// Backwards compatible wrapper that delegates to [LocalAiEngine].
String mockAiReply({
  required AiCharacter character,
  required String prompt,
  Place? place,
  String? language,
}) {
  final lang = language ?? LocalizedContent.languageCode;
  final engine = buildAiEngine(language: lang, character: character);
  AiPlaceInfo? context;
  if (place != null) {
    context = AiPlaceInfo(
      id: place.id,
      title: place.title,
      shortDescription: place.shortDescription,
      description: place.description,
      culturalNote: place.culturalNote,
      visitingRules: place.visitingRules,
      route: place.route,
      regionId: place.regionId,
      regionName: MockData.regionByIdOrNull(place.regionId)?.name ?? '',
      aliases: place.aliasesForAi().toList(),
    );
  }
  return engine.reply(prompt, contextPlace: context).text;
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    // Schedule the listen for the next frame so we have a valid context.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRedirect(ref.read(authProvider));
    });
  }

  void _maybeRedirect(AuthController auth) {
    if (_redirected || !auth.loaded || !mounted) return;
    _redirected = true;
    final route = auth.isLoggedIn ? '/home' : '/onboarding';
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth changes — when prefs finish loading we navigate.
    ref.listen<AuthController>(authProvider, (previous, next) {
      _maybeRedirect(next);
    });
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Image.asset(
                'assets/images/branding/sacred_kg_logo_512.png',
                width: 168,
                height: 168,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 180,
                  height: 180,
                  child: AnimatedSacredModel(compact: true),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.appTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(l10n.tagline),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Friendly fallback page shown when go_router fails to resolve a route.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.placeNotFound)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.travel_explore, size: 72),
              const SizedBox(height: 12),
              Text(
                l10n.placeNotFound,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: Text(l10n.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the place id does not resolve to a known catalog entry.
class _PlaceNotFoundScreen extends StatelessWidget {
  const _PlaceNotFoundScreen({required this.missingId});

  final String missingId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.placeNotFound),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/catalog');
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 72),
              const SizedBox(height: 12),
              Text(
                l10n.placeNotFound,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                missingId,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/catalog'),
                child: Text(l10n.backToCatalog),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const AnimatedSacredModel(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.onboardingTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.onboardingBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: SizedBox(
                  width: double.infinity,
                  child: Center(child: Text(l10n.login)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => context.go('/register'),
                child: SizedBox(
                  width: double.infinity,
                  child: Center(child: Text(l10n.createAccount)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(authProvider).guest();
                  if (context.mounted) context.go('/home');
                },
                child: Text(l10n.continueAsGuest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;
  bool _busy = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      error = null;
    });
    final l10n = context.l10n;
    final reason = AuthController.validateLogin(email.text, password.text);
    if (reason != null) {
      setState(() {
        _busy = false;
        error = reason == 'auth.error.email'
            ? l10n.invalidEmail
            : reason == 'auth.error.password'
                ? l10n.passwordTooShort
                : l10n.bothFieldsRequired;
      });
      return;
    }
    final ok = await ref
        .read(authProvider)
        .login(email.text, password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      context.go('/home');
    } else {
      setState(() => error = l10n.bothFieldsRequired);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.welcomeBack,
      subtitle: l10n.loginSubtitle,
      children: [
        TextField(
          controller: email,
          autofillHints: const [AutofillHints.email],
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.email,
            hintText: 'name@example.com',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(labelText: l10n.password),
          onSubmitted: (_) => _submit(),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.login),
        ),
        TextButton(
          onPressed: _busy ? null : () => context.go('/register'),
          child: Text(l10n.createAccount),
        ),
      ],
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;
  bool _busy = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      error = null;
    });
    final l10n = context.l10n;
    final reason = AuthController.validateRegister(
      name.text,
      email.text,
      password.text,
    );
    if (reason != null) {
      setState(() {
        _busy = false;
        error = reason == 'auth.error.email'
            ? l10n.invalidEmail
            : reason == 'auth.error.password'
                ? l10n.passwordTooShort
                : l10n.allFieldsRequired;
      });
      return;
    }
    final ok = await ref
        .read(authProvider)
        .register(name.text, email.text, password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      context.go('/home');
    } else {
      setState(() => error = l10n.allFieldsRequired);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.createAccount,
      subtitle: l10n.registerSubtitle,
      children: [
        TextField(
          controller: name,
          autofillHints: const [AutofillHints.name],
          decoration: InputDecoration(labelText: l10n.name),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: email,
          autofillHints: const [AutofillHints.email],
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.email,
            hintText: 'name@example.com',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(labelText: l10n.password),
          onSubmitted: (_) => _submit(),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.register),
        ),
        TextButton(
          onPressed: _busy ? null : () => context.go('/login'),
          child: Text(l10n.alreadyHaveAccount),
        ),
      ],
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const AnimatedSacredModel(compact: true),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(subtitle),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final appState = ref.watch(appStateProvider);
    final featured = [
      MockData.placeById('sulaiman_too'),
      MockData.placeById('cholpon_ata'),
      MockData.placeById('burana'),
      MockData.placeById('arslanbob'),
    ];
    final heroPlace = featured.first;
    final quickActions = [
      (
        t('Seven regions'),
        t('Choose a route'),
        Icons.public,
        '/map',
        AppTheme.leaf,
      ),
      (
        t('Ask Apashka'),
        t('Rules and stories'),
        Icons.auto_awesome,
        '/ai',
        AppTheme.rose,
      ),
      (
        t('Visit request'),
        t('Plan respectfully'),
        Icons.event_available,
        '/booking',
        AppTheme.gold,
      ),
    ];
    final menu = [
      (
        t('Sacred catalog'),
        t('Search shrines, stones, springs'),
        Icons.grid_view_rounded,
        '/catalog',
        AppTheme.clay,
      ),
      (
        t('Community yurt'),
        t('Read tips from visitors'),
        Icons.forum,
        '/feed',
        AppTheme.leaf,
      ),
      (
        t('Language and theme'),
        t('Theme, language, music'),
        Icons.tune,
        '/settings',
        AppTheme.gold,
      ),
      (
        t('Account'),
        t('Bookings and favorites'),
        Icons.person,
        '/account',
        AppTheme.rose,
      ),
    ];
    return AppScaffold(
      selectedIndex: 0,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeTopBar(userName: auth.userName),
                  const SizedBox(height: 12),
                  const _KyrgyzOrnamentBand(),
                  const SizedBox(height: 12),
                  _HomeHeroPanel(place: heroPlace),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _HomeMetric(
                          value: '${MockData.regions.length}',
                          label: t('regions'),
                          icon: Icons.map_outlined,
                          color: AppTheme.leaf,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HomeMetric(
                          value: '${MockData.places.length}',
                          label: t('places'),
                          icon: Icons.place_outlined,
                          color: AppTheme.clay,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HomeMetric(
                          value: '${appState.favorites.length}',
                          label: t('saved'),
                          icon: Icons.favorite_border,
                          color: AppTheme.rose,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _CultureStoryRow(),
                  const SizedBox(height: 22),
                  _HomeSectionHeader(
                    title: t('Pilgrim paths'),
                    action: t('Open catalog'),
                    onAction: () => context.go('/catalog'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 104,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: quickActions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = quickActions[index];
                        return SizedBox(
                              width: 162,
                              child: _HomeQuickAction(
                                title: item.$1,
                                subtitle: item.$2,
                                icon: item.$3,
                                color: item.$5,
                                onTap: () => _openHomeRoute(context, item.$4),
                              ),
                            )
                            .animate(delay: (35 * index).ms)
                            .fadeIn()
                            .slideX(begin: 0.05, end: 0);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HomeSectionHeader(
                    title: t('Sacred highlights'),
                    action: t('See all'),
                    onAction: () => context.go('/catalog'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 218,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: featured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                              width: 286,
                              child: _FeaturedHomePlaceCard(
                                place: featured[index],
                              ),
                            )
                            .animate(delay: (45 * index).ms)
                            .fadeIn()
                            .slideY(begin: 0.04, end: 0);
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _KyrgyzOrnamentBand(compact: true),
                  const SizedBox(height: 16),
                  _HomeSectionHeader(title: t('More to explore')),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: menu.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = menu[index];
                return _HomeToolRow(
                      title: item.$1,
                      subtitle: item.$2,
                      icon: item.$3,
                      color: item.$5,
                      onTap: () => _openHomeRoute(context, item.$4),
                    )
                    .animate(delay: (35 * index).ms)
                    .fadeIn()
                    .slideY(begin: 0.04, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _openHomeRoute(BuildContext context, String route) {
  const primaryRoutes = {'/home', '/map', '/catalog', '/ai', '/account'};
  if (primaryRoutes.contains(route)) {
    context.go(route);
  } else {
    context.push(route);
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${t('Salam')}, ${LocalizedContent.phrase(userName)}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                t('Sacred KG cultural routes'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go('/account'),
          child: Container(
            width: 52,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.rose,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.72)),
            ),
            child: const _TundukMark(size: 28, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _HomeHeroPanel extends StatelessWidget {
  const _HomeHeroPanel({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 336,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSacredModel(place: place, showTitle: false),
            CustomPaint(
              painter: KyrgyzHeroPainter(
                ornament: AppTheme.gold.withValues(alpha: 0.92),
                mountain: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Row(
                children: [
                  _HeroBadge(label: t('Tunduk route')),
                  const SizedBox(width: 8),
                  _HeroBadge(label: MockData.regionById(place.regionId).name),
                ],
              ),
            ),
            const Positioned(
              right: 18,
              top: 18,
              child: _TundukMark(size: 54, color: Colors.white),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Kyrgyz sacred routes'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'Mountains, petroglyphs, springs, and stories held with respect.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.go('/map'),
                          icon: const Icon(Icons.public),
                          label: Text(t('Open regions')),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: () => context.push('/place/${place.id}'),
                        icon: const Icon(Icons.arrow_forward),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: AppTheme.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.04, end: 0);
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _KyrgyzOrnamentBand extends StatelessWidget {
  const _KyrgyzOrnamentBand({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 18 : 28,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: KyrgyzOrnamentPainter(
            base: AppTheme.rose,
            accent: AppTheme.gold,
            secondary: AppTheme.leaf,
            compact: compact,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _TundukMark extends StatelessWidget {
  const _TundukMark({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: TundukPainter(color)),
    );
  }
}

class _CultureStoryRow extends StatelessWidget {
  const _CultureStoryRow();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Tunduk', t('shared sky'), Icons.circle_outlined, AppTheme.rose),
      ('Shyrdak', t('ornament paths'), Icons.diamond_outlined, AppTheme.gold),
      ('Komuz', t('living memory'), Icons.music_note, AppTheme.leaf),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: _CultureStoryTile(
              title: items[i].$1,
              subtitle: items[i].$2,
              icon: items[i].$3,
              color: items[i].$4,
            ).animate(delay: (45 * i).ms).fadeIn().slideY(begin: 0.06, end: 0),
          ),
          if (i != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _CultureStoryTile extends StatelessWidget {
  const _CultureStoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color.lerp(color, Theme.of(context).colorScheme.surface, 0.84),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Icon(icon, color: color.withValues(alpha: 0.18), size: 46),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniOrnament extends StatelessWidget {
  const _MiniOrnament({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 16,
      child: CustomPaint(
        painter: MiniOrnamentPainter(color.withValues(alpha: 0.72)),
      ),
    );
  }
}

class _HomeMetric extends StatelessWidget {
  const _HomeMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (action != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _HomeQuickAction extends StatelessWidget {
  const _HomeQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 17),
                ),
                const Spacer(),
                _MiniOrnament(color: color),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedHomePlaceCard extends StatelessWidget {
  const _FeaturedHomePlaceCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/place/${place.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ArtStrip(place: place),
                  CustomPaint(
                    painter: KyrgyzCornerPainter(
                      color: Colors.white.withValues(alpha: 0.36),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        place.type.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    place.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.gold, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        MockData.regionById(place.regionId).name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeToolRow extends StatelessWidget {
  const _HomeToolRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: KyrgyzCornerPainter(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                  Icon(icon, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class RegionsScreen extends StatelessWidget {
  const RegionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 1,
      title: t('Choose a region'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _RegionsHero(),
          const SizedBox(height: 14),
          const _KyrgyzOrnamentBand(compact: true),
          const SizedBox(height: 16),
          const _RegionStatsRow(),
          const SizedBox(height: 20),
          _DetailSectionTitle(
            title: t('Seven sacred directions'),
            action: t('All places'),
            onAction: () => context.go('/catalog'),
          ),
          const SizedBox(height: 10),
          const _RegionSpotlightStrip(),
          const SizedBox(height: 16),
          _DetailSectionTitle(title: t('Regional routes')),
          const SizedBox(height: 10),
          ...MockData.regions.indexed.map((entry) {
            final index = entry.$1;
            final region = entry.$2;
            final places = MockData.places
                .where((place) => place.regionId == region.id)
                .toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RegionRouteCard(region: region, places: places)
                  .animate(delay: (45 * index).ms)
                  .fadeIn()
                  .slideY(begin: 0.04, end: 0),
            );
          }),
        ],
      ),
    );
  }
}

class _RegionsHero extends StatelessWidget {
  const _RegionsHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 276,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AnimatedKyrgyzstanMap(),
            CustomPaint(
              painter: KyrgyzHeroPainter(
                ornament: AppTheme.gold.withValues(alpha: 0.88),
                mountain: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 16,
              right: 16,
              child: _TundukMark(size: 54, color: Colors.white),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroBadge(label: t('Kyrgyzstan regions')),
                  const SizedBox(height: 10),
                  Text(
                    t('Choose a sacred direction'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'Browse valleys, lake routes, southern mountains, forests, and petroglyph paths.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 340.ms).slideY(begin: 0.03, end: 0);
  }
}

class _RegionStatsRow extends StatelessWidget {
  const _RegionStatsRow();

  @override
  Widget build(BuildContext context) {
    final petroglyphCount = MockData.places
        .where((place) => place.type == PlaceType.petroglyphSite)
        .length;
    final stats = [
      ('7', t('regions'), Icons.public, AppTheme.leaf),
      (
        '${MockData.places.length}',
        t('places'),
        Icons.place_outlined,
        AppTheme.clay,
      ),
      ('$petroglyphCount', t('petroglyphs'), Icons.history_edu, AppTheme.rose),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          Expanded(
            child: _DetailStatTile(
              icon: stats[i].$3,
              value: stats[i].$1,
              label: stats[i].$2,
              color: stats[i].$4,
            ).animate(delay: (35 * i).ms).fadeIn().slideY(begin: 0.04, end: 0),
          ),
          if (i != stats.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _RegionSpotlightStrip extends StatelessWidget {
  const _RegionSpotlightStrip();

  @override
  Widget build(BuildContext context) {
    final spotlight = MockData.regions.take(4).toList();
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: spotlight.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final region = spotlight[index];
          return SizedBox(
                width: 178,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push('/region/${region.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: region.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: KyrgyzCornerPainter(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _TundukMark(size: 30, color: Colors.white),
                            const Spacer(),
                            Text(
                              region.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              region.highlights.first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate(delay: (40 * index).ms)
              .fadeIn()
              .slideX(begin: 0.05, end: 0);
        },
      ),
    );
  }
}

class _RegionRouteCard extends StatelessWidget {
  const _RegionRouteCard({required this.region, required this.places});

  final Region region;
  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final featured = places.isEmpty ? t('No places yet') : places.first.title;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/region/${region.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: region.color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 92,
              decoration: BoxDecoration(
                color: region.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: KyrgyzCornerPainter(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _TundukMark(size: 30, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        '${places.length}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          region.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    region.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: region.highlights
                        .map(
                          (highlight) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: region.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              highlight,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tWith('Featured: {place}', {'place': featured}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({this.regionId, super.key});

  final String? regionId;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final searchController = TextEditingController();
  String query = '';
  String? regionId;
  PlaceType? type;
  bool sortByRating = true;

  @override
  void initState() {
    super.initState();
    regionId = widget.regionId;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var places = MockData.places.where((place) {
      final matchesQuery =
          place.title.toLowerCase().contains(query.toLowerCase()) ||
          place.shortDescription.toLowerCase().contains(query.toLowerCase());
      final matchesRegion = regionId == null || place.regionId == regionId;
      final matchesType = type == null || place.type == type;
      return matchesQuery && matchesRegion && matchesType;
    }).toList();
    places.sort(
      (a, b) => sortByRating
          ? b.rating.compareTo(a.rating)
          : b.popularity.compareTo(a.popularity),
    );
    final regionName = regionId == null
        ? null
        : MockData.regionById(regionId!).name;
    final activeFilterCount =
        (regionId == null ? 0 : 1) + (type == null ? 0 : 1);

    return AppScaffold(
      selectedIndex: 2,
      title: regionName == null
          ? t('Sacred catalog')
          : tWith('{region} places', {'region': regionName}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _CatalogHero(regionName: regionName, resultCount: places.length),
          const SizedBox(height: 14),
          const _KyrgyzOrnamentBand(compact: true),
          const SizedBox(height: 14),
          _CatalogSearchCard(
            controller: searchController,
            query: query,
            activeFilterCount: activeFilterCount,
            onChanged: (value) => setState(() => query = value),
            onClear: () => setState(() {
              searchController.clear();
              query = '';
              regionId = null;
              type = null;
            }),
          ),
          const SizedBox(height: 14),
          _CatalogFilterSection(
            selectedRegionId: regionId,
            selectedType: type,
            sortByRating: sortByRating,
            onRegionSelected: (value) => setState(() => regionId = value),
            onTypeSelected: (value) => setState(() => type = value),
            onSortChanged: (value) => setState(() => sortByRating = value),
          ),
          const SizedBox(height: 18),
          _DetailSectionTitle(
            title: tWith('{count} sacred places', {'count': places.length}),
            action: sortByRating ? t('Top rated') : t('Popular'),
          ),
          const SizedBox(height: 10),
          if (places.isEmpty)
            EmptyView(message: t('No matching places yet.'))
          else
            ...places.indexed.map((entry) {
              final index = entry.$1;
              final place = entry.$2;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CatalogPlaceCard(place: place)
                    .animate(delay: (35 * index).ms)
                    .fadeIn()
                    .slideY(begin: 0.04, end: 0),
              );
            }),
        ],
      ),
    );
  }
}

class _CatalogHero extends StatelessWidget {
  const _CatalogHero({required this.regionName, required this.resultCount});

  final String? regionName;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AnimatedSacredModel(compact: true, showTitle: false),
            CustomPaint(
              painter: KyrgyzHeroPainter(
                ornament: AppTheme.gold.withValues(alpha: 0.88),
                mountain: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.24),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 16,
              right: 16,
              child: _TundukMark(size: 48, color: Colors.white),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroBadge(label: regionName ?? t('All Kyrgyzstan')),
                  const SizedBox(height: 10),
                  Text(
                    t('Sacred catalog'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    tWith(
                      '{count} places with stories, rules, routes, and local mock reviews.',
                      {'count': resultCount},
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.03, end: 0);
  }
}

class _CatalogSearchCard extends StatelessWidget {
  const _CatalogSearchCard({
    required this.controller,
    required this.query,
    required this.activeFilterCount,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final int activeFilterCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _TundukMark(size: 28, color: AppTheme.rose),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t('Find a place by name or story'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (query.isNotEmpty || activeFilterCount > 0)
                TextButton(onPressed: onClear, child: Text(t('Clear'))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: t('Search sacred places'),
              suffixText: activeFilterCount == 0
                  ? null
                  : tWith('{count} filters', {'count': activeFilterCount}),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CatalogFilterSection extends StatelessWidget {
  const _CatalogFilterSection({
    required this.selectedRegionId,
    required this.selectedType,
    required this.sortByRating,
    required this.onRegionSelected,
    required this.onTypeSelected,
    required this.onSortChanged,
  });

  final String? selectedRegionId;
  final PlaceType? selectedType;
  final bool sortByRating;
  final ValueChanged<String?> onRegionSelected;
  final ValueChanged<PlaceType?> onTypeSelected;
  final ValueChanged<bool> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(title: t('Route filters')),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CulturalFilterChip(
                  selected: selectedRegionId == null,
                  label: t('All regions'),
                  color: AppTheme.leaf,
                  onTap: () => onRegionSelected(null),
                ),
                const SizedBox(width: 8),
                ...MockData.regions.map(
                  (region) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CulturalFilterChip(
                      selected: selectedRegionId == region.id,
                      label: region.name,
                      color: region.color,
                      onTap: () => onRegionSelected(region.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CulturalFilterChip(
                  selected: selectedType == null,
                  label: t('All types'),
                  color: AppTheme.clay,
                  onTap: () => onTypeSelected(null),
                ),
                const SizedBox(width: 8),
                ...PlaceType.values.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CulturalFilterChip(
                      selected: selectedType == item,
                      label: item.label,
                      color: AppTheme.rose,
                      onTap: () => onTypeSelected(item),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text(t('Rating')),
                icon: const Icon(Icons.star),
              ),
              ButtonSegment(
                value: false,
                label: Text(t('Popular')),
                icon: const Icon(Icons.trending_up),
              ),
            ],
            selected: {sortByRating},
            onSelectionChanged: (value) => onSortChanged(value.first),
          ),
        ],
      ),
    );
  }
}

class _CulturalFilterChip extends StatelessWidget {
  const _CulturalFilterChip({
    required this.selected,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: selected
          ? const _TundukMark(size: 18, color: Colors.white)
          : null,
      label: Text(label),
      selectedColor: color,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _CatalogPlaceCard extends StatelessWidget {
  const _CatalogPlaceCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/place/${place.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: place.colors.first.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 108,
              height: 140,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ArtStrip(place: place),
                    CustomPaint(
                      painter: KyrgyzCornerPainter(
                        color: Colors.white.withValues(alpha: 0.34),
                      ),
                    ),
                    const Center(
                      child: _TundukMark(size: 38, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      place.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        InfoChip(
                          icon: Icons.place,
                          label: MockData.regionById(place.regionId).name,
                        ),
                        InfoChip(
                          icon: Icons.star,
                          label: place.rating.toStringAsFixed(1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.type.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: place.colors.first,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceDetailScreen extends ConsumerWidget {
  const PlaceDetailScreen({required this.placeId, super.key});

  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foundPlace = MockData.placeByIdOrNull(placeId);
    if (foundPlace == null) {
      return _PlaceNotFoundScreen(missingId: placeId);
    }
    final place = foundPlace;
    final appState = ref.watch(appStateProvider);
    final isFavorite = appState.favorites.contains(place.id);
    final reviews = MockData.reviews
        .where((review) => review.placeId == place.id)
        .toList();
    return AppScaffold(
      title: place.title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _PlaceDetailHero(
            place: place,
            isFavorite: isFavorite,
            onFavorite: () =>
                ref.read(appStateProvider).toggleFavorite(place.id),
          ),
          const SizedBox(height: 14),
          const _KyrgyzOrnamentBand(compact: true),
          const SizedBox(height: 14),
          _PlaceDetailStats(place: place),
          const SizedBox(height: 18),
          _PlaceIntroCard(place: place),
          const SizedBox(height: 14),
          _PlaceActionPanel(place: place),
          const SizedBox(height: 18),
          _DetailSectionTitle(
            title: t('Sacred knowledge'),
            action: t('Ask guide'),
            onAction: () => context.push('/ai?place=${place.id}'),
          ),
          const SizedBox(height: 10),
          SectionBlock(
            title: t('Cultural note'),
            text: place.culturalNote,
            icon: Icons.auto_stories,
          ),
          SectionBlock(
            title: t('Visiting rules'),
            text: place.visitingRules,
            icon: Icons.volunteer_activism,
          ),
          SectionBlock(title: t('Route'), text: place.route, icon: Icons.route),
          const SizedBox(height: 18),
          _DetailSectionTitle(title: t('Place palette')),
          const SizedBox(height: 10),
          _PlacePaletteStrip(place: place),
          const SizedBox(height: 20),
          _DetailSectionTitle(title: t('Visitor voices')),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            EmptyView(message: t('No local reviews for this place yet.'))
          else
            ...reviews.map(
              (review) => _ReviewCard(
                review: review,
              ).animate().fadeIn().slideY(begin: 0.04, end: 0),
            ),
        ],
      ),
    );
  }
}

class _PlaceDetailHero extends StatelessWidget {
  const _PlaceDetailHero({
    required this.place,
    required this.isFavorite,
    required this.onFavorite,
  });

  final Place place;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 372,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSacredModel(place: place, showTitle: false),
            CustomPaint(
              painter: KyrgyzHeroPainter(
                ornament: AppTheme.gold.withValues(alpha: 0.95),
                mountain: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.74),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: Row(
                children: [
                  _HeroBadge(label: MockData.regionById(place.regionId).name),
                  const SizedBox(width: 8),
                  _HeroBadge(label: place.type.label),
                  const Spacer(),
                  IconButton.filled(
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isFavorite
                          ? AppTheme.rose
                          : Colors.white.withValues(alpha: 0.22),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              right: 18,
              top: 74,
              child: _TundukMark(size: 58, color: Colors.white),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.gold, size: 19),
                      const SizedBox(width: 5),
                      Text(
                        '${place.rating.toStringAsFixed(1)} ${t('rating')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${place.reviewsCount} ${t('reviews')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 360.ms).slideY(begin: 0.03, end: 0);
  }
}

class _PlaceDetailStats extends StatelessWidget {
  const _PlaceDetailStats({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        Icons.public,
        MockData.regionById(place.regionId).name,
        t('regions'),
        AppTheme.leaf,
      ),
      (Icons.category_outlined, place.type.label, t('type'), AppTheme.clay),
      (Icons.trending_up, '${place.popularity}', t('popular'), AppTheme.rose),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          Expanded(
            child: _DetailStatTile(
              icon: stats[i].$1,
              value: stats[i].$2,
              label: stats[i].$3,
              color: stats[i].$4,
            ).animate(delay: (40 * i).ms).fadeIn().slideY(begin: 0.05, end: 0),
          ),
          if (i != stats.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _DetailStatTile extends StatelessWidget {
  const _DetailStatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Icon(icon, color: color.withValues(alpha: 0.12), size: 48),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceIntroCard extends StatelessWidget {
  const _PlaceIntroCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TundukMark(size: 28, color: AppTheme.rose),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t('Story of the place'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(place.description),
        ],
      ),
    );
  }
}

class _PlaceActionPanel extends StatelessWidget {
  const _PlaceActionPanel({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.push('/ai?place=${place.id}'),
            icon: const Icon(Icons.auto_awesome),
            label: Text(t('Ask guide')),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/booking?place=${place.id}'),
            icon: const Icon(Icons.event_available),
            label: Text(t('Plan visit')),
          ),
        ),
      ],
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (action != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _PlacePaletteStrip extends StatelessWidget {
  const _PlacePaletteStrip({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: place.colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => Container(
          width: 126,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                place.colors[index],
                place.colors[(index + 1) % place.colors.length],
              ],
            ),
          ),
          child: CustomPaint(
            painter: KyrgyzCornerPainter(
              color: Colors.white.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.leaf,
              child: Text(
                review.user.characters.isNotEmpty
                    ? review.user.characters.first
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.user,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(Icons.star, color: AppTheme.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(review.text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({this.placeId, super.key});

  final String? placeId;

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  late AiCharacter selected = MockData.characters.first;
  final input = TextEditingController();
  final messages = <ChatMessage>[];
  bool _greetingInjected = false;

  Place? get place => MockData.placeByIdOrNull(widget.placeId);

  AiPlaceInfo? get _aiContextPlace {
    final p = place;
    if (p == null) return null;
    return AiPlaceInfo(
      id: p.id,
      title: p.title,
      shortDescription: p.shortDescription,
      description: p.description,
      culturalNote: p.culturalNote,
      visitingRules: p.visitingRules,
      route: p.route,
      regionId: p.regionId,
      regionName: MockData.regionByIdOrNull(p.regionId)?.name ?? '',
      aliases: p.aliasesForAi().toList(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_greetingInjected) return;
    _greetingInjected = true;
    final lang = aiLanguageFromContext(context);
    final engine = buildAiEngine(language: lang, character: selected);
    messages.add(
      ChatMessage(
        text: engine.reply('hi', contextPlace: _aiContextPlace).text,
        fromUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void send([String? preset]) {
    final text = (preset ?? input.text).trim();
    if (text.isEmpty) return;
    final lang = aiLanguageFromContext(context);
    final engine = buildAiEngine(language: lang, character: selected);
    final response = engine.reply(text, contextPlace: _aiContextPlace);
    setState(() {
      messages.add(
        ChatMessage(text: text, fromUser: true, timestamp: DateTime.now()),
      );
      messages.add(
        ChatMessage(
          text: response.text,
          fromUser: false,
          timestamp: DateTime.now(),
        ),
      );
      input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prompts = [
      t('What is special here?'),
      t('What rules should I follow?'),
      t('Best time to visit?'),
      t('How do I get there?'),
    ];
    return AppScaffold(
      selectedIndex: 3,
      title: t('AI guide'),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                _AiGuideHero(place: place, selected: selected),
                const SizedBox(height: 14),
                const _KyrgyzOrnamentBand(compact: true),
                const SizedBox(height: 16),
                _DetailSectionTitle(title: t('Choose your guide')),
                const SizedBox(height: 10),
                Row(
                  children: MockData.characters.map((character) {
                    final isSelected = selected.id == character.id;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: character.id == MockData.characters.first.id
                              ? 6
                              : 0,
                          left: character.id == MockData.characters.first.id
                              ? 0
                              : 6,
                        ),
                        child: _AiCharacterCard(
                          character: character,
                          selected: isSelected,
                          onTap: () => setState(() => selected = character),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _AiPromptStrip(prompts: prompts, onPrompt: send),
                const SizedBox(height: 18),
                _DetailSectionTitle(title: t('Conversation')),
                const SizedBox(height: 10),
                ...messages.indexed.map((entry) {
                  final index = entry.$1;
                  final message = entry.$2;
                  return _ChatBubble(message: message, character: selected)
                      .animate(delay: (20 * index).ms)
                      .fadeIn(duration: 180.ms)
                      .slideY(begin: 0.04, end: 0);
                }),
              ],
            ),
          ),
          _AiInputBar(controller: input, onSend: send),
        ],
      ),
    );
  }
}

class _AiGuideHero extends StatelessWidget {
  const _AiGuideHero({required this.place, required this.selected});

  final Place? place;
  final AiCharacter selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 206,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSacredModel(place: place, compact: true, showTitle: false),
            CustomPaint(
              painter: KyrgyzHeroPainter(
                ornament: AppTheme.gold.withValues(alpha: 0.90),
                mountain: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    selected.color.withValues(alpha: 0.16),
                    Colors.black.withValues(alpha: 0.24),
                    Colors.black.withValues(alpha: 0.74),
                  ],
                ),
              ),
            ),
            const Positioned(
              right: 16,
              top: 16,
              child: _TundukMark(size: 46, color: Colors.white),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroBadge(label: selected.name),
                  const SizedBox(height: 10),
                  Text(
                    place == null ? t('Ask a cultural guide') : place!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    place == null
                        ? t(
                            'Mock guidance for rules, stories, routes, and traditions.',
                          )
                        : t(
                            'Place-aware mock answers for etiquette, stories, and visit planning.',
                          ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.03, end: 0);
  }
}

class _AiCharacterCard extends StatelessWidget {
  const _AiCharacterCard({
    required this.character,
    required this.selected,
    required this.onTap,
  });

  final AiCharacter character;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 126,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? character.color
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: character.color.withValues(alpha: selected ? 0.9 : 0.22),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: KyrgyzCornerPainter(
                  color: (selected ? Colors.white : character.color).withValues(
                    alpha: 0.25,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TundukMark(
                      size: 30,
                      color: selected ? Colors.white : character.color,
                    ),
                    const Spacer(),
                    if (selected)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  character.name,
                  style: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  character.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.88)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AiPromptStrip extends StatelessWidget {
  const _AiPromptStrip({required this.prompts, required this.onPrompt});

  final List<String> prompts;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => ActionChip(
          avatar: const _TundukMark(size: 18, color: AppTheme.rose),
          label: Text(prompts[index]),
          onPressed: () => onPrompt(prompts[index]),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.character});

  final ChatMessage message;
  final AiCharacter character;

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    final bubbleColor = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surface;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(8),
          border: isUser
              ? null
              : Border.all(color: character.color.withValues(alpha: 0.16)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser) ...[
              _TundukMark(size: 22, color: character.color),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiInputBar extends StatelessWidget {
  const _AiInputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: t('Ask about rules, route, or traditions'),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: onSend, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(appStateProvider).posts;
    return AppScaffold(
      title: t('Community'),
      actions: [
        IconButton(
          onPressed: () => context.push('/feed/create'),
          icon: const Icon(Icons.add),
        ),
      ],
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = posts[index];
          final place = post.placeId == null
              ? null
              : MockData.placeById(post.placeId!);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: post.color,
                        child: Text(
                          post.userName.characters.isNotEmpty
                              ? post.userName.characters.first
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, HH:mm').format(post.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Chip(label: Text(post.type.label)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post.text),
                  if (place != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.push('/place/${place.id}'),
                      icon: const Icon(Icons.place),
                      label: Text(place.title),
                    ),
                  ],
                  const Divider(),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            ref.read(appStateProvider).toggleLike(post.id),
                        icon: Icon(
                          post.liked ? Icons.favorite : Icons.favorite_border,
                        ),
                        label: Text('${post.likeCount}'),
                      ),
                      TextButton.icon(
                        onPressed: () => _openCommentSheet(context, ref, post),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text('${post.commentCount}'),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Share',
                        onPressed: () =>
                            _showSharePlaceholder(context, post),
                        icon: const Icon(Icons.share_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

void _showSharePlaceholder(BuildContext context, CommunityPost post) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${post.userName}: ${post.text}'),
      duration: const Duration(seconds: 2),
    ),
  );
}

Future<void> _openCommentSheet(
  BuildContext context,
  WidgetRef ref,
  CommunityPost post,
) async {
  final controller = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (innerContext, setSheetState) {
            final l10n = innerContext.l10n;
            final comments = ref.watch(appStateProvider).commentsFor(post.id);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${post.userName}: ${post.text}',
                  style: Theme.of(innerContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.noComments,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const Divider(height: 8),
                      itemBuilder: (_, index) {
                        final c = comments[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 14,
                            child: Text(
                              c.userName.isNotEmpty
                                  ? c.userName.characters.first
                                  : '?',
                            ),
                          ),
                          title: Text(c.userName),
                          subtitle: Text(c.text),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: l10n.commentPlaceholder,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.send),
                      label: Text(l10n.send),
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isEmpty) return;
                        ref.read(appStateProvider).addComment(
                              post.id,
                              value,
                              userName:
                                  ref.read(authProvider).userName,
                            );
                        controller.clear();
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    },
  );
  controller.dispose();
}

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final text = TextEditingController();
  PostType type = PostType.experience;
  String? placeId;

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: t('New post'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: text,
            minLines: 5,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: t('Share a review, tip, issue, or experience'),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PostType>(
            initialValue: type,
            decoration: InputDecoration(labelText: t('Post type')),
            items: PostType.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(),
            onChanged: (value) => setState(() => type = value ?? type),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: placeId,
            decoration: InputDecoration(labelText: t('Related place')),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(t('No place')),
              ),
              ...MockData.places.map(
                (place) => DropdownMenuItem<String?>(
                  value: place.id,
                  child: Text(place.title),
                ),
              ),
            ],
            onChanged: (value) => setState(() => placeId = value),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              if (text.text.trim().isEmpty) return;
              ref
                  .read(appStateProvider)
                  .addPost(text.text.trim(), type, placeId);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/feed');
              }
            },
            child: Text(t('Publish locally')),
          ),
        ],
      ),
    );
  }
}

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({this.placeId, super.key});

  final String? placeId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late String selectedPlaceId = widget.placeId ?? MockData.places.first.id;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
  int people = 2;
  bool confirmed = false;
  bool _submitting = false;
  final notes = TextEditingController();

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      selectedDate = DateTime.now().add(const Duration(days: 3));
      people = 2;
      confirmed = false;
      notes.clear();
    });
  }

  Future<void> _submit(Place place) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    ref.read(appStateProvider).addBooking(
          Booking(
            id: 'b${DateTime.now().microsecondsSinceEpoch}',
            placeId: place.id,
            placeTitle: place.title,
            date: selectedDate,
            peopleCount: people,
            notes: notes.text.trim(),
            rulesConfirmed: confirmed,
            status: BookingStatus.pending,
            createdAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('Visit request saved locally.'))),
    );
    _resetForm();
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(appStateProvider).bookings;
    final place = MockData.placeById(selectedPlaceId);
    return AppScaffold(
      title: t('Booking request'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _BookingHero(place: place),
          const SizedBox(height: 14),
          const _KyrgyzOrnamentBand(compact: true),
          const SizedBox(height: 16),
          _DetailSectionTitle(title: t('Plan your visit')),
          const SizedBox(height: 10),
          _BookingFormCard(
            title: t('1. Sacred place'),
            subtitle: t('Choose where the visit request should go.'),
            icon: Icons.place_outlined,
            color: AppTheme.leaf,
            child: DropdownButtonFormField<String>(
              initialValue: selectedPlaceId,
              decoration: InputDecoration(labelText: t('Place')),
              items: MockData.places
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.title),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => selectedPlaceId = value ?? selectedPlaceId),
            ),
          ),
          const SizedBox(height: 12),
          _BookingDateCard(
            date: selectedDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: selectedDate,
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
          const SizedBox(height: 12),
          _BookingPeopleCard(
            people: people,
            onDecrease: people > 1 ? () => setState(() => people--) : null,
            onIncrease: () => setState(() => people++),
          ),
          const SizedBox(height: 12),
          _BookingFormCard(
            title: t('4. Notes for the visit'),
            subtitle: t(
              'Add guide requests, transport notes, or accessibility needs.',
            ),
            icon: Icons.edit_note,
            color: AppTheme.clay,
            child: TextField(
              controller: notes,
              minLines: 3,
              maxLines: 4,
              decoration: InputDecoration(labelText: t('Optional notes')),
            ),
          ),
          const SizedBox(height: 12),
          _RulesConfirmationCard(
            confirmed: confirmed,
            onChanged: (value) => setState(() => confirmed = value),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: confirmed && !_submitting ? () => _submit(place) : null,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t('Send visit request')),
          ),
          const SizedBox(height: 24),
          _DetailSectionTitle(title: t('My visit requests')),
          const SizedBox(height: 10),
          ...bookings.map(
            (booking) => _BookingHistoryCard(
              booking: booking,
            ).animate().fadeIn().slideY(begin: 0.04, end: 0),
          ),
        ],
      ),
    );
  }
}

class _BookingHero extends StatelessWidget {
  const _BookingHero({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSacredModel(place: place, compact: true, showTitle: false),
            CustomPaint(
              painter: KyrgyzHeroPainter(
                ornament: AppTheme.gold.withValues(alpha: 0.9),
                mountain: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.26),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            const Positioned(
              right: 16,
              top: 16,
              child: _TundukMark(size: 46, color: Colors.white),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroBadge(label: t('Respectful visit')),
                  const SizedBox(height: 10),
                  Text(
                    place.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(
                      'Choose date, group size, and rules before sending a local request.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.90),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.03, end: 0);
  }
}

class _BookingFormCard extends StatelessWidget {
  const _BookingFormCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.04, end: 0);
  }
}

class _BookingDateCard extends StatelessWidget {
  const _BookingDateCard({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('d').format(date);
    final month = DateFormat('MMM').format(date).toUpperCase();
    final weekday = DateFormat('EEEE').format(date);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 82,
              decoration: BoxDecoration(
                color: AppTheme.rose,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: KyrgyzCornerPainter(
                        color: Colors.white.withValues(alpha: 0.26),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        month,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        day,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('2. Visit date'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text('$weekday, ${DateFormat('MMMM d, y').format(date)}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.nightlight_round,
                        size: 16,
                        color: AppTheme.gold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t('Moon marker: mock calendar'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.04, end: 0);
  }
}

class _BookingPeopleCard extends StatelessWidget {
  const _BookingPeopleCard({
    required this.people,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int people;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return _BookingFormCard(
      title: t('3. Visitors'),
      subtitle: t('Keep the group size clear for local planning.'),
      icon: Icons.groups_2_outlined,
      color: AppTheme.leaf,
      child: Row(
        children: [
          IconButton.outlined(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$people',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(t('people'), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton.outlined(
            onPressed: onIncrease,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _RulesConfirmationCard extends StatelessWidget {
  const _RulesConfirmationCard({
    required this.confirmed,
    required this.onChanged,
  });

  final bool confirmed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!confirmed),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: confirmed
              ? AppTheme.leaf.withValues(alpha: 0.12)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: confirmed
                ? AppTheme.leaf
                : AppTheme.rose.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: confirmed,
              onChanged: (value) => onChanged(value ?? false),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('5. Visiting rules'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(
                      'I will keep the place clean, respect prayer or ritual spaces, and follow local guidance.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.04, end: 0);
  }
}

class _BookingHistoryCard extends StatelessWidget {
  const _BookingHistoryCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (booking.status) {
      BookingStatus.pending => AppTheme.gold,
      BookingStatus.approved => AppTheme.leaf,
      BookingStatus.rejected => AppTheme.rose,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 58,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: KyrgyzCornerPainter(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                  const Icon(Icons.event_available, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.placeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM d, y').format(booking.date)} - ${booking.peopleCount} ${t('people')}',
                  ),
                  if (booking.notes.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      booking.notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Chip(label: Text(booking.status.label)),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.settings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.darkTheme} / ${l10n.lightTheme} / ${l10n.systemTheme}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.savedLocally,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.settings_brightness),
                        label: Text(l10n.systemTheme),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode),
                        label: Text(l10n.lightTheme),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode),
                        label: Text(l10n.darkTheme),
                      ),
                    ],
                    selected: <ThemeMode>{settings.themeMode},
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) return;
                      ref
                          .read(settingsProvider)
                          .setThemeMode(selection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: settings.language,
            decoration: InputDecoration(labelText: l10n.language),
            items: AppLocalizations.supportedLocales.map((locale) {
              final code = locale.languageCode;
              return DropdownMenuItem(
                value: code,
                child: Text(languageLabel(context, code)),
              );
            }).toList(),
            onChanged: (value) =>
                ref.read(settingsProvider).setLanguage(value ?? 'ky'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: settings.musicEnabled,
            title: Text(l10n.music),
            subtitle: Text(l10n.mockSettingOnly),
            onChanged: (value) => ref.read(settingsProvider).setMusic(value),
          ),
          const SizedBox(height: 16),
          SectionBlock(
            title: l10n.contactDevelopers,
            text: 'hack2026@sacred.kg',
            icon: Icons.mail,
          ),
          SectionBlock(
            title: l10n.about,
            text: l10n.aboutText,
            icon: Icons.info,
          ),
        ],
      ),
    );
  }
}

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(appStateProvider);
    final l10n = context.l10n;
    final displayName = LocalizedContent.phrase(auth.userName);
    final favorites = MockData.places
        .where((place) => state.favorites.contains(place.id))
        .toList();
    return AppScaffold(
      selectedIndex: 4,
      title: l10n.account,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppTheme.leaf,
                    child: Text(
                      displayName.characters.isNotEmpty
                          ? displayName.characters.first.toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(auth.email),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.favorites,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (favorites.isEmpty)
            EmptyView(message: l10n.favoritePlacesEmpty)
          else
            ...favorites.map((place) => PlaceCard(place: place, wide: true)),
          const SizedBox(height: 18),
          Text(
            l10n.myBookings,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...state.bookings.map(
            (booking) => Card(
              child: ListTile(
                title: Text(booking.placeTitle),
                subtitle: Text(DateFormat('MMM d, y').format(booking.date)),
                trailing: Chip(label: Text(booking.status.label)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.shortcuts,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _HomeToolRow(
            title: l10n.communityFeed,
            subtitle: l10n.visitorTips,
            icon: Icons.forum_outlined,
            color: AppTheme.leaf,
            onTap: () => context.push('/feed'),
          ),
          const SizedBox(height: 8),
          _HomeToolRow(
            title: l10n.bookingRequests,
            subtitle: l10n.planAnotherVisit,
            icon: Icons.event_available,
            color: AppTheme.gold,
            onTap: () => context.push('/booking'),
          ),
          const SizedBox(height: 8),
          _HomeToolRow(
            title: l10n.settings,
            subtitle: l10n.themeLanguageMusic,
            icon: Icons.tune,
            color: AppTheme.clay,
            onTap: () => context.push('/settings'),
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: () async {
              await ref.read(authProvider).logout();
              if (context.mounted) context.go('/onboarding');
            },
            icon: const Icon(Icons.logout),
            label: Text(l10n.logout),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.deleteAccountQuestion),
                  content: Text(l10n.deleteAccountBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authProvider).deleteAccount();
                if (context.mounted) context.go('/onboarding');
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
  }
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.child,
    this.title,
    this.actions,
    this.selectedIndex,
    super.key,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final path = GoRouterState.of(context).uri.path;
    final navIndex = selectedIndex ?? _navIndexForPath(path);
    return PopScope(
      canPop: context.canPop() || path == '/home',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && path != '/home') {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: title == null
            ? null
            : AppBar(title: Text(title!), actions: actions),
        body: SafeArea(top: title == null, child: child),
        bottomNavigationBar:
            NavigationBar(
                  selectedIndex: navIndex,
                  animationDuration: const Duration(milliseconds: 420),
                  onDestinationSelected: (index) {
                    final routes = [
                      '/home',
                      '/map',
                      '/catalog',
                      '/ai',
                      '/account',
                    ];
                    context.go(routes[index]);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: l10n.home,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.public_outlined),
                      selectedIcon: const Icon(Icons.public),
                      label: l10n.regions,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.grid_view_outlined),
                      selectedIcon: const Icon(Icons.grid_view_rounded),
                      label: l10n.places,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.auto_awesome_outlined),
                      selectedIcon: const Icon(Icons.auto_awesome),
                      label: l10n.ai,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: const Icon(Icons.person),
                      label: l10n.account,
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 180.ms)
                .slideY(begin: 0.18, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}

int _navIndexForPath(String path) {
  if (path.startsWith('/map') || path.startsWith('/region')) {
    return 1;
  }
  if (path.startsWith('/catalog') || path.startsWith('/place')) {
    return 2;
  }
  if (path.startsWith('/ai')) {
    return 3;
  }
  if (path.startsWith('/account') ||
      path.startsWith('/feed') ||
      path.startsWith('/booking') ||
      path.startsWith('/settings')) {
    return 4;
  }
  return 0;
}

class PlaceCard extends StatelessWidget {
  const PlaceCard({required this.place, this.wide = false, super.key});

  final Place place;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/place/${place.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: wide
            ? Row(
                children: [
                  _ArtStrip(place: place, width: 92),
                  Expanded(child: _PlaceText(place: place)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _ArtStrip(place: place)),
                  _PlaceText(place: place, compact: true),
                ],
              ),
      ),
    );
  }
}

class _ArtStrip extends StatelessWidget {
  const _ArtStrip({required this.place, this.width});

  final Place place;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: place.colors,
        ),
      ),
      child: CustomPaint(
        painter: PetroglyphPatternPainter(Colors.white.withValues(alpha: 0.45)),
      ),
    );
    return SizedBox(
      width: width,
      child: PlaceImage(
        assetPath: place.imageAsset,
        fallback: fallback,
      ),
    );
  }
}

class _PlaceText extends StatelessWidget {
  const _PlaceText({required this.place, this.compact = false});

  final Place place;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            place.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            place.shortDescription,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: AppTheme.gold),
              const SizedBox(width: 4),
              Text(place.rating.toStringAsFixed(1)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  MockData.regionById(place.regionId).name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}

class SectionBlock extends StatelessWidget {
  const SectionBlock({
    required this.title,
    required this.text,
    required this.icon,
    super.key,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(child: Text(message)),
    );
  }
}

class AnimatedSacredModel extends StatefulWidget {
  const AnimatedSacredModel({
    this.place,
    this.compact = false,
    this.showTitle = true,
    super.key,
  });

  final Place? place;
  final bool compact;
  final bool showTitle;

  @override
  State<AnimatedSacredModel> createState() => _AnimatedSacredModelState();
}

class _AnimatedSacredModelState extends State<AnimatedSacredModel>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        widget.place?.colors ??
        const [AppTheme.leaf, AppTheme.gold, AppTheme.rose];
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final turn = controller.value * math.pi * 2;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.first,
                colors[1 % colors.length],
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: PetroglyphPatternPainter(
                  Colors.white.withValues(alpha: 0.18),
                ),
              ),
              Align(
                alignment: Alignment(0, widget.compact ? 0.2 : 0.34),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0016)
                    ..rotateY(math.sin(turn) * 0.35)
                    ..rotateX(-0.58 + math.cos(turn) * 0.04),
                  child: SizedBox(
                    width: widget.compact ? 150 : 230,
                    height: widget.compact ? 150 : 220,
                    child: CustomPaint(
                      painter: SacredStoneModelPainter(
                        primary: colors.first,
                        accent: colors.length > 1 ? colors[1] : AppTheme.gold,
                        glow: colors.length > 2 ? colors[2] : AppTheme.rose,
                        progress: controller.value,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.showTitle)
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Text(
                    widget.place?.title ?? t('Kyrgyz sacred routes'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      shadows: const [Shadow(blurRadius: 10)],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class AnimatedKyrgyzstanMap extends StatefulWidget {
  const AnimatedKyrgyzstanMap({super.key});

  @override
  State<AnimatedKyrgyzstanMap> createState() => _AnimatedKyrgyzstanMapState();
}

class _AnimatedKyrgyzstanMapState extends State<AnimatedKyrgyzstanMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CustomPaint(
        painter: RegionMapPainter(progress: controller.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class KyrgyzOrnamentPainter extends CustomPainter {
  KyrgyzOrnamentPainter({
    required this.base,
    required this.accent,
    required this.secondary,
    required this.compact,
  });

  final Color base;
  final Color accent;
  final Color secondary;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: [base, Color.lerp(base, secondary, 0.36)!, secondary],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final step = compact ? 34.0 : 42.0;
    final centerY = size.height / 2;
    for (var x = -step; x < size.width + step; x += step) {
      final diamond = Path()
        ..moveTo(x + step * 0.50, 2)
        ..lineTo(x + step * 0.86, centerY)
        ..lineTo(x + step * 0.50, size.height - 2)
        ..lineTo(x + step * 0.14, centerY)
        ..close();
      canvas.drawPath(diamond, Paint()..color = accent.withValues(alpha: 0.90));

      final inner = Path()
        ..moveTo(x + step * 0.50, size.height * 0.24)
        ..lineTo(x + step * 0.68, centerY)
        ..lineTo(x + step * 0.50, size.height * 0.76)
        ..lineTo(x + step * 0.32, centerY)
        ..close();
      canvas.drawPath(
        inner,
        Paint()..color = Colors.white.withValues(alpha: 0.64),
      );

      final hookPaint = Paint()
        ..color = Colors.white.withValues(alpha: compact ? 0.26 : 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 1.2 : 1.6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(x + step * 0.22, centerY),
          width: step * 0.42,
          height: step * 0.42,
        ),
        -math.pi / 2,
        math.pi,
        false,
        hookPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(x + step * 0.78, centerY),
          width: step * 0.42,
          height: step * 0.42,
        ),
        math.pi / 2,
        math.pi,
        false,
        hookPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant KyrgyzOrnamentPainter oldDelegate) {
    return oldDelegate.base != base ||
        oldDelegate.accent != accent ||
        oldDelegate.secondary != secondary ||
        oldDelegate.compact != compact;
  }
}

class TundukPainter extends CustomPainter {
  TundukPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, size.width * 0.07)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint);
    canvas.drawLine(
      Offset(center.dx - radius * 0.68, center.dy),
      Offset(center.dx + radius * 0.68, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.68),
      Offset(center.dx, center.dy + radius * 0.68),
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.58),
      -math.pi * 0.88,
      math.pi * 1.76,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant TundukPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class MiniOrnamentPainter extends CustomPainter {
  MiniOrnamentPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.10, 2, size.width * 0.28, size.height - 4),
      math.pi,
      math.pi,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.62, 2, size.width * 0.28, size.height - 4),
      0,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant MiniOrnamentPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class KyrgyzHeroPainter extends CustomPainter {
  KyrgyzHeroPainter({required this.ornament, required this.mountain});

  final Color ornament;
  final Color mountain;

  @override
  void paint(Canvas canvas, Size size) {
    final mountainPaint = Paint()..color = mountain;
    final mountainPath = Path()
      ..moveTo(0, size.height * 0.56)
      ..lineTo(size.width * 0.18, size.height * 0.42)
      ..lineTo(size.width * 0.30, size.height * 0.50)
      ..lineTo(size.width * 0.47, size.height * 0.35)
      ..lineTo(size.width * 0.64, size.height * 0.53)
      ..lineTo(size.width * 0.82, size.height * 0.40)
      ..lineTo(size.width, size.height * 0.58)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(mountainPath, mountainPaint);

    final linePaint = Paint()
      ..color = ornament
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final sideX = size.width - 22;
    for (var y = size.height * 0.22; y < size.height * 0.78; y += 38) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(sideX, y), width: 30, height: 30),
        math.pi / 2,
        math.pi,
        false,
        linePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(22, y + 18), width: 30, height: 30),
        -math.pi / 2,
        math.pi,
        false,
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant KyrgyzHeroPainter oldDelegate) {
    return oldDelegate.ornament != ornament || oldDelegate.mountain != mountain;
  }
}

class KyrgyzCornerPainter extends CustomPainter {
  KyrgyzCornerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(12, 12), Offset(size.width * 0.32, 12), paint);
    canvas.drawLine(
      const Offset(12, 12),
      Offset(12, size.height * 0.32),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(12, 12, 28, 28),
      0,
      math.pi * 1.5,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 12, size.height - 12),
      Offset(size.width * 0.68, size.height - 12),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 12, size.height - 12),
      Offset(size.width - 12, size.height * 0.68),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant KyrgyzCornerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class SacredStoneModelPainter extends CustomPainter {
  SacredStoneModelPainter({
    required this.primary,
    required this.accent,
    required this.glow,
    required this.progress,
  });

  final Color primary;
  final Color accent;
  final Color glow;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.82),
        width: size.width * 0.8,
        height: size.height * 0.16,
      ),
      shadow,
    );

    final base = Paint()
      ..shader = LinearGradient(
        colors: [primary, accent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final side = Paint()..color = Color.lerp(primary, Colors.black, 0.24)!;
    final cap = Paint()..color = Color.lerp(accent, Colors.white, 0.16)!;

    final body = Path()
      ..moveTo(size.width * 0.28, size.height * 0.78)
      ..lineTo(size.width * 0.39, size.height * 0.20)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.10,
        size.width * 0.61,
        size.height * 0.20,
      )
      ..lineTo(size.width * 0.72, size.height * 0.78)
      ..close();
    final sidePath = Path()
      ..moveTo(size.width * 0.61, size.height * 0.20)
      ..lineTo(size.width * 0.72, size.height * 0.78)
      ..lineTo(size.width * 0.58, size.height * 0.86)
      ..lineTo(size.width * 0.50, size.height * 0.24)
      ..close();
    final capPath = Path()
      ..moveTo(size.width * 0.39, size.height * 0.20)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.10,
        size.width * 0.61,
        size.height * 0.20,
      )
      ..lineTo(size.width * 0.50, size.height * 0.24)
      ..close();

    canvas.drawPath(body, base);
    canvas.drawPath(sidePath, side);
    canvas.drawPath(capPath, cap);

    final orbit = progress * math.pi * 2;
    final glowPaint = Paint()
      ..color = glow.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final y = size.height * (0.38 + math.sin(orbit) * 0.025);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, y),
        width: size.width * 0.34,
        height: size.height * 0.12,
      ),
      math.pi * 0.08,
      math.pi * 1.45,
      false,
      glowPaint,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.43, size.height * 0.52),
      Offset(size.width * 0.57, size.height * 0.52),
      linePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.46),
      size.width * 0.035,
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.50),
      Offset(size.width * 0.50, size.height * 0.62),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.57),
      Offset(size.width * 0.44, size.height * 0.66),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.57),
      Offset(size.width * 0.58, size.height * 0.66),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant SacredStoneModelPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.primary != primary;
  }
}

class PetroglyphPatternPainter extends CustomPainter {
  PetroglyphPatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final x = ((i * 57) % math.max(size.width, 1.0)).toDouble();
      final y = (24 + (i * 41) % math.max(size.height - 48, 1.0)).toDouble();
      canvas.drawCircle(Offset(x + 18, y), 8, paint);
      canvas.drawLine(Offset(x + 18, y + 8), Offset(x + 18, y + 26), paint);
      canvas.drawLine(Offset(x + 18, y + 17), Offset(x + 5, y + 28), paint);
      canvas.drawLine(Offset(x + 18, y + 17), Offset(x + 34, y + 28), paint);
    }
  }

  @override
  bool shouldRepaint(covariant PetroglyphPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}

class RegionMapPainter extends CustomPainter {
  RegionMapPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.leaf, AppTheme.gold],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);
    final regionPaint = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.75);
    for (var i = 0; i < MockData.regions.length; i++) {
      final region = MockData.regions[i];
      regionPaint.color = region.color.withValues(alpha: 0.78);
      final x = size.width * (0.10 + (i % 4) * 0.22);
      final y =
          size.height *
          (0.28 + (i ~/ 4) * 0.28 + math.sin(progress * math.pi + i) * 0.015);
      final rect = Rect.fromCenter(
        center: Offset(x + size.width * 0.08, y),
        width: size.width * 0.19,
        height: size.height * 0.22,
      );
      final path = Path()
        ..moveTo(rect.left, rect.center.dy)
        ..lineTo(rect.left + rect.width * 0.25, rect.top)
        ..lineTo(rect.right - rect.width * 0.16, rect.top + rect.height * 0.08)
        ..lineTo(rect.right, rect.center.dy)
        ..lineTo(rect.right - rect.width * 0.22, rect.bottom)
        ..lineTo(
          rect.left + rect.width * 0.10,
          rect.bottom - rect.height * 0.08,
        )
        ..close();
      canvas.drawPath(path, regionPaint);
      canvas.drawPath(path, stroke);
      final textPainter = TextPainter(
        text: TextSpan(
          text: region.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: rect.width);
      textPainter.paint(canvas, Offset(rect.left + 5, rect.center.dy - 8));
    }
  }

  @override
  bool shouldRepaint(covariant RegionMapPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
