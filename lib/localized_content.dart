import 'package:intl/intl.dart';

import 'app_localizations.dart';

class LocalizedContent {
  const LocalizedContent._();

  static String get languageCode => normalizeLanguageCode(Intl.defaultLocale);

  static String enumLabel(String group, String key, String fallback) {
    return _text(_enumLabels, '$group.$key', fallback);
  }

  static String regionField(String id, String field, String fallback) {
    return _text(_regions, '$id.$field', fallback);
  }

  static List<String> regionHighlights(String id, List<String> fallback) {
    final value = _text(_regions, '$id.highlights', fallback.join('|'));
    return value.split('|');
  }

  static String placeField(String id, String field, String fallback) {
    return _text(_places, '$id.$field', fallback);
  }

  /// Returns a place field for an explicit language, ignoring [Intl.defaultLocale].
  /// Returns `null` when no localized text is available for that language.
  static String? placeFieldFor(String id, String field, String lang) {
    final code = normalizeLanguageCode(lang);
    return _places[code]?['$id.$field'];
  }

  static String reviewText(String placeId, String user, String fallback) {
    return _text(_reviews, '$placeId.$user', fallback);
  }

  static String postText(String id, String fallback) {
    return _text(_posts, id, fallback);
  }

  static String bookingNote(String id, String fallback) {
    return _text(_bookings, '$id.notes', fallback);
  }

  static String characterField(String id, String field, String fallback) {
    return _text(_characters, '$id.$field', fallback);
  }

  static String phrase(String fallback) {
    return _text(_phrases, fallback, fallback);
  }

  static String aiVoice(String characterId) {
    return characterId == 'apashka'
        ? phrase('I would approach it gently:')
        : phrase('From the heritage record:');
  }

  static String aiRules(String target) {
    return phrase(
      'at {target}, keep the visit quiet, do not touch fragile stones or water sources, ask before photographing people, and leave the path cleaner than you found it.',
    ).replaceAll('{target}', target);
  }

  static String aiBestTime() {
    return phrase(
      'early morning is usually best for comfort, photos, and calm movement. Mountain routes should be checked seasonally and with local guidance.',
    );
  }

  static String aiChooseRegion() {
    return phrase(
      'choose a region first, then the app can show a simple route note for the selected sacred place.',
    );
  }

  static String aiTraditionsOverview() {
    return phrase(
      'many Kyrgyz sacred places connect water, stone, mountains, family memory, and respectful silence.',
    );
  }

  static String aiAskOverview() {
    return phrase(
      'ask about rules, history, route, or best time to visit, and I will answer with mock local guidance.',
    );
  }

  static String _text(
    Map<String, Map<String, String>> source,
    String key,
    String fallback,
  ) {
    return source[languageCode]?[key] ?? fallback;
  }

  static const _enumLabels = <String, Map<String, String>>{
    'ru': {
      'placeType.sacredPlace': 'Священное место',
      'placeType.petroglyphSite': 'Петроглифы',
      'placeType.mausoleum': 'Мавзолей',
      'placeType.sacredSpring': 'Священный источник',
      'placeType.historicalComplex': 'Исторический комплекс',
      'placeType.archaeologicalSite': 'Археологический объект',
      'placeType.naturalSacredPlace': 'Природное священное место',
      'postType.review': 'Отзыв',
      'postType.issue': 'Проблема',
      'postType.tip': 'Совет',
      'postType.experience': 'Впечатление',
      'bookingStatus.pending': 'Ожидает',
      'bookingStatus.approved': 'Одобрено',
      'bookingStatus.rejected': 'Отклонено',
    },
    'ky': {
      'placeType.sacredPlace': 'Ыйык жер',
      'placeType.petroglyphSite': 'Петроглиф жайы',
      'placeType.mausoleum': 'Күмбөз',
      'placeType.sacredSpring': 'Ыйык булак',
      'placeType.historicalComplex': 'Тарыхый комплекс',
      'placeType.archaeologicalSite': 'Археологиялык жай',
      'placeType.naturalSacredPlace': 'Табигый ыйык жер',
      'postType.review': 'Пикир',
      'postType.issue': 'Маселе',
      'postType.tip': 'Кеңеш',
      'postType.experience': 'Таасир',
      'bookingStatus.pending': 'Күтүүдө',
      'bookingStatus.approved': 'Бекитилди',
      'bookingStatus.rejected': 'Четке кагылды',
    },
  };

  static const _regions = <String, Map<String, String>>{
    'ru': {
      'chuy.name': 'Чуй',
      'chuy.subtitle': 'Башни, долины и старые караванные дороги',
      'chuy.highlights': 'Бурана|Ала-Арча|маршруты паломников',
      'issyk_kul.name': 'Иссык-Куль',
      'issyk_kul.subtitle': 'Озерные легенды и древние камни',
      'issyk_kul.highlights': 'Чолпон-Ата|Манжылы-Ата|озерные святыни',
      'naryn.name': 'Нарын',
      'naryn.subtitle': 'Высокие перевалы и память караванов',
      'naryn.highlights': 'Таш-Рабат|Сон-Куль|горные тропы',
      'talas.name': 'Талас',
      'talas.subtitle': 'Эпическое наследие и открытые долины',
      'talas.highlights': 'Манас Ордо|Кировская долина|устная история',
      'osh.name': 'Ош',
      'osh.subtitle': 'Сулайман-Тоо и слои Шелкового пути',
      'osh.highlights': 'Сулайман-Тоо|старый город|источники',
      'jalal_abad.name': 'Джалал-Абад',
      'jalal_abad.subtitle': 'Ореховые леса и целебные воды',
      'jalal_abad.highlights': 'Арсланбоб|источники|лесные тропы',
      'batken.name': 'Баткен',
      'batken.subtitle': 'Скалы, цветы и южные легенды',
      'batken.highlights': 'Айгуль-Таш|пещеры|пограничные истории',
    },
    'ky': {
      'chuy.name': 'Чүй',
      'chuy.subtitle': 'Мунаралар, өрөөндөр жана эски кербен жолдору',
      'chuy.highlights': 'Бурана|Ала-Арча|зыярат маршруттары',
      'issyk_kul.name': 'Ысык-Көл',
      'issyk_kul.subtitle': 'Көл уламыштары жана байыркы таштар',
      'issyk_kul.highlights': 'Чолпон-Ата|Манжылы-Ата|көлдөгү ыйык жерлер',
      'naryn.name': 'Нарын',
      'naryn.subtitle': 'Бийик ашуулар жана кербендердин эстелиги',
      'naryn.highlights': 'Таш-Рабат|Соң-Көл|тоо жолдору',
      'talas.name': 'Талас',
      'talas.subtitle': 'Эпикалык мурас жана кең өрөөндөр',
      'talas.highlights': 'Манас Ордо|Киров өрөөнү|оозеки тарых',
      'osh.name': 'Ош',
      'osh.subtitle': 'Сулайман-Тоо жана Жибек жолунун катмарлары',
      'osh.highlights': 'Сулайман-Тоо|эски шаар|булактар',
      'jalal_abad.name': 'Жалал-Абад',
      'jalal_abad.subtitle': 'Жаңгак токойлору жана шыпаалуу суулар',
      'jalal_abad.highlights': 'Арстанбап|булактар|токой жолдору',
      'batken.name': 'Баткен',
      'batken.subtitle': 'Аскалар, гүлдөр жана түштүк уламыштары',
      'batken.highlights': 'Айгүл-Таш|үңкүрлөр|чек ара окуялары',
    },
  };

