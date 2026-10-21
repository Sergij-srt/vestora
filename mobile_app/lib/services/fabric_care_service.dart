enum CareSymbolCategory {
  wash('Прання 🧺'),
  bleach('Відбілювання 🧴'),
  dry('Сушіння 🌬️'),
  iron('Прасування ♨️'),
  dryClean('Хімчистка 🧼');

  final String label;
  const CareSymbolCategory(this.label);
}

class CareSymbolItem {
  final String iconEmoji;
  final String title;
  final CareSymbolCategory category;
  final String description;
  final String tip;

  const CareSymbolItem({
    required this.iconEmoji,
    required this.title,
    required this.category,
    required this.description,
    required this.tip,
  });
}

class StainRescueGuide {
  final String stainType;
  final String iconEmoji;
  final String goldenRule;
  final List<String> steps;
  final String warning;

  const StainRescueGuide({
    required this.stainType,
    required this.iconEmoji,
    required this.goldenRule,
    required this.steps,
    required this.warning,
  });
}

class FabricGuideItem {
  final String fabricName;
  final String iconEmoji;
  final String luxuryRank;
  final String washingRule;
  final String dryingRule;
  final String storageRule;
  final String proStylistSecret;

  const FabricGuideItem({
    required this.fabricName,
    required this.iconEmoji,
    required this.luxuryRank,
    required this.washingRule,
    required this.dryingRule,
    required this.storageRule,
    required this.proStylistSecret,
  });
}

class FabricCareService {
  static const List<CareSymbolItem> symbols = [
    CareSymbolItem(
      iconEmoji: '🧺',
      title: 'Делікатне прання 30°C',
      category: CareSymbolCategory.wash,
      description: 'Температура води максимум 30°C на делікатному режимі з мінімальним віджимом (до 600 об/хв).',
      tip: 'Ідеально для вовни, змішаного трикотажу та тонкої бавовни.',
    ),
    CareSymbolItem(
      iconEmoji: '🤲',
      title: 'Тільки ручне прання',
      category: CareSymbolCategory.wash,
      description: 'Прання лише вручну при температурі до 30°C без тертя і викручування.',
      tip: 'Для шовку, тонкого кашеміру та мережива. Використовуйте рідкі засоби без ензимів.',
    ),
    CareSymbolItem(
      iconEmoji: '🚫🧺',
      title: 'Прання заборонено',
      category: CareSymbolCategory.wash,
      description: 'Річ не можна мочити у воді, оскільки волокна втратять структуру або дадуть усадку.',
      tip: 'Тільки суха професійна хімчистка (пальта, костюми, структуровані блейзери).',
    ),
    CareSymbolItem(
      iconEmoji: '📐',
      title: 'Сушіння на площині (Flat Dry)',
      category: CareSymbolCategory.dry,
      description: 'Розкласти річ горизонтально на рушнику без підвішування на плічки.',
      tip: 'Критично важливо для светрів: мокра вовна під власною вагою розтягується на 1-2 розміри.',
    ),
    CareSymbolItem(
      iconEmoji: '🚫🌀',
      title: 'Заборона барабанної сушки',
      category: CareSymbolCategory.dry,
      description: 'Не використовувати автоматичну сушильну машину.',
      tip: 'Гаряче повітря сушарки безповоротно зсідає натуральну вовну та руйнує еластан у денімі.',
    ),
    CareSymbolItem(
      iconEmoji: '•♨️',
      title: 'Прасування при 110°C (Низька t°)',
      category: CareSymbolCategory.iron,
      description: 'Прасування ледь теплою праскою без прямого контакту пари.',
      tip: 'Для шовку, ацетату, купро та поліестеру. Завжди прасуйте з виворітного боку.',
    ),
    CareSymbolItem(
      iconEmoji: '••♨️',
      title: 'Прасування при 150°C (Середня t°)',
      category: CareSymbolCategory.iron,
      description: 'Помірний нагрів із можливістю відпарювання.',
      tip: 'Підходить для тонкої вовни та змішаних костюмних тканин. Краще використовувати пропрасовувач.',
    ),
    CareSymbolItem(
      iconEmoji: '•••♨️',
      title: 'Прасування при 200°C (Висока t°)',
      category: CareSymbolCategory.iron,
      description: 'Максимальний нагрів із рясним зволоженням та парою.',
      tip: 'Для 100% льону та щільної бавовни. Льон найлегше розпрасовується, поки він ще злегка вологий.',
    ),
    CareSymbolItem(
      iconEmoji: '🅿️',
      title: 'Суха хімчистка (Dry Clean Only)',
      category: CareSymbolCategory.dryClean,
      description: 'Професійне чищення в розчинниках перхлоретилену.',
      tip: 'Довіряйте пальта та жакети лише сертифікованим екологічним хімчисткам.',
    ),
    CareSymbolItem(
      iconEmoji: '🚫🧴',
      title: 'Не відбілювати',
      category: CareSymbolCategory.bleach,
      description: 'Заборона хлоровмісних та агресивних окислювальних відбілювачів.',
      tip: 'Хлор спалює волокна тканини та призводить до жовтих плям, які неможливо вивести.',
    ),
  ];

