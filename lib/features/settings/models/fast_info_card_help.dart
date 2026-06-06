enum FastInfoHelpAnchor {
  pillValue,
  pillTrend,
  title,
  primaryValue,
  secondaryValues,
  avatar,
  trend,
  visual,
}

class FastInfoHelpCallout {
  const FastInfoHelpCallout(this.anchor, this.label);

  final FastInfoHelpAnchor anchor;
  final String label;
}

class FastInfoCardHelp {
  const FastInfoCardHelp({
    required String purpose,
    required this.details,
    required List<String> calculation,
    required this.comparison,
    required this.missingData,
    required this.pillCallouts,
    required this.boxCallouts,
  }) : _purpose = purpose,
       _calculation = calculation;

  final String _purpose;
  final String details;
  final List<String> _calculation;
  final String comparison;
  final String missingData;
  final List<FastInfoHelpCallout> pillCallouts;
  final List<FastInfoHelpCallout> boxCallouts;

  String get purpose => _withPrefix(_purpose, 'Ez azt mutatja:');

  List<String> get calculation {
    if (_calculation.isEmpty) {
      return const <String>['Így számol: nincs külön képlet.'];
    }
    return <String>[
      _withPrefix(_calculation.first, 'Így számol:'),
      ..._calculation.skip(1),
    ];
  }
}

String _withPrefix(String value, String prefix) {
  return value.startsWith(prefix) ? value : '$prefix $value';
}

const genericFastInfoCardHelp = FastInfoCardHelp(
  purpose: 'Megmutatja a kiválasztott FastInfo adat rövid összefoglalóját.',
  details: 'Ehhez a kártyához nincs részletes magyarázat.',
  calculation: <String>['A számítást a FastInfo számító réteg végzi.'],
  comparison: 'Nincs külön összehasonlítás.',
  missingData: 'Ha nincs elég adat, a kártya Nincs adat állapotot mutat.',
  pillCallouts: <FastInfoHelpCallout>[_pillValue],
  boxCallouts: <FastInfoHelpCallout>[_title, _primaryValue, _secondaryValues],
);

FastInfoCardHelp fastInfoCardHelpForId(String id) {
  return fastInfoCardHelpById[id] ?? genericFastInfoCardHelp;
}

const _pillValue = FastInfoHelpCallout(
  FastInfoHelpAnchor.pillValue,
  'A kártya legfontosabb rövid értéke',
);
const _pillTrend = FastInfoHelpCallout(
  FastInfoHelpAnchor.pillTrend,
  'Gyors összehasonlító irány és százalék',
);
const _title = FastInfoHelpCallout(
  FastInfoHelpAnchor.title,
  'Megmutatja, melyik FastInfo adatot látod',
);
const _primaryValue = FastInfoHelpCallout(
  FastInfoHelpAnchor.primaryValue,
  'A nagy kártyanézet fő, hangsúlyos értéke',
);
const _secondaryValues = FastInfoHelpCallout(
  FastInfoHelpAnchor.secondaryValues,
  'Kiegészítő részletek és összehasonlítások',
);

