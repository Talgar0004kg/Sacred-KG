import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:hack2026/app_localizations.dart';
import 'package:hack2026/main.dart';

void main() {
  final originalLocale = Intl.defaultLocale;

  tearDown(() {
    // Restore the global default locale between tests so one test's
    // mutation doesn't leak into the next.
    Intl.defaultLocale = originalLocale;
  });

  test('normalizes supported language codes', () {
    expect(normalizeLanguageCode('EN'), 'en');
    expect(normalizeLanguageCode('RU'), 'ru');
    expect(normalizeLanguageCode('KG'), 'ky');
    expect(normalizeLanguageCode('ky'), 'ky');
    expect(normalizeLanguageCode('unknown'), 'ky');
  });

  test('mock catalog data follows the active locale', () {
    Intl.defaultLocale = 'ky';
    expect(MockData.regionById('chuy').name, 'Чүй');
    expect(MockData.placeById('burana').title, 'Бурана мунарасы');
    expect(PlaceType.sacredSpring.label, 'Ыйык булак');

    Intl.defaultLocale = 'ru';
    expect(MockData.regionById('chuy').name, 'Чуй');
    expect(MockData.placeById('burana').title, 'Башня Бурана');
    expect(PostType.tip.label, 'Совет');

    Intl.defaultLocale = 'en';
  });

  testWidgets('Russian and Kyrgyz localization values load', (tester) async {
    await tester.pumpWidget(
      const _LocalizedTextHarness(
        locale: Locale('ru'),
        labelKey: _LabelKey.settings,
      ),
    );
    await tester.pump();

    expect(
      find.text(const AppLocalizations(Locale('ru')).settings),
      findsOneWidget,
    );

    await tester.pumpWidget(
      const _LocalizedTextHarness(
        locale: Locale('ky'),
        labelKey: _LabelKey.settings,
      ),
    );
    await tester.pump();

    expect(
      find.text(const AppLocalizations(Locale('ky')).settings),
      findsOneWidget,
    );
  });
}

enum _LabelKey { settings }

class _LocalizedTextHarness extends StatelessWidget {
  const _LocalizedTextHarness({required this.locale, required this.labelKey});

  final Locale locale;
  final _LabelKey labelKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          return Text(switch (labelKey) {
            _LabelKey.settings => context.l10n.settings,
          });
        },
      ),
    );
  }
}
