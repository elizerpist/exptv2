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
        'Megmutatja, mennyi pénz maradt meg ebben a hónapban a bevételedből.',
    details:
        'A nagy szám az eddigi havi bevétel mínusz az eddigi havi kiadás. A kör azt mutatja, hogy ez a beállított megtakarítási cél hány százaléka. A pill jobb oldalán a zöld csík a mostani állás, a kék vonal pedig azt mutatja, várhatóan hol állsz majd hó végén.',
    calculation: <String>[
      'Mostani megtakarítás = max(0, aktuális havi bevétel - aktuális havi kiadás).',
      'Mostani célhaladás = mostani megtakarítás / beállított havi megtakarítási cél.',
      'Várható hó végi célhaladás = max(0, várható havi bevétel - várható havi kiadás) / cél.',
      'A várható havi bevételbe a még be nem érkezett ismétlődő bevételek is beleszámítanak.',
    ],
    comparison:
        'Nem két hónapot hasonlít. Azt mutatja, hogy a saját havi célodhoz képest hol tartasz most, és hova érhetsz hó végére.',
    missingData:
        'Ha nincs megtakarítási cél, a kártya csak az eddigi megmaradt pénzt írja ki, célhaladás nélkül.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Mostani havi megtakarítás',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Zöld: mostani célállás; kék vonal: várható hó végi állás',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Eddig megmaradt pénz ebben a hónapban',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Cél, célhaladás és havi állás',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'A kör a megtakarítási cél teljesülését mutatja',
      ),
    ],
  ),
  'koltesi_trend': FastInfoCardHelp(
    purpose:
        'Megmutatja, az elmúlt 30 nap változó költése több vagy kevesebb volt-e, mint az előtte lévő 30 nap.',
    details:
        'Ez egy gördülő nézet: mindig ma visszanéz 30 napot, és mellé teszi az azt megelőző 30 napot. A fix, ismétlődő tételeket kihagyja, mert egy lakbér vagy más időzített nagy tétel duplán vagy rossz napra esve félrevezetné a trendet.',
    calculation: <String>[
      'Aktuális oldal = elmúlt 30 nap változó kiadása, fixek nélkül.',
      'Előző oldal = az azt megelőző 30 nap változó kiadása, fixek nélkül.',
      'Változás = aktuális oldal / előző oldal - 1. Ha nőtt a költés, piros felfelé nyíl; ha csökkent, zöld lefelé nyíl jelenik meg.',
    ],
    comparison:
        'A box megosztott sávja két részt mutat: bal oldalt az előző 30 nap, jobb oldalt az elmúlt 30 nap. A pill jobb oldalán zöld-sárga-piros sáv van: a tű mutatja, hogy az aktuális 30 nap mennyire tér el az előzőtől.',
    missingData:
        'Ha az előző 30 napban nem volt összehasonlítható változó kiadás, a százalékos változás nem jelenik meg.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Elmúlt 30 nap változó költése',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Százalékos eltérés az előző 30 naphoz képest',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Zöld-sárga-piros sáv tűvel: balra jobb, középen közel azonos, jobbra rosszabb',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Elmúlt 30 nap összege fixek nélkül',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Előző 30 nap összege és a fixek nélküli jelölés',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Megfelezett sáv: előző 30 nap és elmúlt 30 nap aránya',
      ),
    ],
  ),
  'legutobbi_tranzakcio': FastInfoCardHelp(
    purpose: 'Megmutatja a legutoljára rögzített tranzakciót.',
    details:
        'A nagy szám a tranzakció összege. A színes kör a kategória színe és ikonja. Alatta a bolt vagy név, majd a kategórianév látszik. A pillben ugyanez röviden: összeg, bolt és kategória.',
    calculation: <String>[
      'Az app dátum, idő és azonosító alapján kiválasztja a legfrissebb tranzakciót.',
      'A kategóriaikon és szín a tranzakció kategóriájából jön.',
      'Ha a tranzakció ismétlődő ghostból aktiválódott, a rekord megkapja az ismétlődő tranzakció azonosítóját is.',
    ],
    comparison:
        'Ez nem összehasonlító kártya. Egyetlen dolgot mutat: mi volt a legutolsó pénzmozgás.',
    missingData:
        'Ha még nincs tranzakció, Nincs tranzakció állapot jelenik meg.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Legutóbbi tranzakció összege',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.avatar,
        'Kategória színe és ikonja',
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
        'Bolt vagy név, kategória és időpont',
      ),
      _title,
    ],
  ),
  'varhato_ho_vegi_koltes': FastInfoCardHelp(
    purpose: 'Megbecsüli, mennyi lehet a teljes havi kiadás hó végére.',
    details:
        'A fő szám egy becsült hó végi végösszeg. A becslés a változó költés tempójából indul ki, és hozzáadja a havi fix költségeket. Így a lakbér nem úgy számít, mintha minden nap újra elköltenéd, de a havi végösszegből sem tűnik el.',
    calculation: <String>[
      'Változó havi becslés = eddigi változó költés / eltelt hónapnapok * hónap napjai.',
      'Várható hó végi kiadás = változó havi becslés + havi fix költségek.',
      'A 7 pontos vonal minden pontja azt mutatja, az adott napon mennyi lett volna a hó végi becslés. Az utolsó, kék pont a mai nap.',
      'A becslési sáv egy óvatos alsó és felső tartományt mutat: optimistább oldal, várható közép, pesszimistább oldal.',
    ],
    comparison:
        'Ha van havi kiadási keret, a pill jobb oldali sávja azt mutatja, a becsült hó végi kiadás a keret hány százaléka.',
    missingData:
        'Havi limit nélkül a becslés továbbra is látszik, de a kerethez mért százalék és kockázati színezés semlegesebb lehet.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Becsült hó végi költés',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'A havi keret várható kihasználtsága',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Kerethez mért progress: meddig érhet a hó végi költés',
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
        'Fix-korrigált jelölés, 7 napos trend és becslési sáv',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Elmúlt 7 nap becslési trendje, kék ponttal a mai napon',
      ),
    ],
  ),
  'leggyorsabban_fogyo_kategorialimit': FastInfoCardHelp(
    purpose:
        'Megmutatja, melyik kategórialimit a legszűkebb, vagyis melyikre kell leginkább figyelni.',
    details:
        'A boxban a kategória neve, ikonja, elköltött/limit értéke és a még maradt összeg látszik. A pill nem a mostani százalékot hangsúlyozza, hanem azt, hogy a jelenlegi tempó alapján várhatóan hány százalékon állna hó végén.',
    calculation: <String>[
      'Mostani limitállás = kategória változó havi költése / kategória havi limitje, fixek nélkül.',
      'Várható hó végi limitállás = mostani limitállás / hónap eltelt része.',
      'A fix vagy ismétlődő tételek itt kimaradnak, mert nem jó, ha egy időzített nagy tétel elfedi, melyik hétköznapi kategória fogy gyorsan.',
      'Döntetlen esetén a nagyobb arány, majd a kategórianév dönt.',
    ],
    comparison:
        'A box progress sávja a mostani állást mutatja. A pill jobb oldali sávja a hó végi várható túlfutást jelzi: 100% után szaggatott túlcsordulás jelenik meg.',
    missingData:
        'Ha nincs beállított kategórialimit, Nincs kategórialimit állapot jelenik meg.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Várható hó végi limithasználat',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Melyik kategória állhat veszélyben hó végére',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        '100% sáv és szaggatott túlfutás, ha a becslés túlmegy a limiten',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.avatar,
        'Kategória színe és ikonja',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'A legszűkebb limit kategóriája',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Elköltve/limit és még maradt összeg',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Mostani limitállás progress sávon',
      ),
    ],
  ),
  'leggyakoribb_kereskedo': FastInfoCardHelp(
    purpose:
        'Megmutatja, melyik kereskedőnél volt a legtöbb kiadási tranzakció.',
    details:
        'Ez nem azt keresi, hol ment el a legtöbb pénz, hanem azt, hol vásároltál a legtöbbször. Ez azért fontos, mert összeg alapján gyakran mindig a lakbér vagy egy nagy számla lenne az első.',
    calculation: <String>[
      'Rangsor = tranzakciószám, majd nagyobb teljes kiadás, majd frissebb tranzakció, végül kereskedőnév.',
      'A kategória avatar a kereskedőhöz leggyakrabban tartozó kategória színe és ikonja.',
      'A pill 14 napos aktivitási csíkot mutat: ahol volt tranzakció ennél a kereskedőnél, ott színes jel jelenik meg.',
    ],
    comparison:
        'Az összes névvel rendelkező változó kiadási kereskedőt hasonlítja egymáshoz. A fix/időzített tételek nem számítanak bele.',
    missingData:
        'Ha nincs névvel rendelkező kiadási kereskedő, Nincs kereskedő állapot látszik.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Kereskedő neve és tranzakciószáma',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Hány aktív napon volt nála költés',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        '14 napos aktivitási csík',
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
        'Tranzakciószám, kategórianév és teljes összeg',
      ),
      _title,
    ],
  ),
  'atlagos_napi_koltes': FastInfoCardHelp(
    purpose:
        'Megmutatja, mennyi a napi átlagos változó költésed az elmúlt 30 nap alapján.',
    details:
        'A boxban a nagy szám a napi átlag, alatta látszik, hogy ez az elmúlt 30 nap átlaga. A kis vonal a napi költési ritmust rajzolja. A pillben ugyanaz a napi átlag a főérték, a jobb oldali mini vonalon piros pontok jelzik a kiugró napokat, amelyek felhúzzák az átlagot.',
    calculation: <String>[
      'Átlag = elmúlt 30 nap változó kiadása / 30.',
      'A fix/időzített tételek kimaradnak, hogy például a lakbér ne húzza fel a mindennapi tempót.',
      'Elég még = aktuális egyenleg / napi átlag.',
      'Kiugró nap = olyan nap, amely jóval magasabb az átlagos napnál.',
    ],
    comparison:
        'Nem hónapot hasonlít hónaphoz, hanem az elmúlt 30 nap napi ritmusát mutatja egy kis vonalon.',
    missingData:
        'Ha nincs változó költés az elmúlt 30 napban, az átlag 0 Ft, és az elég még sor nem jelenik meg.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Elmúlt 30 nap változó napi átlaga',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Hány kiugró nap húzza fel az átlagot',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Mini költési vonal piros kiugró pontokkal',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(FastInfoHelpAnchor.primaryValue, 'Napi átlagköltés'),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Elmúlt 30 nap átlaga és fixek nélküli jelölés',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Elmúlt 30 nap napi költésvonala',
      ),
    ],
  ),
  'no_spend_napok_szama': FastInfoCardHelp(
    purpose:
        'Megmutatja, mely napokon nem volt változó költésed, vagyis hány költésmentes napod volt.',
    details:
        'A box a hónap eddigi költésmentes napjait mutatja. A havi csíkban a zöld nap költésmentes, a piros nap költős, a mai nap kék keretet kap. A pill külön az elmúlt 7 napot mutatja, hogy gyorsan lásd a legfrissebb ritmust.',
    calculation: <String>[
      'Költésmentes nap = olyan nap, ahol nincs változó kiadás.',
      'Fix/időzített tétel nem rontja el a napot, mert az nem mindennapi döntés.',
      'Box arány = havi költésmentes napok / eddig eltelt hónapnapok.',
      'Pill érték = költésmentes napok száma az elmúlt 7 napból.',
    ],
    comparison:
        'A box a hónapot mutatja, a pill az elmúlt 7 napot. A jövőbeli napok halványak.',
    missingData:
        'Jövőbeli nap nem számít költésmentes napnak. Ha még nincs adat, a csík semleges marad.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Költésmentes napok az elmúlt 7 napból',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'A pill heti időtávja',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        '7 napos csík: zöld a költésmentes nap',
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
        'Aktuális havi időtáv',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Havi napcsík: zöld szabad nap, piros költős nap, kék keret ma',
      ),
    ],
  ),
  'top_kategoria_heten': FastInfoCardHelp(
    purpose:
        'Megmutatja a mai, heti és havi top költési kategóriát egy kártyán.',
    details:
        'A box főértéke a mai top kategória. Alatta a mai összeg látszik, a kis lista pedig Ma / Hét / Hó sorokban mutatja a három időtáv nyertesét szín+ikon avatarral. A pill ugyanezt tömöríti: fő sorban a mai top, alatta a heti és havi összeg, jobb oldalt három avatar.',
    calculation: <String>[
      'Minden időtávnál az a kategória nyer, amelyikben a legtöbb változó pénz ment el.',
      'Fixek nélkül számol: a fix/időzített tételek kimaradnak, ezért a lakbér nem lesz automatikusan top kategória.',
      'Holtversenynél a több tranzakció, majd a kategórianév dönt.',
    ],
    comparison:
        'A három időtávot hasonlítja egymás mellé: ma, ezen a héten, ebben a hónapban.',
    missingData:
        'Ha valamelyik időtávban nincs költés, az a sor kimarad, és a kártya az elérhető időtávot mutatja.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Mai top kategória és összege',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Heti és havi top összeg',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Ma / hét / hó top kategória avatarjai',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Mai top kategória, ha van mai költés',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Mai összeg és fixek nélküli jelölés',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Ma / hét / hó lista szín+ikon avatarral',
      ),
      _title,
    ],
  ),
  'legnagyobb_novekedo_kategoria': FastInfoCardHelp(
    purpose:
        'Megmutatja, melyik kategória változott a legtöbb forinttal az előző 30 naphoz képest.',
    details:
        'A box főértéke a kategória neve, iránya és forintváltozása. A mini vonal azt mutatja, hogy az előző 30 naphoz képest merre mozdult. A pillben a jobb oldali mérő középről indul: jobbra piros növekedés, balra zöld csökkenés.',
    calculation: <String>[
      'Kiszámolja minden kategóriára: elmúlt 30 nap összege - előző 30 nap összege.',
      'A legnagyobb abszolút forintváltozású kategória kerül a kártyára.',
      'A százalék csak magyarázó érték; a győztest a forintváltozás választja ki.',
      'Fixek nélkül számol: a fix/időzített tételek kimaradnak.',
    ],
    comparison:
        'Az elmúlt 30 napot az azt megelőző 30 nappal hasonlítja össze.',
    missingData:
        'Korábban hiányzó kategória Új jelölést kap, nem végtelen százalékot.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Kategória és forintváltozás',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Százalékos változás és fixek nélküli jelölés',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Középvonalas eltérésmérő: balra csökkenés, jobbra növekedés',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Kategória neve, irány és forintváltozás',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Százalékos változás és fixek nélküli jelölés',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Mini vonal az előző és az aktuális 30 nap közti mozgásra',
      ),
    ],
  ),
  'kovetkezo_ismetlo_kiadas': FastInfoCardHelp(
    purpose: 'Megmutatja, melyik fix/időzített kiadás jön legközelebb.',
    details:
        'A boxban a következő fix tétel neve a főérték, alatta az összeg és hogy hány nap múlva jön. Az avatar a kategóriát jelzi. A 7 napos mini timeline megmutatja, mely napokon jön fix terhelés. A pill ugyanezt tömöríti: név + összeg, alatta visszaszámlálás, jobbra heti terhelés.',
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
        'Következő fix neve és rövid összege',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Visszaszámlálás napokban',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Következő 7 nap fix terhelése oszlopokkal',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.avatar,
        'Az ismétlődő tétel kategória-avatarja',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Következő tétel neve',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Összeg, esedékesség és következő 7 nap tételei',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        '7 napos timeline, kiemelve a következő fix napját',
      ),
      _title,
    ],
  ),
  'havi_fix_koltseg_osszesen': FastInfoCardHelp(
    purpose:
        'Megmutatja, mennyi fix/időzített kiadás van ebben a hónapban, és mennyi van még hátra.',
    details:
        'A box főértéke a havi fixek teljes összege. A split sáv bal oldala a már levont fixeket, jobb oldala a hátralévő fixeket mutatja. A pill főértéke direkt a hátralévő összeg, mert ez a legfontosabb gyors döntési adat.',
    calculation: <String>[
      'Havi fix költség = az aktuális hónap ismétlődő kiadási tételeinek összege.',
      'Haladásjelző = havi fix költség / havi kiadási limit.',
    ],
    comparison:
        'A vizuál a már levont és a még hátralévő havi fixeket teszi egymás mellé.',
    missingData:
        'Havi limit nélkül a limitfüggő értékek rejtve maradnak; fix költség nélkül Nincs havi fix költség jelenik meg.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Hátralévő havi fix összeg',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Teljes havi fix összeg',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Levont / hátralévő split sáv',
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
        'Levont, hátralévő és legnagyobb fix tétel',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Levont / hátralévő split sáv',
      ),
    ],
  ),
  'bevetel_ebben_a_honapban': FastInfoCardHelp(
    purpose:
        'Megmutatja, mennyi bevétel érkezett be ebben a hónapban, és mennyi várható még ghost bevételből.',
    details:
        'A box nagy száma csak a ténylegesen beérkezett bevétel. A várt érték külön jelenik meg, mert abban a még nem aktivált ghost bevételek is benne vannak. A három oszlop: előző hónap azonos napjáig, most beérkezett, és várt hó végi bevétel. A pill főértéke az előző hónaphoz mért eltérés.',
    calculation: <String>[
      'Beérkezett bevétel = ebben a hónapban ténylegesen rögzített bevétel.',
      'Várt bevétel = beérkezett bevétel + még függő ghost bevételek.',
      'Fedezeti napok = beérkezett bevétel / elmúlt 30 nap változó napi átlaga.',
    ],
    comparison:
        'Az aktuális hónap eddigi bevételét az előző hónap azonos napjáig beérkezett bevételhez hasonlítja.',
    missingData:
        'Nulla átlagos kiadásnál a fedezeti napok kimaradnak; nulla előző havi bevételnél a százalékos trend rejtve marad.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Előző hónap azonos napjához mért bevételi trend',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Ténylegesen beérkezett bevétel',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Előző / most összehasonlító oszlopok',
      ),
    ],
    boxCallouts: <FastInfoHelpCallout>[
      _title,
      FastInfoHelpCallout(
        FastInfoHelpAnchor.primaryValue,
        'Havi bevétel eddig',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Beérkezett, várt ghost bevétel és fedezeti napok',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Három oszlop: előző, most, várt bevétel',
      ),
    ],
  ),
  'kiadas_bevetel_arany': FastInfoCardHelp(
    purpose:
        'Megmutatja, a ténylegesen beérkezett havi bevételből mennyi ment már el.',
    details:
        'Itt nem költési tempót nézünk, hanem valódi pénzügyi arányt. Ezért a fix/időzített kiadások is beleszámítanak. A box főértéke az elköltött százalék, a pill főértéke az, hogy hány százalék maradt. A split sáv bal zöld része a megmaradt bevétel, jobb szürke része az elköltött rész.',
    calculation: <String>[
      'Elköltött arány = aktuális havi valós kiadás / aktuális havi beérkezett bevétel.',
      'Maradék arány = 1 - elköltött arány.',
      'Valós kiadásba a fix/időzített kiadások is beleszámítanak.',
    ],
    comparison:
        'A haladásjelző nem múltbeli időszakot hasonlít, hanem a bevétel elköltött részét jelzi.',
    missingData:
        'Aktuális havi bevétel nélkül az arány és haladásjelző kimarad, de a pénzáram továbbra is látszik.',
    pillCallouts: <FastInfoHelpCallout>[
      FastInfoHelpCallout(
        FastInfoHelpAnchor.pillValue,
        'Megmaradt havi bevétel százaléka',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.secondaryValues,
        'Megmaradt forint a beérkezett bevételből',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Bal zöld maradék, jobb szürke elköltött rész',
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
        'Valós havi kiadás / beérkezett bevétel',
      ),
      FastInfoHelpCallout(
        FastInfoHelpAnchor.visual,
        'Elköltött arány zöld/sárga/piros sávon',
      ),
    ],
  ),
};