const fastInfoCardHelpById = <String, FastInfoCardHelp>{
  'mai_koltes': FastInfoCardHelp(
    purpose: 'Megmutatja, ma mennyi pénz ment el, és mennyi költhető még ma.',
    details:
        'A fő szám a valós mai költés: ebben a fix tételek is benne vannak, mert ez mutatja meg, tényleg mennyi pénz fogyott ma. A napi keret és a százalék viszont fixek nélkül számol, hogy egy lakbér vagy más időzített nagy tétel ne tegye használhatatlanná a napi tempót.',
    calculation: <String>[
      'Napi plafon = max(0, havi limit - mai nap előtti változó havi költés) / maival együtt hátralévő hónapnapok.',
      'Napi keret sáv = mai változó költés / napi plafon. Zöld 75% alatt, sárga 75-100% között, piros 100% felett.',
      'A pill jobb oldali jelölője azt mutatja, hol van a 30 napos napi átlag ehhez a mai plafonhoz képest. Ha az átlag nagyobb, mint a plafon, jobbra szaggatott túlcsordulás látszik.',
    ],
    comparison:
        'A nyíl és a százalék azt mutatja, hogy a mai változó költés mennyivel több vagy kevesebb az elmúlt 30 nap napi átlagánál.',
    missingData:
        'Havi limit nélkül nincs napi plafon, ezért a napi keret sáv és a még költhető összeg nem jelenik meg. Ha nincs 30 napos átlag, az összehasonlító százalék is eltűnik.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(FastInfoHelpAnchor.pillValue, 'Mai valós költés'),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Ennyi költhető még ma a napi plafonból',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Napi plafon sáv és napi átlag jelölője',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Ma valósan elköltve',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Mai tranzakciószám, napi plafon maradéka és átlaghoz mért eltérés',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Napi keret kihasználtsága fix/időzített tételek nélkül',
      ),
    ],
  ),
  'heti_koltes': FastInfoCardHelp(
    purpose:
        'Megmutatja, ezen a héten mennyi ment el, és a hét napjai közül melyik volt erősebb.',
    details:
        'A fő szám a valós heti költés. A keret, a heti ritmus színei és az időarányos eltérés fixek nélkül számolnak, mert a lakbérhez hasonló ismétlődő tételek elnyomnák a hétköznapi költést. A tranzakciószám azt mutatja, hány kiadási tétel volt hétfőtől máig.',
    calculation: <String>[
      'Heti keret = havi kiadási limit / 4.345. Ez egy átlagos hónap hetesítése.',
      'A 7 oszlop hétfőtől vasárnapig mutatja a napi változó költést. A jövőbeli napok halványak, a mai nap kék keretet kap.',
      'Időarányhoz képest p = heti változó költés keretaránya - a hét eltelt része. A p százalékpontot jelent.',
    ],
    comparison:
        'A box alsó százaléka az aktuális heti változó költést az előző hét azonos napjáig tartó változó költéshez hasonlítja.',
    missingData:
        'Havi limit nélkül nincs heti keret és nincs költhető összeg. Az oszlopok akkor is látszhatnak, de kerethez viszonyított színezés nélkül.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Hétfőtől máig valósan elköltve',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Időarányos eltérés százalékpontban',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Balra jobb a tempó, jobbra rosszabb a tempó',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(FastInfoHelpAnchor.primaryValue, 'Heti valós költés'),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Tranzakciószám, heti keret maradéka és előző heti eltérés',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        '7 napos heti ritmus fix/időzített tételek nélkül',
      ),
    ],
  ),
  'havi_koltes': FastInfoCardHelp(
    purpose:
        'Megmutatja, az aktuális naptári hónap eddig mennyibe került az előző hónaphoz képest.',
    details:
        'A fő szám a valós aktuális havi költés. A box line chartja három naptári hónapot hasonlít össze: előző hónap, aktuális hónap és az előző előtti hónap. Az index és a vonal fixek nélkül számol, hogy az ismétlődő időzített tételek ne torzítsák az összehasonlítást.',
    calculation: <String>[
      'Havi költés = az aktuális naptári hónap valós kiadásainak összege ma végéig.',
      'Előző hónap index = aktuális hónap változó költése azonos napig / előző hónap változó költése azonos napig.',
      'Ha az index 59%, akkor most ugyaneddig a napig az előző havi költés 59%-án állsz. 100% alatt kevesebb, 100% felett több.',
    ],
    comparison:
        'Az összehasonlítás mindig naptári hónapokat néz azonos napig. Például június 6-án a június 1-6. költést hasonlítja május 1-6. költéshez.',
    missingData:
        'Ha nincs előző havi azonos napi adat, az index helyett Nincs összehasonlítás jelenik meg. Havi limit nélkül a limithez kötött maradék nem számolható, de a havi összehasonlítás ettől még működhet.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Aktuális havi valós költés',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Előző hónap indexe azonos napig',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Index skála: zöld kevesebb, sárga közel azonos, piros több',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Aktuális havi valós kiadás',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Aktuális hó eddig és azonos napig mért százalék',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Három havi napi költésvonal azonos napig, fixek nélkül',
      ),
    ],
  ),
  'megtakaritas': FastInfoCardHelp(
    purpose:
        'Megmutatja az aktuális havi tényleges megtakarítást és a célhoz viszonyított haladást.',
    details:
        'A kártya a havi bevétel és havi kiadás különbségéből számolt megtakarítást, a beállított megtakarítási célt és a megtakarítási rátát foglalja össze.',
    calculation: <String>[
      'Aktuális megtakarítás = max(0, aktuális havi bevétel - aktuális havi kiadás).',
      'Célhaladás = aktuális megtakarítás / beállított megtakarítási cél.',
      'Megtakarítási ráta = aktuális megtakarítás / aktuális havi bevétel.',
    ],
    comparison:
        'A vizuál nem időszakokat hasonlít, hanem a beállított havi cél teljesülését mutatja.',
    missingData:
        'Cél nélkül Nincs cél látszik; havi bevétel nélkül a megtakarítási ráta kimarad.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Aktuális havi megtakarítás',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Megtakarított összeg',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Megtakarítási cél és ráta',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Haladás a beállított megtakarítási cél felé',
      ),
    ],
  ),
  'koltesi_trend': FastInfoCardHelp(
    purpose: 'Megmutatja, hogy az elmúlt 30 nap költése nőtt vagy csökkent-e.',
    details:
        'A kártya az elmúlt gördülő 30 nap kiadását, az azt megelőző 30 napot, a százalékos változást és a havi limithez képesti kerettempót mutatja. Az összehasonlítás fixek nélkül készül, hogy az ismétlődő nagy tételek ne torzítsanak.',
    calculation: <String>[
      'Aktuális időszak = maival záródó elmúlt 30 nap kiadása.',
      'Előző időszak = az azt közvetlenül megelőző 30 nap kiadása.',
      'Változás = aktuális időszak / előző időszak - 1.',
    ],
    comparison:
        'Mindig az elmúlt 60 napot figyeli: utolsó 30 nap kontra előtti 30 nap.',
    missingData:
        'Ha az előző 30 nap összege nulla, a százalékos trend nem jelenik meg.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Elmúlt 30 nap költése',
      ),
      _pillTrend,
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Legutóbbi 30 nap összege',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Előző 30 nap és kerettempó',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.trend,
        'Piros felfelé vagy zöld lefelé nyíl; nincs grafikon',
      ),
    ],
  ),
  'legutobbi_tranzakcio': FastInfoCardHelp(
    purpose: 'A legfrissebb rögzített tranzakciót mutatja gyors ellenőrzésre.',
    details:
        'A nagy kártyanézetben az összeg, a kereskedő vagy név, a kategória és az időpont jelenik meg.',
    calculation: <String>[
      'A legújabb dátumú és időpontú tranzakció kerül kiválasztásra.',
    ],
    comparison:
        'Ez a kártya nem hasonlít időszakokat, csak a legutolsó eseményt mutatja.',
    missingData:
        'Üres tranzakciós előzmény esetén Nincs tranzakció állapot jelenik meg.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Legutóbbi tranzakció összege',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.avatar,
        'A kategória színe és ikonja',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Tranzakció összege',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Kereskedő, kategória és időpont',
      ),
      _title,
    ],
  ),
  'varhato_ho_vegi_koltes': FastInfoCardHelp(
    purpose: 'Megbecsüli, mennyi lehet a teljes havi kiadás hó végére.',
    details:
        'A kártya az eddigi havi tempóból számított hó végi költést, a becsült maradékot és a havi limithez viszonyított kockázatot mutatja.',
    calculation: <String>[
      'Várható hó végi kiadás = aktuális havi kiadás / eltelt hónapnapok * hónap napjai.',
    ],
    comparison:
        'A kockázat a becsült hó végi kiadást a havi kiadási limithez méri, ha van ilyen limit.',
    missingData:
        'Limit nélkül az előrejelzés megmarad, de a kockázati jelzés semleges.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Becsült hó végi költés',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Várható havi végösszeg',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Becsült maradék és limitkockázat',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Hó végi költési előrejelzés',
      ),
    ],
  ),
  'leggyorsabban_fogyo_kategorialimit': FastInfoCardHelp(
    purpose:
        'Megmutatja, melyik kategórialimit fogy a leggyorsabban vagy van túllépve.',
    details:
        'A kártya a legmagasabb limithasználatú kategóriát, az elköltve/limit értéket, valamint a limit közelében és felett lévő kategóriák számát mutatja.',
    calculation: <String>[
      'Rangsor = aktuális havi kategóriaköltés / kategórialimit, csökkenő sorrendben.',
      'Döntetlen esetén a kategórianév rendez.',
    ],
    comparison:
        'A limithasználat az aktuális naptári hónapon belüli kategóriaköltést méri a havi kategórialimithez.',
    missingData:
        'Ha nincs beállított kategórialimit, Nincs kategórialimit állapot jelenik meg.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Legmagasabb limithasználatú kategória',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.avatar,
        'Kategória színe és ikonja',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'A leginkább fogyó limit kategóriája',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Elköltve/limit, közel és felett lévő kategóriák',
      ),
      FastInfoHelpCallout(FastInfoHelpAnchor.visual, 'Színes limithaladás'),
    ],
  ),
  'leggyakoribb_kereskedo': FastInfoCardHelp(
    purpose: 'Megmutatja, hol történik a legtöbb kiadási tranzakció.',
    details:
        'A kártya az elsődleges rangsort tranzakciószám alapján veszi, utána mutatja a teljes összeget.',
    calculation: <String>[
      'Rangsor = tranzakciószám, majd nagyobb teljes kiadás, majd kereskedőnév.',
    ],
    comparison:
        'Az összes névvel rendelkező kiadási kereskedőt hasonlítja egymáshoz.',
    missingData:
        'Ha nincs névvel rendelkező kiadási kereskedő, Nincs kereskedő állapot látszik.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Legtöbb tranzakcióval rendelkező kereskedő',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.avatar,
        'A kereskedő leggyakoribb kategóriájának avatarja',
      ),
      FastInfoHelpCallout(FastInfoHelpAnchor.primaryValue, 'Kereskedő neve'),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Tranzakciószám, majd teljes összeg',
      ),
      _title,
    ],
  ),
  'atlagos_napi_koltes': FastInfoCardHelp(
    purpose:
        'Megmutatja az elmúlt 30 nap napi költési alaptempóját és az egyenlegből fedezhető napokat.',
    details:
        'A kártya a gördülő 30 nap napi átlagát és a fejlécben használt valós egyenleg alapján számolt puffer napokat mutatja.',
    calculation: <String>[
      'Átlag = elmúlt 30 nap kiadása / 30.',
      'Puffer napok = max(0, fejléc egyenleg) / átlagos napi költés.',
    ],
    comparison:
        'A vizuál az elmúlt 30 nap napi költéssorát mutatja, nem havi összehasonlítást.',
    missingData: 'Nulla átlagos költésnél a puffer napok nem jelennek meg.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Elmúlt 30 nap napi átlaga',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(FastInfoHelpAnchor.primaryValue, 'Napi átlagköltés'),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Az egyenlegből fedezhető átlagos költési napok',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Elmúlt 30 nap napi költésvonala',
      ),
    ],
  ),
  'no_spend_napok_szama': FastInfoCardHelp(
    purpose: 'Megmutatja, hány eltelt hónapnapon nem volt kiadás.',
    details:
        'A kártya az aktuális hónap elejétől máig számolja a kiadásmentes napokat.',
    calculation: <String>[
      'Költésmentes nap = olyan eltelt hónapnap, ahol a napi kiadás összege nulla.',
      'Arány = költésmentes napok / eltelt hónapnapok.',
    ],
    comparison: 'Csak az aktuális hónap eddig eltelt napjait nézi.',
    missingData: 'Jövőbeli nap soha nem számít költésmentes napnak.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Költésmentes napok száma ebben a hónapban',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Költésmentes napok száma',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Eltelt havi napok száma',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Költésmentes napok aránya az eltelt napokból',
      ),
    ],
  ),
  'top_kategoria_ma': FastInfoCardHelp(
    purpose: 'Megmutatja a mai legnagyobb összegű kiadási kategóriát.',
    details:
        'A nagy kártyanézet a kategóriát, az összeget és a mai költésből való részesedést mutatja.',
    calculation: <String>[
      'Rangsor = mai kategóriaösszeg, majd tranzakciószám, majd kategórianév.',
    ],
    comparison: 'Csak a mai nap kiadási kategóriáit hasonlítja egymáshoz.',
    missingData: 'Ha ma nincs költés, Ma nincs költés állapot jelenik meg.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Mai legnagyobb összegű kategória',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.avatar,
        'A kategória színe és ikonja',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Top kategória neve',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Összeg és részesedés a mai költésből',
      ),
      _title,
    ],
  ),
  'top_kategoria_heten': FastInfoCardHelp(
    purpose: 'Összeveti a hét és a hónap leggyakoribb kiadási kategóriáját.',
    details:
        'A heti elsődleges kategória összeg alapján rangsorol, a részletekben a heti és havi értékek is látszanak. A rangsor fixek nélkül készül, ezért a lakbér nem nyomja el a napi kategóriákat.',
    calculation: <String>[
      'Rangsor = tranzakciószám, majd nagyobb teljes kiadás, majd kategórianév.',
    ],
    comparison:
        'A heti top kategóriát a hónap eddigi top kategóriájával mutatja együtt.',
    missingData:
        'Ha csak az egyik időszakban van adat, azt az elérhető időszakot használja.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Heti leggyakoribb kategória',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.avatar,
        'A heti top kategória avatarja',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Heti top kategória',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Heti és havi darabszámok és összegek',
      ),
      _title,
    ],
  ),
  'legnagyobb_novekedo_kategoria': FastInfoCardHelp(
    purpose:
        'Megmutatja, melyik kategória változott a legnagyobbat két gördülő 30 napos időszak között.',
    details:
        'A kártya az aktuális és az előző 30 nap kategóriaösszegét, valamint a növekedés vagy csökkenés irányát mutatja. A változást fixek nélkül számolja, hogy a rendszeres tételek ne döntsenek helyetted.',
    calculation: <String>[
      'Rangsor = új kategóriák előre, majd legnagyobb abszolút százalékos változás, majd aktuális összeg, majd név.',
    ],
    comparison:
        'Az elmúlt 30 napot az azt megelőző 30 nappal hasonlítja össze.',
    missingData:
        'Korábban hiányzó kategória Új jelölést kap, nem végtelen százalékot.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Legnagyobbat változó kategória',
      ),
      _pillTrend,
    ],
    boxCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(FastInfoHelpAnchor.avatar, 'Kategória-avatar'),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Változó kategória neve',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Elmúlt 30 nap és előző 30 nap összege',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.trend,
        'Piros növekedés vagy zöld csökkenés',
      ),
    ],
  ),
  'kovetkezo_ismetlo_kiadas': FastInfoCardHelp(
    purpose:
        'Megmutatja a következő esedékes ismétlődő kiadást és a következő 7 nap terhét.',
    details:
        'A nagy kártyanézet a következő tétel nevét, összegét, esedékességét, valamint a következő hét tételszámát és összegét mutatja.',
    calculation: <String>[
      'A következő függő ismétlődő kiadási tétel kerül előre.',
      'A 7 napos összeg a mai naptól számított következő hét függő kiadási tételeinek összege.',
    ],
    comparison: 'Ez nem múltbeli trend, hanem közelgő kötelezettséglista.',
    missingData:
        'Ha nincs függő ismétlődő kiadás, Nincs közelgő ismétlődő kiadás állapot látszik.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Következő ismétlődő kiadás összege',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.avatar,
        'Az ismétlődő tétel kategória-avatarja',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Következő tétel neve és összege',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Esedékesség és következő 7 nap tételei',
      ),
      _title,
    ],
  ),
  'havi_fix_koltseg_osszesen': FastInfoCardHelp(
    purpose: 'Összegzi az aktuális hónap várható fix kiadásait.',
    details:
        'A kártya a havi fix költségek összegét, a már levont és hátralévő részt, a legnagyobb fix tételt és a fixek után maradó keretet mutatja.',
    calculation: <String>[
      'Havi fix költség = az aktuális hónap ismétlődő kiadási tételeinek összege.',
      'Haladásjelző = havi fix költség / havi kiadási limit.',
    ],
    comparison:
        'A vizuál a fix költségek havi limithez viszonyított arányát mutatja.',
    missingData:
        'Havi limit nélkül a limitfüggő értékek rejtve maradnak; fix költség nélkül Nincs havi fix költség jelenik meg.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Aktuális havi fix költségek összege',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Fix költségek összesen',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Levont, hátralévő, legnagyobb és keret után maradó összeg',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Fix költségek aránya a havi limitből',
      ),
    ],
  ),
  'bevetel_ebben_a_honapban': FastInfoCardHelp(
    purpose: 'Megmutatja az aktuális havi bevételt és annak fedezeti erejét.',
    details:
        'A nagy kártyanézet a havi bevételt, az átlagos költéssel fedezhető napokat és az előző hónap azonos napjához mért eltérést mutatja.',
    calculation: <String>[
      'Fedezeti napok = aktuális havi bevétel / elmúlt 30 nap átlagos napi kiadása.',
    ],
    comparison:
        'Az aktuális hónap eddigi bevételét az előző hónap azonos napjáig beérkezett bevételhez hasonlítja.',
    missingData:
        'Nulla átlagos kiadásnál a fedezeti napok kimaradnak; nulla előző havi bevételnél a százalékos trend rejtve marad.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Aktuális havi bevétel',
      ),
      _pillTrend,
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Havi bevétel eddig',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Fedezeti napok és előző havi eltérés',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.trend,
        'Zöld növekedés vagy piros csökkenés',
      ),
    ],
  ),
  'kiadas_bevetel_arany': FastInfoCardHelp(
    purpose:
        'Megmutatja, az aktuális havi bevétel mekkora része ment már el kiadásra.',
    details:
        'A kártya a kiadás/bevétel arányt és a nettó havi pénzáram-t foglalja össze.',
    calculation: <String>[
      'Arány = aktuális havi kiadás / aktuális havi bevétel.',
      'Pénzáram = aktuális havi bevétel - aktuális havi kiadás.',
    ],
    comparison:
        'A haladásjelző nem múltbeli időszakot hasonlít, hanem a bevétel elköltött részét jelzi.',
    missingData:
        'Aktuális havi bevétel nélkül az arány és haladásjelző kimarad, de a pénzáram továbbra is látszik.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Elköltött havi bevétel százaléka',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Kiadás/bevétel arány',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Nettó havi pénzáram',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Zöld/sárga/piros kiadás-bevétel arány',
      ),
    ],
  ),
};