  static const _places = <String, Map<String, String>>{
    'ru': {
      'burana.title': 'Башня Бурана',
      'burana.shortDescription':
          'Минарет и музей под открытым небом рядом с древним Баласагуном.',
      'burana.description':
          'Башня Бурана - один из самых узнаваемых памятников наследия северного Кыргызстана. Демо-история показывает ее как спокойную отправную точку для знакомства с караванными путями, каменными балбалами и городской жизнью Шелкового пути.',
      'burana.culturalNote':
          'Посетители часто связывают это место с памятью, дорогой и долгим обменом языками и ремеслами в долине.',
      'burana.visitingRules':
          'Осторожно ходите рядом с камнями, не поднимайтесь в закрытые зоны, говорите тише возле памятных объектов и не оставляйте следов.',
      'burana.route':
          'Из Бишкека двигайтесь в сторону Токмока. Последний участок можно пройти на местном транспорте или короткой поездкой на такси.',
      'ala_archa.title': 'Священная долина Ала-Арча',
      'ala_archa.shortDescription':
          'Горные тропы, чистая вода и тихие места для размышления.',
      'ala_archa.description':
          'Прототип показывает Ала-Арчу как природный священный маршрут с уважительным походом, водными источниками и ощущением входа в охраняемое горное пространство.',
      'ala_archa.culturalNote':
          'К горным долинам часто относятся бережно, потому что вода, камни и тропы хранят семейную и сезонную память.',
      'ala_archa.visitingRules':
          'Оставайтесь на маркированных тропах, уважайте животных, не включайте громкую музыку и уносите весь мусор.',
      'ala_archa.route':
          'Доберитесь до парка из Бишкека на машине или организованном транспорте, затем следуйте по отмеченным тропам.',
      'cholpon_ata.title': 'Петроглифы Чолпон-Аты',
      'cholpon_ata.shortDescription':
          'Каменные рисунки под открытым небом у Иссык-Куля со сценами животных и охоты.',
      'cholpon_ata.description':
          'Поле петроглифов дает MVP сильную визуальную основу: древние камни, символические животные и маршрут, который можно исследовать как галерею.',
      'cholpon_ata.culturalNote':
          'Наскальные рисунки представлены как хрупкие свидетельства наблюдений, верований и движения по ландшафту.',
      'cholpon_ata.visitingRules':
          'Не трогайте и не обводите рисунки, держитесь троп, фотографируйте без вспышки там, где это требуется, и не наступайте на отмеченные камни.',
      'cholpon_ata.route':
          'Езжайте в Чолпон-Ату на северном берегу Иссык-Куля, затем следуйте указателям местного музея.',
      'manjyly_ata.title': 'Источники Манжылы-Ата',
      'manjyly_ata.shortDescription':
          'Место источников, связанное с благословениями, тихими прогулками и семейными визитами.',
      'manjyly_ata.description':
          'Экран подчеркивает внимательное посещение: вода, сухие холмы, воздух озера и малые ритуалы, к которым важно подходить уважительно.',
      'manjyly_ata.culturalNote':
          'Источники часто связывают с исцелением, благодарностью и осторожным поведением рядом с водой.',
      'manjyly_ata.visitingRules':
          'Одевайтесь уважительно, сохраняйте чистоту источника, не мешайте личным молитвам и спрашивайте разрешение перед съемкой людей.',
      'manjyly_ata.route':
          'Подъезжайте со стороны южной дороги Иссык-Куля; местные гиды помогут найти зону источников.',
      'jeti_oguz.title': 'Красные скалы Жети-Огуз',
      'jeti_oguz.shortDescription':
          'Красные утесы, легенды и горный воздух рядом с Караколом.',
      'jeti_oguz.description':
          'Жети-Огуз используется в прототипе как выразительная природная история с вниманием к местным легендам и осторожному движению по хрупким склонам.',
      'jeti_oguz.culturalNote':
          'Ландшафтные легенды помогают посетителям понять, почему природная форма может иметь эмоциональное и культурное значение.',
      'jeti_oguz.visitingRules':
          'Не поднимайтесь на неустойчивые склоны, держите места отдыха чистыми и относитесь к местным историям с уважением.',
      'jeti_oguz.route':
          'Езжайте из Каракола к селу Жети-Огуз, затем продолжайте к главным смотровым точкам скал.',
      'tash_rabat.title': 'Караван-сарай Таш-Рабат',
      'tash_rabat.shortDescription':
          'Каменный караван-сарай в высокогорной долине.',
      'tash_rabat.description':
          'Демо представляет Таш-Рабат как место для понимания убежища, торговли, погоды и горного гостеприимства.',
      'tash_rabat.culturalNote':
          'Каменная архитектура высоких долин говорит о стойкости и заботе о путешественниках.',
      'tash_rabat.visitingRules':
          'Следуйте местным указаниям внутри сооружения, не используйте дым или свечи и берегите окружающие пастбища.',
      'tash_rabat.route':
          'Из Нарына двигайтесь в сторону Ат-Башы и продолжайте по горной дороге на подходящем транспорте.',
      'saimaluu_tash.title': 'Саймалуу-Таш',
      'saimaluu_tash.shortDescription':
          'Высокогорный ландшафт петроглифов с тысячами каменных изображений.',
      'saimaluu_tash.description':
          'Саймалуу-Таш представлен как премиальный маршрут наследия: удаленный, мощный и визуально особенный.',
      'saimaluu_tash.culturalNote':
          'Рисунки показаны как горный архив движения, ритуалов, животных и наблюдений за небом.',
      'saimaluu_tash.visitingRules':
          'Идите с гидом, никогда не царапайте и не натирайте рисунки мелом, готовьтесь к погоде и оставляйте место таким, каким нашли.',
      'saimaluu_tash.route':
          'Доступ сезонный и удаленный. Прототип рекомендует поездку с гидом со стороны Джалал-Абада или Нарына.',
      'manas_ordo.title': 'Манас Ордо',
      'manas_ordo.shortDescription':
          'Мемориальный комплекс, связанный с эпосом Манас.',
      'manas_ordo.description':
          'Демо-контент делает это место пространством эпической памяти, уважительного рассказа и обучения через остановки с гидом.',
      'manas_ordo.culturalNote':
          'Эпос Манас занимает центральное место в идентичности, устной истории и общей культурной памяти.',
      'manas_ordo.visitingRules':
          'Сохраняйте уважительный тон, соблюдайте правила музея и не мешайте церемониям или экскурсионным группам.',
      'manas_ordo.route':
          'Из города Талас двигайтесь по дороге к комплексу; есть указатели и местный транспорт.',
      'sulaiman_too.title': 'Сулайман-Тоо',
      'sulaiman_too.shortDescription':
          'Священная гора, возвышающаяся в сердце Оша.',
      'sulaiman_too.description':
          'Сулайман-Тоо - центральное место прототипа: маршруты, смотровые точки, музейные остановки и этикет священных пространств.',
      'sulaiman_too.culturalNote':
          'Гора соединяет паломничество, городскую жизнь, память и многослойную историю Ферганской долины.',
      'sulaiman_too.visitingRules':
          'Одевайтесь скромно, уважайте молитвенные места, не блокируйте тропы и спрашивайте перед съемкой посетителей.',
      'sulaiman_too.route':
          'Начните из центра Оша и используйте отмеченные пешие маршруты вокруг горы и музейных зон.',
      'osh_spring.title': 'Старый источник Ак-Буура',
      'osh_spring.shortDescription':
          'Локальная водная остановка на старом городском маршруте.',
      'osh_spring.description':
          'Эта демо-запись показывает, что каталог может включать как известные, так и районные священные водные места.',
      'osh_spring.culturalNote':
          'Водные места часто несут повседневные традиции: приветствовать старших, делить тень и поддерживать чистоту.',
      'osh_spring.visitingRules':
          'Не загрязняйте воду, держите емкости аккуратно и оставляйте пространство местным жителям.',
      'osh_spring.route':
          'Используйте местные подсказки из центра Оша; маршрут задуман как короткий городской визит.',
      'arslanbob.title': 'Священный лес Арсланбоб',
      'arslanbob.shortDescription':
          'Ореховые леса, водопады и прогулки с местными проводниками.',
      'arslanbob.description':
          'Приложение показывает Арсланбоб как живой ландшафт, где встречаются природа, местный уклад и забота о посетителях.',
      'arslanbob.culturalNote':
          'Лесные маршруты связаны с гостеприимством, сезонами урожая и историями, передаваемыми в семьях.',
      'arslanbob.visitingRules':
          'Пользуйтесь местными тропами, не повреждайте деревья, уважайте частные сады и по возможности поддерживайте местных гидов.',
      'arslanbob.route':
          'Езжайте из Джалал-Абада в сторону Базар-Коргона и дальше к селу Арсланбоб.',
      'jalal_abad_springs.title': 'Источники Джалал-Абада',
      'jalal_abad_springs.shortDescription':
          'Традиции целебной воды в курортном городе.',
      'jalal_abad_springs.description':
          'Эта демо-запись показывает, как оздоровление, местная история и этикет священной воды могут находиться на одном экране.',
      'jalal_abad_springs.culturalNote':
          'Люди приходят к источникам с надеждой на здоровье, благодарностью и тихим обновлением.',
      'jalal_abad_springs.visitingRules':
          'Соблюдайте размещенные правила, не перекрывайте доступ к воде и держите зоны купания или питья чистыми.',
      'jalal_abad_springs.route':
          'Доберитесь до курортной зоны из города Джалал-Абад по местной дороге.',
      'aigul_tash.title': 'Айгуль-Таш',
      'aigul_tash.shortDescription':
          'Каменистый склон, связанный с редким цветком Айгуль и местной легендой.',
      'aigul_tash.description':
          'Айгуль-Таш добавляет в MVP южную природную историю с сезонным ритмом и сильным посланием о сохранении.',
      'aigul_tash.culturalNote':
          'Цветок Айгуль представлен как символ красоты, утраты и заботы о редком живом наследии.',
      'aigul_tash.visitingRules':
          'Никогда не срывайте цветы, оставайтесь на отмеченных тропах, посещайте с местными подсказками и берегите хрупкие склоны.',
      'aigul_tash.route':
          'Езжайте из города Баткен к охраняемой зоне в разрешенный сезон.',
    },
    'ky': {
      'burana.title': 'Бурана мунарасы',
      'burana.shortDescription':
          'Байыркы Баласагундун жанындагы мунара жана ачык асман алдындагы музей.',
      'burana.description':
          'Бурана мунарасы түндүк Кыргызстандагы эң таанымал мурас жайларынын бири. Демо окуя аны кербен жолдору, таш балбалдар жана Жибек жолундагы шаар турмушу тууралуу үйрөнүүнүн тынч башаты катары көрсөтөт.',
      'burana.culturalNote':
          'Зыяратчылар бул жерди эс тутум, сапар жана өрөөн аркылуу өткөн тилдер менен өнөрлөрдүн узак алмашуусу менен байланыштырышат.',
      'burana.visitingRules':
          'Таштардын жанында этият басыңыз, тыюу салынган жерлерге чыкпаңыз, эстеликтердин жанында акырын сүйлөңүз жана из калтырбаңыз.',
      'burana.route':
          'Бишкектен Токмок тарапка барыңыз. Акыркы бөлүгүн жергиликтүү транспорт же кыска такси сапары менен бүтүрсө болот.',
      'ala_archa.title': 'Ала-Арча ыйык өрөөнү',
      'ala_archa.shortDescription':
          'Тоо жолдору, тунук суу жана ой жүгүртүүгө ылайыктуу тынч жайлар.',
      'ala_archa.description':
          'Бул прототип Ала-Арчаны табиятка негизделген ыйык маршрут катары көрсөтөт: урматтуу жөө жүрүү, суу булактары жана корголгон тоо мейкиндигине кирүү сезими.',
      'ala_archa.culturalNote':
          'Тоо өрөөндөрүнө көбүнчө аяр мамиле жасалат, анткени суу, таш жана жолдор үй-бүлөлүк жана сезондук эстутумду алып жүрөт.',
      'ala_archa.visitingRules':
          'Белгиленген жолдордон чыкпаңыз, жапайы жаныбарларды сыйлаңыз, катуу музыка койбоңуз жана таштандыны алып кетиңиз.',
      'ala_archa.route':
          'Паркка Бишкектен машина же уюштурулган транспорт менен жетип, андан соң белгиленген жолдор менен жүрүңүз.',
      'cholpon_ata.title': 'Чолпон-Ата петроглифтери',
      'cholpon_ata.shortDescription':
          'Ысык-Көлдүн жанындагы жаныбарлар жана аңчылык көрүнүштөрү түшүрүлгөн ачык асман алдындагы таш сүрөттөр.',
      'cholpon_ata.description':
          'Петроглиф талаасы MVP үчүн күчтүү визуалдык негиз берет: байыркы таштар, символдук жаныбарлар жана галереядай изилдене турган маршрут.',
      'cholpon_ata.culturalNote':
          'Аска сүрөттөрү байкоо, ишеним жана ландшафт аркылуу кыймылдын назик жазмалары катары берилет.',
      'cholpon_ata.visitingRules':
          'Оюмдарды кармабаңыз жана сызып чыкпаңыз, жолдон чыкпаңыз, талап кылынса жарк эттирбей сүрөткө тартыңыз жана белгиленген таштарды баспаңыз.',
      'cholpon_ata.route':
          'Ысык-Көлдүн түндүк жээгиндеги Чолпон-Атага барып, жергиликтүү музей белгилерин ээрчиңиз.',
      'manjyly_ata.title': 'Манжылы-Ата булактары',
      'manjyly_ata.shortDescription':
          'Бата, тынч сейил жана үй-бүлөлүк зыяраттар менен байланышкан булак аймагы.',
      'manjyly_ata.description':
          'Экран суу, кургак дөңсөөлөр, көл абасы жана урмат менен мамиле кылынуучу майда ырымдар аркылуу аң-сезимдүү зыяратты баса белгилейт.',
      'manjyly_ata.culturalNote':
          'Булактар көп учурда шыпаа, ыраазычылык жана суу жанындагы этият жүрүм-турум менен байланышат.',
      'manjyly_ata.visitingRules':
          'Урматтуу кийиниңиз, булакты таза кармаңыз, жеке дубаларга тоскоол болбоңуз жана адамдарды тартуудан мурда уруксат сураңыз.',
      'manjyly_ata.route':
          'Ысык-Көлдүн түштүк жээгиндеги жолдон барыңыз; жергиликтүү гиддер булак аймагын табууга жардам берет.',
      'jeti_oguz.title': 'Жети-Өгүз кызыл аскалары',
      'jeti_oguz.shortDescription':
          'Караколдун жанындагы кызыл жарлар, уламыштар жана тоо абасы.',
      'jeti_oguz.description':
          'Жети-Өгүз прототипте жергиликтүү уламыштарга жана назик боорлордо этият жүрүүгө көңүл бурган таасирдүү табият окуясы катары колдонулат.',
      'jeti_oguz.culturalNote':
          'Ландшафт уламыштары табигый түзүлүш эмне үчүн эмоциялык жана маданий мааниге ээ экенин түшүнүүгө жардам берет.',
      'jeti_oguz.visitingRules':
          'Туруксуз боорлорго чыкпаңыз, эс алуу жайларын таза кармаңыз жана жергиликтүү окуяларга урмат менен мамиле кылыңыз.',
      'jeti_oguz.route':
          'Караколдон Жети-Өгүз айылына барып, андан соң негизги аска көрүнүштөрүнө улантыңыз.',
      'tash_rabat.title': 'Таш-Рабат кербен сарайы',
      'tash_rabat.shortDescription': 'Бийик тоо өрөөнүндөгү таш кербен сарай.',
      'tash_rabat.description':
          'Демо Таш-Рабатты баш калкалоо, соода, аба ырайы жана тоо меймандостугун түшүнүүчү жай катары көрсөтөт.',
      'tash_rabat.culturalNote':
          'Бийик өрөөндөрдөгү таш архитектура туруктуулукту жана жолоочуларга камкордукту билдирет.',
      'tash_rabat.visitingRules':
          'Имарат ичинде жергиликтүү көрсөтмөлөрдү аткарыңыз, түтүн же шам колдонбоңуз жана тегеректеги жайытты сактаңыз.',
      'tash_rabat.route':
          'Нарындан Ат-Башы тарапка чыгып, ылайыктуу транспорт менен тоо жолун улантыңыз.',
      'saimaluu_tash.title': 'Саймалуу-Таш',
      'saimaluu_tash.shortDescription':
          'Миңдеген таш сүрөттөрү бар бийик тоолуу петроглиф ландшафты.',
      'saimaluu_tash.description':
          'Саймалуу-Таш колдонмодо алыскы, күчтүү жана визуалдык жактан өзгөчө премиум мурас маршруту катары берилет.',
      'saimaluu_tash.culturalNote':
          'Сүрөттөр кыймыл, ырым-жырым, жаныбарлар жана асманды байкоонун тоолук архиви катары көрсөтүлөт.',
      'saimaluu_tash.visitingRules':
          'Гид менен барыңыз, оюмдарды эч качан тырмабаңыз же бор менен белгилебеңиз, аба ырайына даяр болуңуз жана жайды кандай тапсаңыз ошондой калтырыңыз.',
      'saimaluu_tash.route':
          'Кирүү сезондук жана алыс. Прототип Жалал-Абад же Нарын тараптан гид менен барууну сунуштайт.',
      'manas_ordo.title': 'Манас Ордо',
      'manas_ordo.shortDescription':
          'Манас эпосу менен байланышкан мемориалдык комплекс.',
      'manas_ordo.description':
          'Демо контент бул жерди эпикалык эстутум, урматтуу баяндоо жана гид менен үйрөнүү мейкиндиги катары көрсөтөт.',
      'manas_ordo.culturalNote':
          'Манас эпосу өздүк аң-сезимдин, оозеки тарыхтын жана жалпы маданий эстутумдун борборунда турат.',
      'manas_ordo.visitingRules':
          'Урматтуу тонду сактаңыз, музей эрежелерин аткарыңыз жана аземдерге же экскурсия топторуна тоскоол болбоңуз.',
      'manas_ordo.route':
          'Талас шаарынан комплекске карай жол менен барыңыз; белгилер жана жергиликтүү транспорт бар.',
      'sulaiman_too.title': 'Сулайман-Тоо',
      'sulaiman_too.shortDescription': 'Оштун жүрөгүнөн көтөрүлгөн ыйык тоо.',
      'sulaiman_too.description':
          'Сулайман-Тоо прототиптин борбордук жайы: маршруттар, көрүү чекиттери, музей токтоолору жана ыйык мейкиндиктердин адеби.',
      'sulaiman_too.culturalNote':
          'Тоо зыяратты, шаар турмушун, эстутумду жана Фергана өрөөнүнүн көп катмарлуу тарыхын бириктирет.',
      'sulaiman_too.visitingRules':
          'Жөнөкөй кийиниңиз, намаз жайларын сыйлаңыз, жолдорду бош кармаңыз жана зыяратчыларды тартуудан мурда сураңыз.',
      'sulaiman_too.route':
          'Оштун борборунан баштап, тоо жана музей аймактарынын белгиленген жөө жолдорун колдонуңуз.',
      'osh_spring.title': 'Ак-Буура эски булагы',
      'osh_spring.shortDescription':
          'Эски шаар маршруту боюнча жергиликтүү суу токтоочу жай.',
      'osh_spring.description':
          'Бул демо жазуу каталог белгилүү жайларды да, коңшулаш деңгээлдеги ыйык суу жерлерин да камтый аларын көрсөтөт.',
      'osh_spring.culturalNote':
          'Суу жерлери күнүмдүк салттарды алып жүрөт: улуулар менен учурашуу, көлөкөнү бөлүшүү жана аймакты таза кармоо.',
      'osh_spring.visitingRules':
          'Сууну булгабаңыз, идиштерди иреттүү кармаңыз жана жергиликтүү тургундарга орун бериңиз.',
      'osh_spring.route':
          'Оштун борборунан жергиликтүү багыттарды колдонуңуз; маршрут кыска шаардык зыярат катары ойлонулган.',
      'arslanbob.title': 'Арстанбап ыйык токою',
      'arslanbob.shortDescription':
          'Жаңгак токойлору, шаркыратмалар жана коомчулук жетектеген сейилдер.',
      'arslanbob.description':
          'Колдонмо Арстанбапты табият, жергиликтүү турмуш жана зыяратчыга камкордук жолуккан тирүү ландшафт катары көрсөтөт.',
      'arslanbob.culturalNote':
          'Токой маршруттары меймандостук, түшүм мезгилдери жана үй-бүлөлөр аркылуу өткөн окуялар менен байланышкан.',
      'arslanbob.visitingRules':
          'Жергиликтүү жолдорду колдонуңуз, бактарды зыянга учуратпаңыз, жеке бакчаларды сыйлаңыз жана мүмкүн болсо жергиликтүү гиддерди колдоңуз.',
      'arslanbob.route':
          'Жалал-Абаддан Базар-Коргон тарапка чыгып, андан ары Арстанбап айылына барыңыз.',
      'jalal_abad_springs.title': 'Жалал-Абад булактары',
      'jalal_abad_springs.shortDescription':
          'Курорт шаардагы шыпаалуу суу салттары.',
      'jalal_abad_springs.description':
          'Бул демо жазуу ден соолук, жергиликтүү тарых жана ыйык суу адеби бир деталдык экранда боло аларын көрсөтөт.',
      'jalal_abad_springs.culturalNote':
          'Адамдар булактарга ден соолук үмүтү, ыраазычылык жана тынч жаңылануу үчүн келишет.',
      'jalal_abad_springs.visitingRules':
          'Жазылган эрежелерди сактаңыз, суу жеткиликтүүлүгүн тоспоңуз жана жуунуу же ичүү аймактарын таза кармаңыз.',
      'jalal_abad_springs.route':
          'Курорт аймагына Жалал-Абад шаарынан жергиликтүү жол менен жетсе болот.',
      'aigul_tash.title': 'Айгүл-Таш',
      'aigul_tash.shortDescription':
          'Сейрек Айгүл гүлү жана жергиликтүү уламыш менен байланышкан таштуу боор.',
      'aigul_tash.description':
          'Айгүл-Таш MVPге сезондук ыргагы жана сактоо тууралуу күчтүү билдирүүсү бар түштүк табият окуясын кошот.',
      'aigul_tash.culturalNote':
          'Айгүл гүлү сулуулуктун, жоготуунун жана сейрек тирүү мураска кам көрүүнүн белгиси катары берилет.',
      'aigul_tash.visitingRules':
          'Гүлдөрдү эч качан үзбөңүз, белгиленген жолдордо жүрүңүз, жергиликтүү көрсөтмө менен барыңыз жана назик боорлорду сактаңыз.',
      'aigul_tash.route':
          'Баткен шаарынан корголгон аймакка уруксат берилген мезгилде барыңыз.',
    },
  };

