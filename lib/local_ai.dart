// Offline AI guide engine for Sacred KG.
//
// The engine answers in three languages (English, Russian, Kyrgyz) about the
// sacred and tourist places of Kyrgyzstan plus general travel questions about
// the country. It is fully offline — no network calls.
//
// Highlights:
//   * Aggressive text normalization so the engine forgives typos, mixed
//     scripts, swapped letters (ё↔е, ы↔и, ң↔н, ө↔о, ү↔у), Latin/Cyrillic
//     transliteration and small spelling mistakes (Levenshtein ≤ 2).
//   * Multi-intent reasoning: a single user message can ask about history AND
//     route AND rules — the engine builds a layered, guide-style answer made
//     of several blocks rather than a single template.
//   * Tour-guide personality: every reply ends with a fun fact, a light joke
//     or an interesting cultural tip selected randomly from a built-in pool.
//   * General Kyrgyzstan knowledge: food, drinks, currency, transport,
//     etiquette, language tips, yurts, nomadic traditions, weather, safety.
//
// Public entry point: [LocalAiEngine.reply].

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// What the user wants to know.
enum LocalAiIntent {
  greeting,
  rules,
  history,
  route,
  timing,
  traditions,
  general,
  list,
  thanks,
  funFact,
  joke,
  food,
  language,
  money,
  safety,
  yurt,
  nomad,
  offTopic,
  unknown,
}

/// Result of [LocalAiEngine.reply].
@immutable
class LocalAiResponse {
  const LocalAiResponse({
    required this.text,
    required this.intent,
    this.placeId,
  });

  final String text;
  final LocalAiIntent intent;
  final String? placeId;
}

/// Catalog metadata the engine needs about a place.
@immutable
class AiPlaceInfo {
  const AiPlaceInfo({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.description,
    required this.culturalNote,
    required this.visitingRules,
    required this.route,
    required this.regionId,
    required this.regionName,
    required this.aliases,
  });

  final String id;
  final String title;
  final String shortDescription;
  final String description;
  final String culturalNote;
  final String visitingRules;
  final String route;
  final String regionId;
  final String regionName;
  final List<String> aliases;
}

class LocalAiEngine {
  LocalAiEngine({
    required this.places,
    required this.language,
    this.aiName = '',
    math.Random? random,
  }) : _random = random ?? math.Random();

  final List<AiPlaceInfo> places;
  final String language;
  final String aiName;
  final math.Random _random;

  // ---------------------------------------------------------------------------
  // Normalization
  // ---------------------------------------------------------------------------