  static const List<StainRescueGuide> stainGuides = [
    StainRescueGuide(
      stainType: 'Кава та чорний чай',
      iconEmoji: '☕',
      goldenRule: 'Ніколи не лийте гарячу воду — окріп «заварює» таніни у волокна назавжди!',
      steps: [
        '1. Негайно промокніть пляму сухою паперовою серветкою, не розтираючи.',
        '2. Промийте місце плями холодною проточною водою зі зворотного боку тканини.',
        '3. Нанесіть краплю рідкого мила або гліцерину на 10 хвилин.',
        '4. Промийте прохолодною водою та виперіть у делікатному режимі.',
      ],
      warning: 'Уникайте агресивного тертя — це розпушує волокна тканини.',
    ),
    StainRescueGuide(
      stainType: 'Червоне вино',
      iconEmoji: '🍷',
      goldenRule: 'Дійте в перші 60 секунд! Не давайте вину висохнути.',
      steps: [
        '1. Промокніть надлишок вина серветкою без тиску.',
        '2. Налийте на пляму газовану мінеральну воду — бульбашки виштовхують пігмент нагору.',
        '3. Посипте товстим шаром кухонної солі або харчової соди на 5 хвилин для абсорбції.',
        '4. Струсіть сіль і промийте прохолодною водою.',
      ],
      warning: 'Не використовуйте біле вино — це міф, який лише закріплює кислотний слід.',
    ),
    StainRescueGuide(
      stainType: 'Олія, соуси та жир',
      iconEmoji: '🍕',
      goldenRule: 'Жир вимагає сухого абсорбенту до будь-якого контакту з водою!',
      steps: [
        '1. Присипте пляму тальком, дитячою присипкою або кукурудзяним крохмалем.',
        '2. Залиште на 15–20 хвилин, щоб порошок ввібрав олійну основу.',
        '3. Зметіть порошок м\'якою щіточкою.',
        '4. Нанесіть краплю безбарвного гелю для миття посуду та делікатно промийте теплою водою.',
      ],
      warning: 'Не прасуйте масляну пляму праскою — температура полімеризує жир у тканину.',
    ),
    StainRescueGuide(
      stainType: 'Тональний крем та косметика',
      iconEmoji: '💄',
      goldenRule: 'Косметика містить віск і пігмент — використовуйте міцелярну воду.',
      steps: [
        '1. Змочіть ватний диск міцелярною водою без олій.',
        '2. Легкими дотиками від країв до центру розчиніть пігмент.',
        '3. Для комірців сорочок: нанесіть піну для гоління на 5 хвилин перед пранням.',
        '4. Виперіть як зазвичай відповідно до етикетки.',
      ],
      warning: 'Не затирайте сухими серветками — косметика проникне глибше у переплетення ниток.',
    ),
  ];

  static const List<FabricGuideItem> fabricGuides = [
    FabricGuideItem(
      fabricName: 'Кашемір та вовна мериноса',
      iconEmoji: '🐑',
      luxuryRank: 'Преміальна делікатність',
      washingRule: 'Ручне прання при 20-30°C зі спеціальним шампунем для кашеміру. Прання раз на 4–5 носінь — вовна має властивість самоочищення на свіжому повітрі.',
      dryingRule: 'Сушіння лише у розгорнутому вигляді на махровому рушнику на горизонтальній сушарці.',
      storageRule: 'Зберігати тільки складеним на полиці (ніколи на плічках!). У бавовняних чохлах із натуральними кедровими брусками від молі.',
      proStylistSecret: 'Використовуйте делікатний трикотажний гребінець або депілер раз на сезон для зняття пілінгу (кошлатання).',
    ),
    FabricGuideItem(
      fabricName: 'Натуральний льон',
      iconEmoji: '🌿',
      luxuryRank: 'Дихаюча літня класика',
      washingRule: 'Прання при 30–40°C. З кожним пранням якісний льон стає лише м\'якшим і приємнішим до тіла.',
      dryingRule: 'Сушити у затінку в природно розправленому вигляді. Уникати пересушування.',
      storageRule: 'Зберігати на дерев\'яних плічках із широкими полями.',
      proStylistSecret: 'Прасуйте льон з парою, коли він ще на 10% вологий. Пам\'ятайте: шляхетна легка прим\'ятість льону — ознака розкоші, а не недбалості.',
    ),
    FabricGuideItem(
      fabricName: 'Натуральний шовк (Mulberry silk)',
      iconEmoji: '🐛',
      luxuryRank: 'Висока розкіш & сенсорика',
      washingRule: 'Коротке ручне замочування у прохолодній воді з краплею рідкого шовкового мила. Без скручування!',
      dryingRule: 'Загорнути в сухий рушник для відведення зайвої вологи, сушити подалі від батарей і сонця.',
      storageRule: 'На шовкових або оксамитових вішалках, щоб тканина не зісковзувала і не чіплялася за дерево.',
      proStylistSecret: 'Прасувати лише з вивороту при мінімальній температурі (•) без розпилення води (краплі залишають розводи).',
    ),
    FabricGuideItem(
      fabricName: 'Натуральна гладка шкіра та замша',
      iconEmoji: '👞',
      luxuryRank: 'Довговічна інвестиція',
      washingRule: 'Вологе очищення мікрофіброю. Замшу чистити спеціальною каучуковою або креповою щіткою тільки в сухому стані.',
      dryingRule: 'Сушити за кімнатної температури. Для взуття обов\'язково використовувати кедрові колодки.',
      storageRule: 'У повітропроникних пильовиках (dust bags). Не пакувати у поліетиленові пакети.',
      proStylistSecret: 'Раз на 2–3 місяці живіть шкіру бальзамом з бджолиним воском і оновлюйте водовідштовхувальну мембрану спреєм.',
    ),
  ];
}