  static const _characters = <String, Map<String, String>>{
    'ru': {
      'atashka.name': 'Аташка',
      'atashka.role': 'Хранитель истории',
      'apashka.name': 'Апашка',
      'apashka.role': 'Проводник традиций',
    },
    'ky': {
      'atashka.name': 'Аташка',
      'atashka.role': 'Тарых сакчысы',
      'apashka.name': 'Апашка',
      'apashka.role': 'Салт жол көрсөткүчү',
    },
  };

  static const _reviews = <String, Map<String, String>>{
    'ru': {
      'sulaiman_too.Aizada':
          'Закат с тропы был незабываемым. Идите рано и возьмите воду.',
      'cholpon_ata.Temir':
          'Камни требуют терпения. С гидом рисунки легче читать.',
      'burana.Nurai':
          'Спокойная остановка с сильной историей. Балбалы - лучшая часть.',
      'arslanbob.Daniel':
          'Красивый лесной маршрут и теплое местное сопровождение.',
    },
    'ky': {
      'sulaiman_too.Aizada':
          'Жолдогу күн батыш унутулгус болду. Эрте барып, суу алып алыңыз.',
      'cholpon_ata.Temir':
          'Таштар сабырдуулукту талап кылат. Гид менен сүрөттөрдү түшүнүү жеңилирээк.',
      'burana.Nurai':
          'Тарыхы күчтүү тынч токтоочу жай. Балбалдар эң кызыктуу бөлүгү.',
      'arslanbob.Daniel':
          'Кооз токой маршруту жана жылуу жергиликтүү жол көрсөтүү.',
    },
  };