  /// Strict normalization: lowercase, fold typographic variants, treat Kyrgyz
  /// specific letters as their nearest Russian equivalents, transliterate
  /// Latin → Cyrillic for the most common patterns, drop punctuation.
  static String _normalize(String input) {
    var s = input.toLowerCase().trim();
    // Map Kyrgyz-specific Cyrillic letters to their Russian equivalents.
    const folds = {
      'ё': 'е',
      'й': 'и',
      'ң': 'н',
      'ө': 'о',
      'ү': 'у',
      'ұ': 'у',
      'қ': 'к',
      'ғ': 'г',
      'һ': 'х',
      'ы': 'и',
      'э': 'е',
    };
    final buffer = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(folds[ch] ?? ch);
    }
    s = buffer.toString();
    // Light Latin → Cyrillic transliteration for common KG/RU words written
    // in Latin (e.g. "burana", "ysyk-kol", "tash-rabat", "salam").
    const translit = {
      'sh': 'ш', 'ch': 'ч', 'yu': 'ю', 'ya': 'я', 'kh': 'х', 'ts': 'ц',
      'zh': 'ж', 'ee': 'и', 'oo': 'у', 'ai': 'ай',
    };
    for (final entry in translit.entries) {
      s = s.replaceAll(entry.key, entry.value);
    }
    const single = {
      'a': 'а', 'b': 'б', 'c': 'к', 'd': 'д', 'e': 'е', 'f': 'ф', 'g': 'г',
      'h': 'х', 'i': 'и', 'j': 'ж', 'k': 'к', 'l': 'л', 'm': 'м', 'n': 'н',
      'o': 'о', 'p': 'п', 'q': 'к', 'r': 'р', 's': 'с', 't': 'т', 'u': 'у',
      'v': 'в', 'w': 'в', 'x': 'кс', 'y': 'и', 'z': 'з',
    };
    final translitBuf = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      translitBuf.write(single[ch] ?? ch);
    }
    s = translitBuf.toString();
    // Drop everything that is not a Cyrillic / digit / whitespace.
    s = s.replaceAll(RegExp(r'[^а-яё0-9\s-]', unicode: true), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Tokenize a normalized string into individual words.
  static List<String> _tokens(String normalized) {
    return normalized
        .split(RegExp(r'[\s\-]+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  /// Levenshtein distance — small footprint iterative implementation.
  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = math.min(
          math.min(curr[j - 1] + 1, prev[j] + 1),
          prev[j - 1] + cost,
        );
      }
      prev = List<int>.from(curr);
    }
    return prev[b.length];
  }

  /// Returns true if [token] looks like [keyword] given normalized strings.
  /// Allows up to 1 typo for keywords ≥ 4 chars and up to 2 for ≥ 7.
  static bool _fuzzyMatch(String token, String keyword) {
    if (token == keyword) return true;
    if (keyword.length >= 4 && token.startsWith(keyword)) return true;
    if (keyword.length >= 5 && keyword.startsWith(token) && token.length >= 4) {
      return true;
    }
    if (keyword.length >= 4 && token.contains(keyword)) return true;
    if (token.length < 3) return false;
    final budget = keyword.length >= 7
        ? 2
        : keyword.length >= 5
            ? 1
            : 0;
    if (budget == 0) return false;
    return _levenshtein(token, keyword) <= budget;
  }

  // ---------------------------------------------------------------------------
  // Vocabulary keyed by intent.
  // ---------------------------------------------------------------------------

  static const Map<LocalAiIntent, List<String>> _intentKeywords = {
    LocalAiIntent.greeting: [
      'hi', 'hello', 'hey', 'salam', 'salaam', 'привет', 'здравствуи',
      'здравствуите', 'добрии', 'утро', 'вечер', 'саламатсизби', 'кутм',
    ],
    LocalAiIntent.rules: [
      'правил', 'правило', 'этикет', 'нелзя', 'мозно', 'запрет', 'уважение',
      'поведен', 'одезд', 'одет', 'обув', 'эреже', 'тиюу', 'болот', 'болбоит',
      'силама', 'киим', 'кии', 'rules', 'rule', 'forbid', 'allow', 'respect',
      'behave', 'behavior', 'dress', 'wear', 'taboo',
    ],
    LocalAiIntent.history: [
      'истории', 'истори', 'легенд', 'произозден', 'древн', 'прозл', 'наследие',
      'старин', 'миф', 'тарих', 'уламиз', 'окуа', 'баиркии', 'мурас', 'зомок',
      'history', 'historic', 'origin', 'legend', 'past', 'ancient', 'heritage',
      'story',
    ],
    LocalAiIntent.route: [
      'дорог', 'марзрут', 'добрат', 'добир', 'путии', 'пут', 'как доеха',
      'как добра', 'транспорт', 'трасс', 'расстоиан', 'километр', 'зол',
      'кантип бар', 'багит', 'каттам', 'аралик', 'зетип', 'route', 'reach',
      'directions', 'travel', 'transport', 'road', 'drive', 'distance', 'how',
      'taxi', 'bus', 'marshrutka',
    ],
    LocalAiIntent.timing: [
      'когда', 'врем', 'сезон', 'часи работи', 'погод', 'рассвет', 'закат',
      'лето', 'зима', 'весн', 'осен', 'качан', 'убак', 'мезгил', 'заз', 'заи',
      'куз', 'киз', 'кун', 'when', 'time', 'season', 'open', 'hour', 'weather',
      'best', 'sunrise', 'sunset', 'spring', 'summer', 'winter', 'autumn',
      'fall',
    ],
    LocalAiIntent.traditions: [
      'традици', 'обриад', 'ритуал', 'обича', 'культур', 'паломник',
      'паломнич', 'верован', 'салт', 'каада', 'ирим', 'мадании', 'зиарат',
      'tradition', 'custom', 'ritual', 'ceremony', 'culture', 'belief',
      'practice', 'pilgrim', 'shaman',
    ],
    LocalAiIntent.list: [
      'список', 'покази', 'все места', 'какие места', 'варианти', 'что ест',
      'куда', 'показите', 'тизме', 'корсот', 'каиси зерлер', 'бардик зерлер',
      'list', 'show', 'places', 'options', 'where can', 'recommend',
    ],
    LocalAiIntent.thanks: [
      'спасиб', 'благодар', 'рахмат', 'раамат', 'thanks', 'thank', 'thx',
      'ираази',
    ],
    LocalAiIntent.funFact: [
      'факт', 'интересн', 'кизик', 'таазуп', 'fact', 'interesting', 'curious',
      'wow', 'cool', 'удивит',
    ],
    LocalAiIntent.joke: [
      'зутк', 'анекдот', 'смези', 'кулдур', 'joke', 'funny', 'humor', 'laugh',
      'тамаза', 'кулку',
    ],
    LocalAiIntent.food: [
      'еда', 'еду', 'кузат', 'кушан', 'кулинар', 'блиуд', 'плов', 'бесбармак',
      'манти', 'самса', 'кумис', 'каимак', 'тамак', 'азик', 'food', 'eat',
      'dish', 'meal', 'cuisine', 'beshbarmak', 'plov', 'manti', 'kymyz',
      'lagman', 'shorpo',
    ],
    LocalAiIntent.language: [
      'изик', 'переведи', 'переведите', 'фраз', 'привет на', 'спасибо на',
      'тил', 'фраза', 'language', 'phrase', 'translate', 'how to say',
      'kyrgyz word', 'kirgiz',
    ],
    LocalAiIntent.money: [
      'денги', 'валиут', 'цена', 'сом', 'обмен', 'банкомат', 'банк', 'naличн',
      'налиц', 'акца', 'акша', 'money', 'cash', 'currency', 'price', 'cost',
      'exchange', 'atm', 'card',
    ],
    LocalAiIntent.safety: [
      'безопас', 'опасн', 'страз', 'воровст', 'безопаснос', 'хауипсиз',
      'коркунуч', 'safety', 'safe', 'danger', 'crime', 'theft', 'risk',
    ],
    LocalAiIntent.yurt: [
      'иурт', 'иурта', 'иурти', 'воилок', 'тундук', 'кииз', 'yurt', 'felt',
      'tunduk',
    ],
    LocalAiIntent.nomad: [
      'кочев', 'номад', 'мал', 'абилак', 'кочуп', 'жайлоо', 'жаилоо', 'nomad',
      'nomadic', 'pasture', 'jailoo', 'shepherd',
    ],
  };

  // High-confidence off-topic markers — mostly programming, news, finance,
  // jokes about random topics that have nothing to do with KG.
  static const List<String> _offTopicSignals = [
    'python', 'javascript', 'java code', 'sql', 'flutter code', 'algorithm',
    'kubernetes', 'docker', 'compile error',
    'stock market', 'bitcoin', 'crypto price', 'ethereum',
    'us election', 'trump', 'biden', 'putin',
    'football match', 'soccer score', 'nba',
    'netflix', 'movie review', 'song lyrics',
    'программ ', 'код ', 'компиляц', 'скрипт', 'питон', 'явасипт', 'крипт',
    'выборы', 'президент сза', 'фондов',
    'программ', 'код жаз', 'котормо', 'ыр сөз',
  ];

  // ---------------------------------------------------------------------------
  // Detection
  // ---------------------------------------------------------------------------

  /// Detect a primary natural language for the message.
  String detectLanguage(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'[өүң]', unicode: true).hasMatch(lower)) return 'ky';
    if (RegExp(r'[а-яё]', unicode: true).hasMatch(lower)) return 'ru';
    if (RegExp(r'[a-z]').hasMatch(lower)) return 'en';
    return language;
  }

  Set<LocalAiIntent> _detectIntents(List<String> tokens) {
    final intents = <LocalAiIntent>{};
    for (final entry in _intentKeywords.entries) {
      for (final keyword in entry.value) {
        final normalizedKeyword = _normalize(keyword);
        // Multi-word keyword: substring match against the joined tokens.
        if (normalizedKeyword.contains(' ')) {
          final joined = tokens.join(' ');
          if (joined.contains(normalizedKeyword)) {
            intents.add(entry.key);
            break;
          }
          continue;
        }
        for (final token in tokens) {
          if (_fuzzyMatch(token, normalizedKeyword)) {
            intents.add(entry.key);
            break;
          }
        }
      }
    }
    return intents;
  }

  AiPlaceInfo? _detectPlace(List<String> tokens, String rawNormalized) {
    if (places.isEmpty) return null;
    AiPlaceInfo? best;
    var bestScore = 0.0;
    for (final place in places) {
      var score = 0.0;
      final aliasSet = <String>{
        place.title,
        place.id,
        ...place.aliases,
      }.where((alias) => alias.trim().isNotEmpty).toList();
      for (final raw in aliasSet) {
        final normAlias = _normalize(raw);
        if (normAlias.length < 3) continue;
        if (rawNormalized.contains(normAlias)) {
          score += normAlias.length * 1.5;
        }
        for (final token in tokens) {
          if (_fuzzyMatch(token, normAlias) ||
              (normAlias.length >= 5 && _fuzzyMatch(token, normAlias.split(' ').first))) {
            score += token.length;
          }
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = place;
      }
    }
    if (bestScore < 3) return null;
    return best;
  }

  bool _looksOffTopic(String normalized) {
    for (final signal in _offTopicSignals) {
      if (normalized.contains(_normalize(signal))) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Public entry point
  // ---------------------------------------------------------------------------

  LocalAiResponse reply(String text, {AiPlaceInfo? contextPlace}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return LocalAiResponse(
        text: _pick(_emptyPrompt),
        intent: LocalAiIntent.unknown,
      );
    }

    final lang = detectLanguage(trimmed);
    final normalized = _normalize(trimmed);
    final tokens = _tokens(normalized);
    final intents = _detectIntents(tokens);
    final place = _detectPlace(tokens, normalized) ?? contextPlace;

    // Greeting alone — say hi.
    if (intents.contains(LocalAiIntent.greeting) &&
        intents.length == 1 &&
        place == null) {
      return _wrap(_pick(_greeting, lang: lang), LocalAiIntent.greeting,
          lang: lang);
    }
    if (intents.contains(LocalAiIntent.thanks) && intents.length == 1) {
      return _wrap(_pick(_thanks, lang: lang), LocalAiIntent.thanks,
          lang: lang);
    }

    // General topics that don't need a place.
    if (place == null) {
      if (intents.contains(LocalAiIntent.list)) {
        return _wrap(_listAnswer(lang), LocalAiIntent.list, lang: lang);
      }
      for (final generalIntent in const [
        LocalAiIntent.food,
        LocalAiIntent.language,
        LocalAiIntent.money,
        LocalAiIntent.safety,
        LocalAiIntent.yurt,
        LocalAiIntent.nomad,
        LocalAiIntent.traditions,
        LocalAiIntent.timing,
      ]) {
        if (intents.contains(generalIntent)) {
          return _wrap(_generalAnswer(generalIntent, lang), generalIntent,
              lang: lang);
        }
      }
      if (intents.contains(LocalAiIntent.funFact)) {
        return _wrap(_pick(_generalFunFacts, lang: lang),
            LocalAiIntent.funFact, lang: lang);
      }
      if (intents.contains(LocalAiIntent.joke)) {
        return _wrap(_pick(_jokes, lang: lang), LocalAiIntent.joke,
            lang: lang);
      }
      if (_looksOffTopic(normalized) && intents.isEmpty) {
        return _wrap(_pick(_offTopicTable, lang: lang), LocalAiIntent.offTopic,
            lang: lang);
      }
      // Nothing concrete — list places as a friendly fallback.
      return _wrap(_listAnswer(lang), LocalAiIntent.list, lang: lang);
    }

    // We have a place — build a layered guide-style answer based on which
    // intents were detected.
    final answer = _composePlaceAnswer(
      place: place,
      intents: intents,
      lang: lang,
    );
    final primary = intents.isEmpty
        ? LocalAiIntent.general
        : (intents.contains(LocalAiIntent.history)
            ? LocalAiIntent.history
            : intents.contains(LocalAiIntent.route)
                ? LocalAiIntent.route
                : intents.contains(LocalAiIntent.rules)
                    ? LocalAiIntent.rules
                    : intents.contains(LocalAiIntent.timing)
                        ? LocalAiIntent.timing
                        : intents.contains(LocalAiIntent.traditions)
                            ? LocalAiIntent.traditions
                            : LocalAiIntent.general);
    return LocalAiResponse(text: answer, intent: primary, placeId: place.id);
  }

  // ---------------------------------------------------------------------------
  // Composition
  // ---------------------------------------------------------------------------

  String _composePlaceAnswer({
    required AiPlaceInfo place,
    required Set<LocalAiIntent> intents,
    required String lang,
  }) {
    final blocks = <String>[];
    final hasSpecific = intents.any((i) => const {
          LocalAiIntent.history,
          LocalAiIntent.route,
          LocalAiIntent.rules,
          LocalAiIntent.timing,
          LocalAiIntent.traditions,
          LocalAiIntent.funFact,
          LocalAiIntent.joke,
        }.contains(i));

    // Opening line: name + region + short description.
    blocks.add('${place.title} — ${_label(_inRegionLabel, lang)} '
        '${place.regionName}.\n${place.shortDescription}');

    if (intents.contains(LocalAiIntent.history) || !hasSpecific) {
      blocks.add('${_label(_historyLabel, lang)}:\n${place.description}');
    }
    if (intents.contains(LocalAiIntent.traditions) || !hasSpecific) {
      blocks.add('${_label(_culturalLabel, lang)}:\n${place.culturalNote}');
    }
    if (intents.contains(LocalAiIntent.rules) || !hasSpecific) {
      blocks.add('${_label(_rulesLabel, lang)}:\n${place.visitingRules}');
    }
    if (intents.contains(LocalAiIntent.route)) {
      blocks.add('${_label(_routeLabel, lang)}:\n${place.route}');
    }
    if (intents.contains(LocalAiIntent.timing)) {
      blocks.add('${_label(_timingLabel, lang)}:\n${_timingHint(lang)}');
    }

    // Always close with a small "guide" flourish: a fun fact, a tip, or a
    // light joke. Mix it up so successive answers don't repeat.
    final flourish = _flourishFor(place, intents, lang);
    if (flourish.isNotEmpty) {
      blocks.add(flourish);
    }

    final body = blocks.join('\n\n');
    final prefix = aiName.isEmpty ? '' : '$aiName: ';
    return '$prefix$body';
  }

  String _flourishFor(
    AiPlaceInfo place,
    Set<LocalAiIntent> intents,
    String lang,
  ) {
    if (intents.contains(LocalAiIntent.joke)) {
      return '${_label(_jokeLabel, lang)}: ${_pick(_jokes, lang: lang)}';
    }
    final pool = <String>[];
    final placeFacts = _placeFunFacts[place.id];
    if (placeFacts != null) {
      pool.add(placeFacts[lang] ?? placeFacts['en'] ?? '');
    }
    pool.add(_pick(_generalFunFacts, lang: lang));
    pool.add(_pick(_guideTips, lang: lang));
    pool.removeWhere((s) => s.isEmpty);
    if (pool.isEmpty) return '';
    final tip = pool[_random.nextInt(pool.length)];
    return '${_label(_factLabel, lang)}: $tip';
  }

  String _generalAnswer(LocalAiIntent intent, String lang) {
    switch (intent) {
      case LocalAiIntent.food:
        return _pick(_foodAnswer, lang: lang);
      case LocalAiIntent.language:
        return _pick(_languageAnswer, lang: lang);
      case LocalAiIntent.money:
        return _pick(_moneyAnswer, lang: lang);
      case LocalAiIntent.safety:
        return _pick(_safetyAnswer, lang: lang);
      case LocalAiIntent.yurt:
        return _pick(_yurtAnswer, lang: lang);
      case LocalAiIntent.nomad:
        return _pick(_nomadAnswer, lang: lang);
      case LocalAiIntent.traditions:
        return _pick(_traditionsGeneralAnswer, lang: lang);
      case LocalAiIntent.timing:
        return _pick(_timingGeneralAnswer, lang: lang);
      default:
        return _pick(_generalFunFacts, lang: lang);
    }
  }

  String _listAnswer(String lang) {
    final intro = _label(_listIntro, lang);
    final lines = places
        .map((p) => '• ${p.title} — ${p.regionName}')
        .toList();
    return '$intro\n${lines.join('\n')}\n\n${_label(_listOutro, lang)}';
  }

  LocalAiResponse _wrap(String text, LocalAiIntent intent,
      {required String lang}) {
    final prefix = aiName.isEmpty ? '' : '$aiName: ';
    return LocalAiResponse(text: '$prefix$text', intent: intent);
  }

  String _pick(Map<String, List<String>> table, {String? lang}) {
    final code = lang ?? language;
    final variants = table[code] ?? table['en'] ?? const <String>[];
    if (variants.isEmpty) return '';
    return variants[_random.nextInt(variants.length)];
  }

  String _label(Map<String, String> table, String lang) {
    return table[lang] ?? table['en'] ?? '';
  }

  String _timingHint(String lang) {
    return _label(_timingHintTable, lang);
  }

  // ---------------------------------------------------------------------------
  // Phrase tables
  // ---------------------------------------------------------------------------

  static const Map<String, List<String>> _greeting = {
    'en': [
      'Hi! I am the offline guide for Sacred KG. Ask me anything about a '
          'sacred place, a tourist site or general travel in Kyrgyzstan and '
          'I will share rules, history, routes, and even a fun fact or two.',
      'Hello, traveller! I work fully offline. Tell me a place name (Burana, '
          'Sulaiman-Too, Issyk-Kul, Tash-Rabat…) or ask about food, money, '
          'language — anything Kyrgyz.',
    ],
    'ru': [
      'Здравствуйте! Я локальный гид Sacred KG, работаю офлайн. Спросите про '
          'любое святое или туристическое место, про еду, валюту, традиции — '
          'отвечу подробно и иногда подкину интересный факт.',
      'Привет! Расскажу про Бурану, Сулайман-Тоо, Иссык-Куль, Таш-Рабат, '
          'Сон-Куль и многое другое. Можете писать с опечатками — я пойму.',
    ],
    'ky': [
      'Саламатсызбы! Мен Sacred KG колдонмосунун офлайн жол көрсөткүчүмүн. '
          'Кыргызстандын ыйык жана туристтик жерлери, тамак-аш, акча, тил, '
          'салттар жөнүндө сурасаңыз — кеңири айтып берем.',
      'Салам! Бурана, Сулайман-Тоо, Ысык-Көл, Таш-Рабат, Сон-Көл — кайсы жер '
          'жөнүндө сүйлөшөбүз? Жазганда ката кетсе да түшүнөм.',
    ],
  };

  static const Map<String, List<String>> _thanks = {
    'en': [
      'Glad to help. Travel safely and respect the places — they remember '
          'kind visitors.',
      'You are welcome! Tell your friends to come too — Kyrgyzstan loves '
          'curious travellers.',
    ],
    'ru': [
      'Рад помочь! Хорошей дороги и берегите эти места — они помнят добрых '
          'гостей.',
      'Пожалуйста! Возвращайтесь и зовите друзей — Кыргызстан любит '
          'любопытных.',
    ],
    'ky': [
      'Жардам берүүгө кубанычтамын! Жолуңуз ачык, жерлерди сыйлап барыңыз — '
          'алар мейманчыл коноктордун эсин жоготпойт.',
      'Эч нерсе эмес! Досторуңузду да чакырыңыз — Кыргызстан жаңы достордон '
          'кубанат.',
    ],
  };

  static const Map<String, List<String>> _emptyPrompt = {
    'en': [
      'Type a question — about Burana, Issyk-Kul, food, traditions or any '
          'place from the catalog.',
    ],
    'ru': [
      'Напишите вопрос — про Бурану, Иссык-Куль, еду, традиции или любое '
          'место из каталога.',
    ],
    'ky': [
      'Суроо жазыңыз — Бурана, Ысык-Көл, тамак-аш, салттар же каталогдогу '
          'кайсы бир жер жөнүндө.',
    ],
  };

  static const Map<String, String> _listIntro = {
    'en': 'Here are the places I know inside out:',
    'ru': 'Вот места, про которые я могу рассказать в деталях:',
    'ky': 'Мен жакшы билген жерлер:',
  };

  static const Map<String, String> _listOutro = {
    'en':
        'Pick any of them and ask about its history, rules, route, traditions '
        'or just say "tell me about it".',
    'ru':
        'Выберите любое и спросите про историю, правила, маршрут, традиции — '
        'или просто скажите «расскажи».',
    'ky':
        'Каалаганын тандап тарых, эреже, жол, салт жөнүндө сурасаңыз болот — '
        'же жөн гана «айтып бер» деп жазыңыз.',
  };

  static const Map<String, List<String>> _offTopicTable = {
    'en': [
      'I am offline and stick to Kyrgyzstan — sacred places, tourist sites, '
          'food, traditions, language. Ask me about Burana, Sulaiman-Too, '
          'Issyk-Kul, Ala-Archa, Tash-Rabat or Son-Kul and I will be in my '
          'element.',
    ],
    'ru': [
      'Я работаю офлайн и говорю только о Кыргызстане — святые места, '
          'туристические локации, еда, традиции, язык. Спросите меня про '
          'Бурану, Сулайман-Тоо, Иссык-Куль, Ала-Арчу, Таш-Рабат или Сон-Куль.',
    ],
    'ky': [
      'Мен офлайнмын жана Кыргызстан тууралуу гана сүйлөшөм — ыйык жерлер, '
          'туристтик объекттер, тамак-аш, салттар, тил. Бурана, Сулайман-Тоо, '
          'Ысык-Көл, Ала-Арча, Таш-Рабат же Сон-Көл — кайсынысын тандайбыз?',
    ],
  };

  static const Map<String, String> _historyLabel = {
    'en': 'History',
    'ru': 'История',
    'ky': 'Тарых',
  };
  static const Map<String, String> _routeLabel = {
    'en': 'How to get there',
    'ru': 'Как добраться',
    'ky': 'Кантип жетсе болот',
  };
  static const Map<String, String> _rulesLabel = {
    'en': 'Visiting rules',
    'ru': 'Правила посещения',
    'ky': 'Зыярат эрежелери',
  };
  static const Map<String, String> _timingLabel = {
    'en': 'Best time to visit',
    'ru': 'Когда лучше идти',
    'ky': 'Качан баруу жакшы',
  };
  static const Map<String, String> _culturalLabel = {
    'en': 'Cultural note',
    'ru': 'Культурная заметка',
    'ky': 'Маданий эскертүү',
  };
  static const Map<String, String> _factLabel = {
    'en': 'Fun fact',
    'ru': 'Интересный факт',
    'ky': 'Кызыктуу факт',
  };
  static const Map<String, String> _jokeLabel = {
    'en': 'Guide joke',
    'ru': 'Шутка от гида',
    'ky': 'Жол көрсөткүчтүн тамашасы',
  };
  static const Map<String, String> _inRegionLabel = {
    'en': 'in the region of',
    'ru': 'в регионе',
    'ky': 'аймагы:',
  };
  static const Map<String, String> _timingHintTable = {
    'en':
        'Mornings and late afternoons are usually the calmest, with soft '
        'light for photos. Spring (April–June) and early autumn '
        '(September–October) are the most pleasant overall — alpine summer '
        '(July–August) is best for high passes and lakes.',
    'ru':
        'Спокойнее всего ранним утром или ближе к вечеру — мягкий свет, '
        'меньше людей. Весна (апрель–июнь) и ранняя осень (сентябрь–октябрь) — '
        'самые приятные сезоны; высокие перевалы и горные озёра лучше '
        'смотреть в июле–августе.',
    'ky':
        'Эрте мененки жана күн батаардагы убак тынч болот, сүрөт үчүн жарык '
        'жумшак. Жаз (апрель–июнь) жана күздүн башы (сентябрь–октябрь) — эң '
        'жайлуу мезгил; бийик ашуулар жана көлдөр июль–августта көрсө жакшы.',
  };

  // Random fun facts about Kyrgyzstan in general — used when the question is
  // not place-specific or as the closing flourish to a place answer.
  static const Map<String, List<String>> _generalFunFacts = {
    'en': [
      'Kyrgyzstan is more than 90% mountains — the Tian Shan range covers '
          'most of the country.',
      'Issyk-Kul is the world\'s second-largest alpine lake; "Ysyk-Kol" '
          'literally means "warm lake" — it almost never freezes.',
      'The Manas epic, recited by manaschys, is one of the longest oral epics '
          'in the world — about half a million lines.',
      'The shyrdak — a hand-felted Kyrgyz carpet — is on the UNESCO list of '
          'intangible cultural heritage in need of urgent safeguarding.',
      'Eagle hunters (berkutchi) train golden eagles for years; the eagle '
          'usually returns to the wild after a decade with its master.',
    ],
    'ru': [
      'Больше 90% территории Кыргызстана — горы. Тянь-Шань занимает почти '
          'всю страну.',
      'Иссык-Куль — второе по величине горное озеро в мире; имя означает '
          '«тёплое озеро» — оно почти никогда не замерзает.',
      'Эпос «Манас» — один из самых длинных устных эпосов планеты, около '
          'полумиллиона строк, его исполняют манасчы.',
      'Кыргызский шырдак — войлочный ковёр ручной работы — внесён в список '
          'ЮНЕСКО как нематериальное наследие, нуждающееся в защите.',
      'Беркутчи годами обучают беркутов охоте; обычно через десяток лет '
          'птицу отпускают обратно в горы.',
    ],
    'ky': [
      'Кыргызстандын 90%дан көбү тоолордон турат — өлкөнү негизинен Тянь-Шань '
          'каптап турат.',
      'Ысык-Көл — дүйнөдөгү экинчи чоң тоолуу көл; "ыйык" эмес, "жылуу" көл '
          'деген маани, ал дээрлик тоңбойт.',
      'Манас эпосу — жер жүзүндөгү эң узун оозеки чыгармалардын бири, '
          'жарым миллионго жакын сабы бар, аны манасчылар айтат.',
      'Кыргыз шырдагы — кол менен басылган кийиз килем — ЮНЕСКОнун коргоого '
          'муктаж маданий мурас тизмесинде.',
      'Бүркүтчүлөр бүркүттү жылдар бою тарбиялашат; адатта он жылдан кийин '
          'бүркүт кайра тоого коё берилет.',
    ],
  };

  static const Map<String, List<String>> _jokes = {
    'en': [
      'A nomad walks into a yurt and says "I came back for my home" — turns '
          'out, the yurt was already two valleys away.',
      'Why is Issyk-Kul so warm? Because Lake Baikal got all the cold first.',
      'Tourist: "How long is the Manas epic?" Manaschy: "Bring tea — and '
          'maybe a sleeping bag."',
    ],
    'ru': [
      'Турист спрашивает: «Сколько идти до перевала?» — Чабан: «Близко, '
          'только за теми тремя горами.»',
      'Почему Иссык-Куль тёплый? Потому что весь холод забрал Байкал.',
      'Турист: «А долго рассказывают Манас?» — Манасчы: «Долейте чай и '
          'устраивайтесь поудобнее.»',
    ],
    'ky': [
      'Турист: «Ашууга кантип жетем?» — Койчу: «Жакын эле, ушул үч тоонун '
          'аркасында.»',
      'Эмне үчүн Ысык-Көл жылуу? Анткени бардык суукту Байкал алып койгон.',
      'Турист: «Манас узакпы?» — Манасчы: «Чайыңды куюп, жайгашып отур.»',
    ],
  };

  static const Map<String, List<String>> _guideTips = {
    'en': [
      'Bring layers — mountain weather can switch from sunshine to snow in '
          'one afternoon, even in summer.',
      'Greet elders first with "Salamatsyzby" — it always opens doors and '
          'usually a cup of tea.',
      'Drinking water from a fresh spring is fine; from rivers — boil it, '
          'glaciers can hide surprises.',
    ],
    'ru': [
      'Берите вещи слоями — в горах за один день погода может смениться от '
          'солнца до снега даже летом.',
      'Со старшими здоровайтесь первым — фраза «Саламатсызбы» открывает и '
          'двери, и чашку чая.',
      'Воду из родника пить можно, из реки — кипятите: ледники прячут '
          'сюрпризы.',
    ],
    'ky': [
      'Кийимди катмарлап алыңыз — тоодо аба ырайы күнү бою кайра-кайра '
          'өзгөрөт, жазда да, жайда да.',
      'Улууларга биринчи учурашыңыз — «Саламатсызбы» эшикти да, чай чыныны '
          'да ачат.',
      'Булактын суусун ичсе болот, дарыя суусун кайнатыңыз — мөңгүлөрдөн '
          'күтүлбөгөн нерсе келиши мүмкүн.',
    ],
  };

  static const Map<String, List<String>> _foodAnswer = {
    'en': [
      'Must-try Kyrgyz dishes:\n'
          '• Beshbarmak — boiled meat (lamb or horse) on flat noodles, the '
          'national dish.\n'
          '• Lagman — pulled noodles with vegetables and meat, perfect after '
          'a hike.\n'
          '• Manty — large steamed dumplings, juicy lamb-and-onion filling.\n'
          '• Plov — rice with carrots, lamb and cumin, slow-cooked in a '
          'kazan.\n'
          '• Shorpo — clear lamb broth with potatoes, the universal cure '
          'for tired travellers.\n'
          'Drinks: kymyz (fermented mare\'s milk, mildly sour), maksym '
          '(grain-based, summer favourite) and unstoppable amounts of black '
          'tea.',
    ],
    'ru': [
      'Что обязательно попробовать:\n'
          '• Бешбармак — варёное мясо (баранина или конина) на широкой лапше, '
          'национальное блюдо.\n'
          '• Лагман — вытяжная лапша с овощами и мясом, идеально после '
          'похода.\n'
          '• Манты — крупные паровые пельмени с сочной бараниной и луком.\n'
          '• Плов — рис с морковью, бараниной и зирой, томлёный в казане.\n'
          '• Шорпо — прозрачный мясной бульон с картошкой, лучшее средство '
          'для уставшего туриста.\n'
          'Напитки: кумыс (кобылье молоко, кислинка с пузырьками), максым '
          '(на основе злаков, летний хит) и литры чёрного чая.',
    ],
    'ky': [
      'Сөзсүз даам татканыңыз керек тамактар:\n'
          '• Бешбармак — кайнатылган эт (кой же жылкы) кесме менен, улуттук '
          'тамак.\n'
          '• Лагман — тарткан кесме, эт-жашылча менен, узак жолдон кийин эң '
          'сонун.\n'
          '• Манты — ширелүү кой эти жана пияз салынган бууда бышкан кашык '
          'челер.\n'
          '• Палоо — сабиз, кой эти, зира менен, казанда жай бышкан күрүч.\n'
          '• Шорпо — таза эт сорпо картошка менен, чарчаган мусапырга '
          'эң жакшы дары.\n'
          'Суусундуктар: кымыз (бээ сүтү, ачыраак), максым (буудай аралаш, '
          'жайдын даамы) жана сансыз көп кара чай.',
    ],
  };

  static const Map<String, List<String>> _languageAnswer = {
    'en': [
      'Useful Kyrgyz phrases:\n'
          '• Salam / Salamatsyzby — Hello / Hello (formal).\n'
          '• Rakhmat — Thank you.\n'
          '• Ooba / jok — Yes / no.\n'
          '• Kanchaa? — How much?\n'
          '• Kechiresiz — Excuse me / sorry.\n'
          '• Aman bolsun — May you be well (great farewell).\n'
          'Russian also works almost everywhere; English is common in tourist '
          'spots and cafés in Bishkek and Karakol.',
    ],
    'ru': [
      'Полезные кыргызские фразы:\n'
          '• Салам / Саламатсызбы — Привет / Здравствуйте (вежливо).\n'
          '• Рахмат — Спасибо.\n'
          '• Ооба / жок — Да / нет.\n'
          '• Канча? — Сколько?\n'
          '• Кечиресиз — Извините.\n'
          '• Аман болсун — Будьте здоровы (хорошее прощание).\n'
          'Русский понимают почти везде; английский распространён в '
          'туристических местах и кафе Бишкека и Каракола.',
    ],
    'ky': [
      'Колдонула турган кыргыз сүйлөмдөр:\n'
          '• Салам / Саламатсызбы — кадимки жана сылык учурашуу.\n'
          '• Рахмат — Ыраазычылык.\n'
          '• Ооба / жок — макул / макул эмес.\n'
          '• Канча? — Канчага?\n'
          '• Кечиресиз — Кечирим сурайм.\n'
          '• Аман болсун — Кош айтыша турган жакшы тилек.\n'
          'Орус тилин дээрлик баары түшүнөт; англис тили Бишкек, Каракол '
          'сыяктуу туристтик жерлерде кеңири колдонулат.',
    ],
  };

  static const Map<String, List<String>> _moneyAnswer = {
    'en': [
      'Currency: Kyrgyz som (KGS). Cash is king outside cities; ATMs are '
          'plentiful in Bishkek, Osh, Karakol and Cholpon-Ata. Cards (Visa, '
          'MasterCard) work in supermarkets and good restaurants but rarely '
          'in mountain villages. Local sim cards are cheap (Beeline, MegaCom, '
          'O!) and a 4G data plan is enough for offline maps and chat.',
    ],
    'ru': [
      'Валюта — кыргызский сом (KGS). За пределами городов лучше иметь '
          'наличные; банкоматы есть в Бишкеке, Оше, Караколе, Чолпон-Ате. '
          'Карты Visa и MasterCard принимают в крупных магазинах и хороших '
          'кафе, но редко в горных сёлах. SIM-карты местных операторов '
          '(Beeline, MegaCom, O!) дешёвые, 4G-пакета хватает для офлайн-карт '
          'и мессенджеров.',
    ],
    'ky': [
      'Валюта — кыргыз сому (KGS). Шаардан тышкары накталай акча алып жүргөн '
          'жакшы; банкоматтар Бишкекте, Ошто, Каракол жана Чолпон-Атада көп. '
          'Visa жана MasterCard карталары чоң дүкөндөрдө, кафелерде иштейт, '
          'тоо айылдарында кээде иштебейт. Жергиликтүү SIM-карта (Beeline, '
          'MegaCom, O!) арзан, 4G тарифи офлайн карта жана чат үчүн жетет.',
    ],
  };

  static const Map<String, List<String>> _safetyAnswer = {
    'en': [
      'Kyrgyzstan is friendly and overall safe. Common-sense rules: keep '
          'belongings close in Bishkek bazaars and minibuses, do not leave '
          'gear unattended at trailheads, and ask before crossing pastures '
          '(shepherds and dogs prefer to know you). Mountain roads can be '
          'rough — let someone know your route before going off-grid.',
    ],
    'ru': [
      'Кыргызстан гостеприимный и в целом безопасный. Базовые советы: на '
          'бишкекских базарах и в маршрутках держите вещи при себе; на старте '
          'трекинга не оставляйте рюкзаки без присмотра; пересекая пастбища, '
          'предупредите чабана — собаки лучше работают, когда хозяин в курсе. '
          'Горные дороги бывают сложными — оставляйте маршрут близким перед '
          'дальним выездом.',
    ],
    'ky': [
      'Кыргызстан мейманчыл жана негизи коопсуз. Кадимки сактык чаралары: '
          'Бишкектин базарларында, маршруткада нерселериңизди жакын алып '
          'жүрүңүз; трек башында рюкзакты жалгыз калтырбаңыз; жайыттан өтсөңүз '
          'койчуга билгизиңиз — иттер ээси билгенде гана тынч. Тоо жолдору '
          'кээде татаал — алыс барардан мурда маршрутту жакындарыңызга '
          'айтыңыз.',
    ],
  };

  static const Map<String, List<String>> _yurtAnswer = {
    'en': [
      'A yurt (boz üi) is a portable felt house used by nomads for centuries. '
          'Its frame is wooden lattice (kerege) topped by a circular crown — '
          'the tunduk — which is so important that it is on the Kyrgyz flag. '
          'Inside, the place opposite the door is the seat of honour; never '
          'step over food or the threshold.',
    ],
    'ru': [
      'Юрта (боз үй) — переносное войлочное жильё кочевников. Каркас '
          'собирается из деревянной решётки кереге, наверху — круглый купол '
          'тундук, который изображён на флаге Кыргызстана. Место напротив '
          'входа — почётное; через еду и порог не переступают.',
    ],
    'ky': [
      'Боз үй — кылымдар бою көчмөндөр пайдаланган кийиз үй. Каркасы керегеден '
          'турат, үстүндө тегерек түндүк — ал кыргыз желегинде да чагылдырылган. '
          'Эшиктин маңдайындагы орун урматтуу болуп саналат; тамак менен '
          'босогодон аттабайт.',
    ],
  };

  static const Map<String, List<String>> _nomadAnswer = {
    'en': [
      'Nomadic life shapes Kyrgyz culture. Families move with their herds '
          'between winter villages and summer pastures (jailoo). On a jailoo '
          'you may be invited for kymyz, sourdough bread and chai — accept '
          'with both hands and at least one cup. Sheep, horses and yaks set '
          'the rhythm: shearing in spring, milk fermentation in summer, and '
          'the descent before snow.',
    ],
    'ru': [
      'Кочевой уклад до сих пор формирует кыргызскую культуру. Семьи кочуют '
          'со стадами между зимовкой и летним пастбищем — джайлоо. На джайлоо '
          'вас могут позвать на кумыс, лепёшку и чай — берите обеими руками и '
          'обязательно хотя бы одну пиалу. Овцы, лошади, яки задают ритм: '
          'весна — стрижка, лето — кумыс, осень — спуск перед снегом.',
    ],
    'ky': [
      'Кыргыз маданиятын көчмөн турмуш күнү бүгүнгө чейин түптөйт. Үй-бүлөлөр '
          'мал менен кышкы айылдан жайлоого көчүшөт. Жайлоодо сизди кымызга, '
          'нанга, чайга чакырышы мүмкүн — эки колдоп алып, жок дегенде бир '
          'чыны ичиңиз. Кой, жылкы, топоз ыргакты белгилейт: жазда кыркуу, '
          'жайында кымыз, күздө кар жаардан мурун кайра түшүү.',
    ],
  };

  static const Map<String, List<String>> _traditionsGeneralAnswer = {
    'en': [
      'Kyrgyz traditions blend Tengrism, Sufi Islam and nomadic codes. Hosts '
          'serve guests first; elders are addressed with respect; the right '
          'hand is used for greetings and gifts. Spring brings Nooruz '
          '(March 21) — fires, sumolok porridge cooked overnight and '
          'horseback games like kok-boru.',
    ],
    'ru': [
      'Традиции кыргызов сочетают тенгрианство, суфийский ислам и кочевые '
          'правила. Гостя обслуживают первым; со старшими говорят с '
          'почтением; здороваются и подают вещи правой рукой. Весной — '
          'Нооруз (21 марта): костры, ночной сумалак и игры на лошадях '
          '(кок-бору).',
    ],
    'ky': [
      'Кыргыз салттары тенгризм, суфий исламы жана көчмөн эрежелеринен '
          'куралган. Конокту биринчи коноктошот; улууларга сыйлап, оң кол '
          'менен учурашат жана белек беришет. Жазда — Нооруз (21-март): от '
          'жагуу, түн бою бышкан сүмөлөк, кок-бору сыяктуу ат оюндары.',
    ],
  };

  static const Map<String, List<String>> _timingGeneralAnswer = {
    'en': [
      'Best general windows for travel:\n'
          '• Spring (April–June): green pastures, wildflowers, rushing rivers.\n'
          '• Summer (July–August): the only safe time for high passes and '
          'remote lakes (Ala-Kul, Kel-Suu, Son-Kul).\n'
          '• Autumn (September–October): clearest air, golden walnut groves '
          'in the south.\n'
          '• Winter (November–March): skiing at Karakol, ice on Issyk-Kul '
          'gulfs (the lake itself rarely freezes), short days, very cold '
          'mountains.',
    ],
    'ru': [
      'Лучшие сезоны для поездок:\n'
          '• Весна (апрель–июнь): зелёные пастбища, полевые цветы, бурные '
          'реки.\n'
          '• Лето (июль–август): единственное безопасное время для высоких '
          'перевалов и горных озёр (Ала-Куль, Кёль-Суу, Сон-Куль).\n'
          '• Осень (сентябрь–октябрь): прозрачный воздух, золотые ореховые '
          'рощи на юге.\n'
          '• Зима (ноябрь–март): горные лыжи в Караколе, лёд на иссык-кульских '
          'заливах (само озеро почти не замерзает), короткие дни, очень '
          'холодные горы.',
    ],
    'ky': [
      'Саякат үчүн эң жакшы мезгилдер:\n'
          '• Жаз (апрель–июнь): жашыл жайлоолор, талаа гүлдөрү, ылдам дарыялар.\n'
          '• Жай (июль–август): бийик ашуулар жана тоолуу көлдөргө '
          '(Ала-Көл, Кель-Суу, Сон-Көл) жалгыз коопсуз убак.\n'
          '• Күз (сентябрь–октябрь): таза аба, түштүктө сары жаңгак токойлору.\n'
          '• Кыш (ноябрь–март): Каракол лыжасы, Ысык-Көлдүн булуңдарында '
          'муз (көлдүн өзү дээрлик тоңбойт), күн кыска, тоодо абдан суук.',
    ],
  };

  // Per-place fun facts. Keys must match place IDs.
  static const Map<String, Map<String, String>> _placeFunFacts = {
    'burana': {
      'en':
          'The Burana minaret used to be 45 m tall but lost its top to a '
          '15th-century earthquake — it now stands at 24 m with a spiral '
          'staircase you can climb.',
      'ru':
          'Башня Бурана раньше была 45 м высотой, но землетрясение XV века '
          'снесло верхушку — сейчас 24 м, и внутри есть винтовая лестница.',
      'ky':
          'Бурана мунарасы мурда 45 м бийик болгон, бирок XV кылымдагы жер '
          'титирөө учун жок кылган — азыр 24 м, ичинде ийрилген тепкич бар.',
    },
    'sulaiman_too': {
      'en':
          'Sulaiman-Too is the only UNESCO World Heritage cultural site in '
          'Kyrgyzstan and has been a place of pilgrimage for at least 1,500 '
          'years.',
      'ru':
          'Сулайман-Тоо — единственный культурный объект Кыргызстана в списке '
          'ЮНЕСКО, паломники приходят сюда уже минимум 1500 лет.',
      'ky':
          'Сулайман-Тоо — Кыргызстандагы ЮНЕСКОнун маданий мурас тизмесиндеги '
          'жалгыз объект, зыяратчылар бул жерге кеминде 1500 жылдан бери барып '
          'келишет.',
    },
    'tash_rabat': {
      'en':
          'Tash-Rabat sits at 3,200 m and was a fortified caravanserai on a '
          'branch of the Silk Road; locals say its inner chambers stay cool '
          'even in July.',
      'ru':
          'Таш-Рабат стоит на 3200 м и был укреплённым караван-сараем на '
          'Великом Шёлковом пути; местные говорят, что внутри прохладно даже '
          'в июле.',
      'ky':
          'Таш-Рабат 3200 м бийиктикте — Жибек Жолунун тармагындагы коргонгон '
          'кербен сарайы; жергиликтүү эл анын ичи июлда да салкын деп айтат.',
    },
    'issyk_kul_lake': {
      'en':
          'At 668 m deep, Issyk-Kul is the second deepest alpine lake on '
          'Earth — only Lake Baikal is deeper.',
      'ru':
          'Иссык-Куль — второе по глубине горное озеро планеты (668 м), '
          'глубже него только Байкал.',
      'ky':
          'Ысык-Көл — жер жүзүндөгү тереңдиги боюнча экинчи тоолуу көл '
          '(668 м), андан тереңи Байкал гана.',
    },
    'son_kul': {
      'en':
          'Son-Kul plateau sits at over 3,000 m and is empty in winter — '
          'shepherds set up yurts only from June to September.',
      'ru':
          'Плато Сон-Куль находится выше 3000 м, зимой оно пустует — чабаны '
          'ставят юрты только с июня по сентябрь.',
      'ky':
          'Сон-Көл өрөөнү 3000 м бийикте, кышында бош калат — койчулар жайлоого '
          'июндан сентябрьга чейин гана көчүп келишет.',
    },
    'ala_archa': {
      'en':
          'Ala-Archa national park gates are only 40 km from central Bishkek '
          '— you can have breakfast in the city and lunch under a glacier.',
      'ru':
          'Ворота Ала-Арчи всего в 40 км от центра Бишкека — можно позавтракать '
          'в городе и обедать у ледника.',
      'ky':
          'Ала-Арчанын дарбазасы Бишкектин борборунан 40 км алыс — таңкы '
          'тамакты шаарда, түшкү тамакты мөңгүнүн түбүндө ичсе болот.',
    },
  };
}

/// Helper that resolves the active locale from a [BuildContext] for callers
/// outside of the main library. The runtime fallback is the language code
/// stored in [LocalizedContent].
String aiLanguageFromBuildContext(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode;
  return normalizeLanguageCode(code);
}