  static const _posts = <String, Map<String, String>>{
    'ru': {
      'p1':
          'На Сулайман-Тоо лучше идти до дневной жары. Верхняя тропа на рассвете тихая.',
      'p2':
          'Дорога после дождя возле Таш-Рабата бывает тяжелой. Помог транспорт с высоким клиренсом.',
      'p3':
          'В Чолпон-Ате изображения животных легче увидеть, когда солнце ниже.',
    },
    'ky': {
      'p1':
          'Сулайман-Тоого түштөн кийинки ысыкка чейин барган жакшы. Жогорку жол таң атканда тынч болот.',
      'p2':
          'Таш-Рабаттын жанындагы жол жамгырдан кийин оор болушу мүмкүн. Бийик клиренстүү унаа жардам берди.',
      'p3':
          'Чолпон-Атада күн төмөндөгөндө жаныбарлардын сүрөттөрү жакшыраак көрүнөт.',
    },
  };

  static const _bookings = <String, Map<String, String>>{
    'ru': {'b1.notes': 'Нужен гид для музея камней.'},
    'ky': {'b1.notes': 'Таш музейи үчүн гид керек.'},
  };

  static const _phrases = <String, Map<String, String>>{
    'ru': {
      'Guest': 'Гость',
      'You': 'Вы',
      'Salam': 'Салам',
      'Seven regions': 'Семь регионов',
      'Choose a route': 'Выберите маршрут',
      'Ask Apashka': 'Спросить Апашку',
      'Rules and stories': 'Правила и истории',
      'Visit request': 'Заявка на визит',
      'Plan respectfully': 'Планировать с уважением',
      'Sacred catalog': 'Каталог святынь',
      'Search shrines, stones, springs': 'Ищите святыни, камни, источники',
      'Community yurt': 'Юрта сообщества',
      'Read tips from visitors': 'Читайте советы посетителей',
      'Language and theme': 'Язык и тема',
      'Theme, language, music': 'Тема, язык, музыка',
      'Account': 'Аккаунт',
      'Bookings and favorites': 'Заявки и избранное',
      'regions': 'регионов',
      'places': 'мест',
      'saved': 'сохранено',
      'Pilgrim paths': 'Пути паломников',
      'Open catalog': 'Открыть каталог',
      'Sacred highlights': 'Священные акценты',
      'See all': 'Смотреть все',
      'More to explore': 'Еще для изучения',
      'Sacred KG cultural routes': 'Культурные маршруты Sacred KG',
      'Tunduk route': 'Маршрут түндүк',
      'Kyrgyz sacred routes': 'Священные маршруты Кыргызстана',
      'Mountains, petroglyphs, springs, and stories held with respect.':
          'Горы, петроглифы, источники и истории, к которым относятся с уважением.',
      'Open regions': 'Открыть регионы',
      'shared sky': 'общее небо',
      'ornament paths': 'орнаментальные пути',
      'living memory': 'живая память',
      'Choose a region': 'Выберите регион',
      'Seven sacred directions': 'Семь священных направлений',
      'All places': 'Все места',
      'Regional routes': 'Региональные маршруты',
      'Kyrgyzstan regions': 'Регионы Кыргызстана',
      'Choose a sacred direction': 'Выберите священное направление',
      'Browse valleys, lake routes, southern mountains, forests, and petroglyph paths.':
          'Просматривайте долины, озерные маршруты, южные горы, леса и пути к петроглифам.',
      'petroglyphs': 'петроглифов',
      'Featured: {place}': 'Главное: {place}',
      'No places yet': 'Мест пока нет',
      '{region} places': 'Места региона {region}',
      '{count} sacred places': '{count} священных мест',
      'No matching places yet.': 'Подходящих мест пока нет.',
      'All Kyrgyzstan': 'Весь Кыргызстан',
      '{count} places with stories, rules, routes, and local mock reviews.':
          '{count} мест с историями, правилами, маршрутами и демо-отзывами.',
      'Find a place by name or story': 'Найдите место по названию или истории',
      'Search sacred places': 'Искать священные места',
      '{count} filters': '{count} фильтров',
      'Route filters': 'Фильтры маршрута',
      'All regions': 'Все регионы',
      'All types': 'Все типы',
      'Rating': 'Рейтинг',
      'Popular': 'Популярные',
      'Clear': 'Очистить',
      'Top rated': 'Лучшие по рейтингу',
      'Sacred knowledge': 'Священное знание',
      'Cultural note': 'Культурная заметка',
      'Visiting rules': 'Правила посещения',
      'Route': 'Маршрут',
      'Place palette': 'Палитра места',
      'Visitor voices': 'Голоса посетителей',
      'No local reviews for this place yet.':
          'Локальных отзывов об этом месте пока нет.',
      'Story of the place': 'История места',
      'Ask guide': 'Спросить гида',
      'Plan visit': 'Запланировать визит',
      'type': 'тип',
      'popular': 'популярность',
      'reviews': 'отзывы',
      'rating': 'рейтинг',
      'AI guide': 'AI-гид',
      'Choose your guide': 'Выберите гида',
      'Conversation': 'Разговор',
      'Ask a cultural guide': 'Спросить культурного гида',
      'Mock guidance for rules, stories, routes, and traditions.':
          'Демо-подсказки о правилах, историях, маршрутах и традициях.',
      'Place-aware mock answers for etiquette, stories, and visit planning.':
          'Демо-ответы с учетом места, этикета, историй и планирования визита.',
      'What is special here?': 'Что здесь особенного?',
      'What rules should I follow?': 'Какие правила соблюдать?',
      'Best time to visit?': 'Лучшее время для визита?',
      'How do I get there?': 'Как добраться?',
      'Ask about rules, route, or traditions':
          'Спросите о правилах, маршруте или традициях',
      'Salam. Ask about rules, history, route, traditions, or the best time to visit.':
          'Салам. Спросите о правилах, истории, маршруте, традициях или лучшем времени визита.',
      'Community': 'Сообщество',
      'New post': 'Новая публикация',
      'Share a review, tip, issue, or experience':
          'Поделитесь отзывом, советом, проблемой или впечатлением',
      'Post type': 'Тип публикации',
      'Related place': 'Связанное место',
      'No place': 'Без места',
      'Publish locally': 'Опубликовать локально',
      'Booking request': 'Заявка на посещение',
      'Plan your visit': 'План визита',
      '1. Sacred place': '1. Священное место',
      'Choose where the visit request should go.':
          'Выберите место для заявки на визит.',
      'Place': 'Место',
      '2. Visit date': '2. Дата визита',
      '3. Visitors': '3. Посетители',
      'Keep the group size clear for local planning.':
          'Укажите размер группы для местного планирования.',
      'people': 'человек',
      '4. Notes for the visit': '4. Заметки к визиту',
      'Add guide requests, transport notes, or accessibility needs.':
          'Добавьте запросы к гиду, заметки о транспорте или потребности доступности.',
      'Optional notes': 'Необязательные заметки',
      '5. Visiting rules': '5. Правила посещения',
      'I will keep the place clean, respect prayer or ritual spaces, and follow local guidance.':
          'Я сохраню место чистым, буду уважать молитвенные или ритуальные пространства и следовать местным указаниям.',
      'Visit request saved locally.': 'Заявка на визит сохранена локально.',
      'Send visit request': 'Отправить заявку',
      'My visit requests': 'Мои заявки на визит',
      'Respectful visit': 'Уважительный визит',
      'Choose date, group size, and rules before sending a local request.':
          'Выберите дату, размер группы и правила перед отправкой локальной заявки.',
      'Moon marker: mock calendar': 'Лунная метка: демо-календарь',
      'this place': 'это место',
      'I would approach it gently:': 'Я бы подошла к этому бережно:',
      'From the heritage record:': 'Из записи о наследии:',
      'at {target}, keep the visit quiet, do not touch fragile stones or water sources, ask before photographing people, and leave the path cleaner than you found it.':
          'в месте {target} сохраняйте тишину, не трогайте хрупкие камни или источники, спрашивайте перед съемкой людей и оставьте тропу чище, чем нашли.',
      'early morning is usually best for comfort, photos, and calm movement. Mountain routes should be checked seasonally and with local guidance.':
          'раннее утро обычно лучше для комфорта, фотографий и спокойного движения. Горные маршруты нужно проверять по сезону и с местными подсказками.',
      'choose a region first, then the app can show a simple route note for the selected sacred place.':
          'сначала выберите регион, затем приложение покажет простую заметку о маршруте к выбранному священному месту.',
      'many Kyrgyz sacred places connect water, stone, mountains, family memory, and respectful silence.':
          'многие священные места Кыргызстана соединяют воду, камень, горы, семейную память и уважительную тишину.',
      'ask about rules, history, route, or best time to visit, and I will answer with mock local guidance.':
          'спросите о правилах, истории, маршруте или лучшем времени визита, и я отвечу демо-подсказкой.',
    },
    'ky': {
      'Guest': 'Конок',
      'You': 'Сиз',
      'Salam': 'Салам',
      'Seven regions': 'Жети регион',
      'Choose a route': 'Маршрут тандаңыз',
      'Ask Apashka': 'Апашкадан сураңыз',
      'Rules and stories': 'Эрежелер жана окуялар',
      'Visit request': 'Зыярат өтүнмөсү',
      'Plan respectfully': 'Урмат менен пландаңыз',
      'Sacred catalog': 'Ыйык жерлер каталогу',
      'Search shrines, stones, springs': 'Ыйык жай, таш, булак издеңиз',
      'Community yurt': 'Коомчулук боз үйү',
      'Read tips from visitors': 'Зыяратчылардын кеңештерин окуңуз',
      'Language and theme': 'Тил жана тема',
      'Theme, language, music': 'Тема, тил, музыка',
      'Account': 'Аккаунт',
      'Bookings and favorites': 'Өтүнмөлөр жана тандалгандар',
      'regions': 'регион',
      'places': 'жер',
      'saved': 'сакталды',
      'Pilgrim paths': 'Зыярат жолдору',
      'Open catalog': 'Каталогду ачуу',
      'Sacred highlights': 'Ыйык негизгилер',
      'See all': 'Баарын көрүү',
      'More to explore': 'Дагы изилдөө',
      'Sacred KG cultural routes': 'Sacred KG маданий маршруттары',
      'Tunduk route': 'Түндүк маршруту',
      'Kyrgyz sacred routes': 'Кыргызстандын ыйык маршруттары',
      'Mountains, petroglyphs, springs, and stories held with respect.':
          'Тоолор, петроглифтер, булактар жана урмат менен сакталган окуялар.',
      'Open regions': 'Региондорду ачуу',
      'shared sky': 'жалпы асман',
      'ornament paths': 'оймо жолдор',
      'living memory': 'жандуу эстутум',
      'Choose a region': 'Регион тандаңыз',
      'Seven sacred directions': 'Жети ыйык багыт',
      'All places': 'Бардык жерлер',
      'Regional routes': 'Региондук маршруттар',
      'Kyrgyzstan regions': 'Кыргызстан региондору',
      'Choose a sacred direction': 'Ыйык багыт тандаңыз',
      'Browse valleys, lake routes, southern mountains, forests, and petroglyph paths.':
          'Өрөөндөрдү, көл маршруттарын, түштүк тоолорун, токойлорду жана петроглиф жолдорун караңыз.',
      'petroglyphs': 'петроглиф',
      'Featured: {place}': 'Негизги: {place}',
      'No places yet': 'Азырынча жер жок',
      '{region} places': '{region} жерлери',
      '{count} sacred places': '{count} ыйык жер',
      'No matching places yet.': 'Дал келген жер азырынча жок.',
      'All Kyrgyzstan': 'Бүткүл Кыргызстан',
      '{count} places with stories, rules, routes, and local mock reviews.':
          'Окуялары, эрежелери, маршруттары жана демо пикирлери бар {count} жер.',
      'Find a place by name or story': 'Жерди аталышы же окуясы менен табыңыз',
      'Search sacred places': 'Ыйык жерлерди издөө',
      '{count} filters': '{count} фильтр',
      'Route filters': 'Маршрут фильтрлери',
      'All regions': 'Бардык региондор',
      'All types': 'Бардык түрлөр',
      'Rating': 'Рейтинг',
      'Popular': 'Популярдуу',
      'Clear': 'Тазалоо',
      'Top rated': 'Жогорку рейтинг',
      'Sacred knowledge': 'Ыйык билим',
      'Cultural note': 'Маданий белги',
      'Visiting rules': 'Зыярат эрежелери',
      'Route': 'Маршрут',
      'Place palette': 'Жер палитрасы',
      'Visitor voices': 'Зыяратчылардын үнү',
      'No local reviews for this place yet.':
          'Бул жер боюнча жергиликтүү пикир азырынча жок.',
      'Story of the place': 'Жердин окуясы',
      'Ask guide': 'Гидден сураңыз',
      'Plan visit': 'Зыярат пландаңыз',
      'type': 'түрү',
      'popular': 'популярдуулук',
      'reviews': 'пикирлер',
      'rating': 'рейтинг',
      'AI guide': 'AI гид',
      'Choose your guide': 'Гидиңизди тандаңыз',
      'Conversation': 'Маек',
      'Ask a cultural guide': 'Маданий гидден сураңыз',
      'Mock guidance for rules, stories, routes, and traditions.':
          'Эрежелер, окуялар, маршруттар жана салттар боюнча демо кеңеш.',
      'Place-aware mock answers for etiquette, stories, and visit planning.':
          'Адеп, окуялар жана зыярат пландоо боюнча жерге ылайык демо жооптор.',
      'What is special here?': 'Бул жерде эмне өзгөчө?',
      'What rules should I follow?': 'Кайсы эрежелерди сактайм?',
      'Best time to visit?': 'Зыярат үчүн эң жакшы убакыт?',
      'How do I get there?': 'Кантип барам?',
      'Ask about rules, route, or traditions':
          'Эрежелер, маршрут же салттар тууралуу сураңыз',
      'Salam. Ask about rules, history, route, traditions, or the best time to visit.':
          'Салам. Эреже, тарых, маршрут, салт же жакшы убакыт тууралуу сураңыз.',
      'Community': 'Коомчулук',
      'New post': 'Жаңы билдирүү',
      'Share a review, tip, issue, or experience':
          'Пикир, кеңеш, маселе же таасир бөлүшүңүз',
      'Post type': 'Билдирүү түрү',
      'Related place': 'Байланышкан жер',
      'No place': 'Жер жок',
      'Publish locally': 'Локалдык жарыялоо',
      'Booking request': 'Зыярат өтүнмөсү',
      'Plan your visit': 'Зыяратты пландаңыз',
      '1. Sacred place': '1. Ыйык жер',
      'Choose where the visit request should go.':
          'Зыярат өтүнмөсү кайсы жерге жөнөтүлөрүн тандаңыз.',
      'Place': 'Жер',
      '2. Visit date': '2. Зыярат күнү',
      '3. Visitors': '3. Зыяратчылар',
      'Keep the group size clear for local planning.':
          'Жергиликтүү пландоо үчүн топтун санын так көрсөтүңүз.',
      'people': 'адам',
      '4. Notes for the visit': '4. Зыяратка эскертмелер',
      'Add guide requests, transport notes, or accessibility needs.':
          'Гид өтүнүчтөрүн, транспорт эскертмелерин же жеткиликтүүлүк муктаждыктарын кошуңуз.',
      'Optional notes': 'Кошумча эскертмелер',
      '5. Visiting rules': '5. Зыярат эрежелери',
      'I will keep the place clean, respect prayer or ritual spaces, and follow local guidance.':
          'Мен жерди таза кармайм, намаз же ырым жайларын сыйлайм жана жергиликтүү көрсөтмөлөрдү аткарам.',
      'Visit request saved locally.': 'Зыярат өтүнмөсү локалдык сакталды.',
      'Send visit request': 'Өтүнмө жөнөтүү',
      'My visit requests': 'Менин зыярат өтүнмөлөрүм',
      'Respectful visit': 'Урматтуу зыярат',
      'Choose date, group size, and rules before sending a local request.':
          'Локалдык өтүнмө жөнөтүүдөн мурда күндү, топ санын жана эрежелерди тандаңыз.',
      'Moon marker: mock calendar': 'Ай белгиси: демо календарь',
      'this place': 'бул жер',
      'I would approach it gently:': 'Мен бул жерге аяр мамиле кылмакмын:',
      'From the heritage record:': 'Мурас жазмасынан:',
      'at {target}, keep the visit quiet, do not touch fragile stones or water sources, ask before photographing people, and leave the path cleaner than you found it.':
          '{target} жеринде тынч болуңуз, назик таштарды же суу булактарын кармабаңыз, адамдарды тартуудан мурда уруксат сураңыз жана жолду тапканыңыздан таза калтырыңыз.',
      'early morning is usually best for comfort, photos, and calm movement. Mountain routes should be checked seasonally and with local guidance.':
          'эрте таң адатта ыңгайлуулук, сүрөт жана тынч жүрүү үчүн жакшы. Тоо маршруттарын мезгилге жараша жана жергиликтүү кеңеш менен текшерүү керек.',
      'choose a region first, then the app can show a simple route note for the selected sacred place.':
          'алгач регион тандаңыз, андан соң колдонмо тандалган ыйык жерге жөнөкөй маршрут маалыматын көрсөтөт.',
      'many Kyrgyz sacred places connect water, stone, mountains, family memory, and respectful silence.':
          'Кыргызстандын көптөгөн ыйык жерлери суу, таш, тоо, үй-бүлөлүк эстутум жана урматтуу тынчтыкты бириктирет.',
      'ask about rules, history, route, or best time to visit, and I will answer with mock local guidance.':
          'эрежелер, тарых, маршрут же зыярат үчүн жакшы убакыт тууралуу сураңыз, мен демо жергиликтүү кеңеш менен жооп берем.',
    },
  };
}
