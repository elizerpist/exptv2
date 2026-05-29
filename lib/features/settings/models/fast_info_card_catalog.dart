enum FastInfoVisualType {
  progress('progress'),
  sparkline('sparkline'),
  bar('bar'),
  ring('ring'),
  status('status'),
  trend('trend'),
  plain('plain');

  const FastInfoVisualType(this.nativeValue);
  final String nativeValue;

  static FastInfoVisualType fromAny(Object? value) {
    return FastInfoVisualType.values.firstWhere(
      (type) => type.nativeValue == value?.toString(),
      orElse: () => FastInfoVisualType.plain,
    );
  }
}

class FastInfoCardDefinition {
  const FastInfoCardDefinition({
    required this.id,
    required this.title,
    required this.pillValue,
    required this.boxValue,
    required this.boxSubtitle,
    required this.visualType,
    this.progress,
  });

  final String id;
  final String title;
  final String pillValue;
  final String boxValue;
  final String boxSubtitle;
  final FastInfoVisualType visualType;
  final double? progress;
}

const defaultFastInfoPillCardIds = <String>[
  'havi_koltes',
  'mai_maradek_keret',
  'koltesi_trend',
];

const defaultFastInfoBoxCardIds = <String>[
  'mai_koltes',
  'havi_limit_allapot',
  'kovetkezo_ismetlo_kiadas',
];

const fastInfoCardCatalog = <FastInfoCardDefinition>[
  FastInfoCardDefinition(id: 'mai_koltes', title: 'Mai költés', pillValue: '4.5k', boxValue: '4 500 Ft', boxSubtitle: '2 tranzakció ma', visualType: FastInfoVisualType.bar, progress: 0.22),
  FastInfoCardDefinition(id: 'heti_koltes', title: 'Heti költés', pillValue: '38k', boxValue: '38 200 Ft', boxSubtitle: 'A heti keret 46%-a', visualType: FastInfoVisualType.progress, progress: 0.46),
  FastInfoCardDefinition(id: 'havi_koltes', title: 'Havi költés', pillValue: '184k', boxValue: '184k / 250k', boxSubtitle: 'A havi keret 74%-a', visualType: FastInfoVisualType.progress, progress: 0.74),
  FastInfoCardDefinition(id: 'megtakaritas', title: 'Megtakarítás', pillValue: '156k', boxValue: '156 780 Ft', boxSubtitle: 'Célhoz képest stabil', visualType: FastInfoVisualType.ring, progress: 0.62),
  FastInfoCardDefinition(id: 'egyenleg', title: 'Egyenleg', pillValue: '312k', boxValue: '312 400 Ft', boxSubtitle: 'Becsült aktuális egyenleg', visualType: FastInfoVisualType.plain),
  FastInfoCardDefinition(id: 'havi_limit_allapot', title: 'Havi limit állapot', pillValue: '74%', boxValue: '184k / 250k', boxSubtitle: '66k maradt', visualType: FastInfoVisualType.progress, progress: 0.74),
  FastInfoCardDefinition(id: 'koltesi_trend', title: 'Költési trend', pillValue: '+12%', boxValue: '+12%', boxSubtitle: 'Az előző időszakhoz képest', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'legutobbi_tranzakcio', title: 'Legutóbbi tranzakció', pillValue: '-2.1k', boxValue: '-2 100 Ft', boxSubtitle: 'Kávézó, 12:42', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'mai_maradek_keret', title: 'Mai maradék keret', pillValue: '8.5k', boxValue: '8 500 Ft', boxSubtitle: 'Mai ajánlott keretből', visualType: FastInfoVisualType.progress, progress: 0.68),
  FastInfoCardDefinition(id: 'heti_maradek_keret', title: 'Heti maradék keret', pillValue: '44k', boxValue: '44 800 Ft', boxSubtitle: 'Heti keret maradéka', visualType: FastInfoVisualType.progress, progress: 0.54),
  FastInfoCardDefinition(id: 'honapbol_hatralevo_napok', title: 'Hónapból hátralévő napok', pillValue: '9 nap', boxValue: '9 nap', boxSubtitle: 'A hónap végéig', visualType: FastInfoVisualType.ring, progress: 0.30),
  FastInfoCardDefinition(id: 'napi_ajanlott_maximum', title: 'Napi ajánlott maximum', pillValue: '7.3k', boxValue: '7 300 Ft', boxSubtitle: 'Becsült napi plafon', visualType: FastInfoVisualType.plain),
  FastInfoCardDefinition(id: 'mai_koltes_ajanlotthoz', title: 'Mai költés az ajánlott maxhoz képest', pillValue: '62%', boxValue: '4.5k / 7.3k', boxSubtitle: 'Mai ajánlott keret', visualType: FastInfoVisualType.progress, progress: 0.62),
  FastInfoCardDefinition(id: 'havi_keret_egesi_sebesseg', title: 'Havi keret égési sebesség', pillValue: 'gyors', boxValue: 'Gyors tempó', boxSubtitle: 'A keret a vártnál gyorsabban fogy', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'varhato_ho_vegi_koltes', title: 'Várható hó végi költés', pillValue: '271k', boxValue: '271 000 Ft', boxSubtitle: 'Becsült hó végi összeg', visualType: FastInfoVisualType.sparkline),
  FastInfoCardDefinition(id: 'tulkoltes_kockazat', title: 'Túlköltés kockázat', pillValue: 'közepes', boxValue: 'Közepes', boxSubtitle: 'Figyeld a napi tempót', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'leggyorsabban_fogyo_kategorialimit', title: 'Leggyorsabban fogyó kategórialimit', pillValue: 'Étel', boxValue: 'Étel 88%', boxSubtitle: 'A limit közelében', visualType: FastInfoVisualType.progress, progress: 0.88),
  FastInfoCardDefinition(id: 'limit_feletti_kategoriak_szama', title: 'Limit feletti kategóriák száma', pillValue: '1 db', boxValue: '1 kategória', boxSubtitle: 'Limit felett', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'utolso_auto_tranzakcio', title: 'Utolsó automatikusan rögzített tranzakció', pillValue: '-990', boxValue: '-990 Ft', boxSubtitle: 'Automatikus rögzítés', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'utolso_kezi_tranzakcio', title: 'Utolsó kézzel rögzített tranzakció', pillValue: '-3.2k', boxValue: '-3 200 Ft', boxSubtitle: 'Kézi rögzítés', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'ma_rogzitett_tranzakciok_szama', title: 'Ma rögzített tranzakciók száma', pillValue: '5 db', boxValue: '5 tranzakció', boxSubtitle: 'Mai aktivitás', visualType: FastInfoVisualType.bar, progress: 0.50),
  FastInfoCardDefinition(id: 'fuggoben_levo_feldolgozas', title: 'Függőben lévő feldolgozás', pillValue: '0', boxValue: '0 függőben', boxSubtitle: 'Nincs várakozó elem', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'legutobbi_push_forrasapp', title: 'Legutóbbi push forrásapp', pillValue: 'Bank', boxValue: 'Bank app', boxSubtitle: 'Utolsó értesítés forrása', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'sikertelen_parse_ok', title: 'Sikertelen parse-ok', pillValue: '2', boxValue: '2 sikertelen', boxSubtitle: 'Ellenőrzést igényel', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'ismeretlen_kereskedok_szama', title: 'Ismeretlen kereskedők száma', pillValue: '3', boxValue: '3 új név', boxSubtitle: 'Kategorizálásra vár', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'uj_kereskedo_ma', title: 'Új kereskedő ma', pillValue: '1', boxValue: '1 új kereskedő', boxSubtitle: 'Ma először láttuk', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'leggyakoribb_kereskedo', title: 'Leggyakoribb kereskedő', pillValue: 'ABC', boxValue: 'ABC Market', boxSubtitle: 'Legtöbb tranzakció', visualType: FastInfoVisualType.bar, progress: 0.70),
  FastInfoCardDefinition(id: 'legdragabb_kereskedo_honapban', title: 'Legdrágább kereskedő ebben a hónapban', pillValue: 'Bérlet', boxValue: 'Bérlet', boxSubtitle: 'Legnagyobb havi összeg', visualType: FastInfoVisualType.bar, progress: 0.82),
  FastInfoCardDefinition(id: 'atlagos_napi_koltes', title: 'Átlagos napi költés', pillValue: '8.1k', boxValue: '8 100 Ft', boxSubtitle: 'Napi átlag', visualType: FastInfoVisualType.sparkline),
  FastInfoCardDefinition(id: 'hetvegi_vs_hetkoznapi_koltes', title: 'Hétvégi vs hétköznapi költés', pillValue: '34/66', boxValue: '34% / 66%', boxSubtitle: 'Hétvége és hétköznap', visualType: FastInfoVisualType.bar),
  FastInfoCardDefinition(id: 'mai_nap_atlaghoz_kepest', title: 'Mai nap az átlaghoz képest', pillValue: '-18%', boxValue: '-18%', boxSubtitle: 'Ma az átlag alatt', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'ez_a_het_elozo_hethez', title: 'Ez a hét az előző héthez képest', pillValue: '+6%', boxValue: '+6%', boxSubtitle: 'Heti összevetés', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'ez_a_honap_elozo_honaphoz', title: 'Ez a hónap az előző hónaphoz képest', pillValue: '-4%', boxValue: '-4%', boxSubtitle: 'Havi összevetés', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'kiadasi_tempo', title: 'Kiadási tempó', pillValue: 'normál', boxValue: 'Normál tempó', boxSubtitle: 'A kerethez igazodik', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'havi_anomalia', title: 'Havi anomália', pillValue: 'nincs', boxValue: 'Nincs anomália', boxSubtitle: 'Szokásos mintázat', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'szokatlan_nagy_tetel', title: 'Szokatlan nagy tétel', pillValue: '1', boxValue: '1 nagy tétel', boxSubtitle: 'Ellenőrizhető tranzakció', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'sporolasi_sorozat', title: 'Spórolási sorozat', pillValue: '4 nap', boxValue: '4 nap', boxSubtitle: 'Átlag alatti költés', visualType: FastInfoVisualType.ring, progress: 0.57),
  FastInfoCardDefinition(id: 'no_spend_napok_szama', title: 'No-spend napok száma', pillValue: '3 nap', boxValue: '3 nap', boxSubtitle: 'Költés nélküli napok', visualType: FastInfoVisualType.ring, progress: 0.43),
  FastInfoCardDefinition(id: 'top_kategoria_ma', title: 'Top kategória ma', pillValue: 'Étel', boxValue: 'Étel', boxSubtitle: 'Mai legnagyobb kategória', visualType: FastInfoVisualType.bar, progress: 0.61),
  FastInfoCardDefinition(id: 'top_kategoria_heten', title: 'Top kategória héten', pillValue: 'Bolt', boxValue: 'Bolt', boxSubtitle: 'Heti legnagyobb kategória', visualType: FastInfoVisualType.bar, progress: 0.55),
  FastInfoCardDefinition(id: 'top_kategoria_honapban', title: 'Top kategória hónapban', pillValue: 'Lakhatás', boxValue: 'Lakhatás', boxSubtitle: 'Havi legnagyobb kategória', visualType: FastInfoVisualType.bar, progress: 0.80),
  FastInfoCardDefinition(id: 'legnagyobb_novekedo_kategoria', title: 'Legnagyobb növekedő kategória', pillValue: 'Utazás', boxValue: 'Utazás +22%', boxSubtitle: 'Legnagyobb növekedés', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'legjobban_csokkeno_kategoria', title: 'Legjobban csökkenő kategória', pillValue: 'Kávé', boxValue: 'Kávé -15%', boxSubtitle: 'Legnagyobb csökkenés', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'kategoria_limit_kozeleben', title: 'Kategória limit közelében', pillValue: '2 db', boxValue: '2 kategória', boxSubtitle: 'Limit közelében', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'kategoria_limit_tullepve', title: 'Kategória limit túllépve', pillValue: '1 db', boxValue: '1 kategória', boxSubtitle: 'Limit felett', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'ures_vagy_kategorizalatlan_tranzakciok', title: 'Üres vagy kategorizálatlan tranzakciók', pillValue: '4 db', boxValue: '4 tranzakció', boxSubtitle: 'Kategóriára vár', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'kedvenc_kategoria_shortcut', title: 'Kedvenc kategória shortcut', pillValue: 'Étel', boxValue: 'Étel', boxSubtitle: 'Gyakran használt kategória', visualType: FastInfoVisualType.plain),
  FastInfoCardDefinition(id: 'kategoria_amire_ma_meg_nem_koltottel', title: 'Kategória, amire ma még nem költöttél', pillValue: 'Hobbi', boxValue: 'Hobbi', boxSubtitle: 'Ma még nincs költés', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'kovetkezo_ismetlo_kiadas', title: 'Következő ismétlődő kiadás', pillValue: 'Lakbér', boxValue: 'Lakbér', boxSubtitle: '3 nap múlva', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'kovetkezo_7_nap_fix_kiadasai', title: 'Következő 7 nap fix kiadásai', pillValue: '42k', boxValue: '42 000 Ft', boxSubtitle: '7 napon belül', visualType: FastInfoVisualType.bar, progress: 0.42),
  FastInfoCardDefinition(id: 'mai_esedekes_fix_kiadas', title: 'Mai esedékes fix kiadás', pillValue: '0', boxValue: 'Nincs ma', boxSubtitle: 'Ma nincs esedékes fix tétel', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'havi_fix_koltseg_osszesen', title: 'Havi fix költség összesen', pillValue: '121k', boxValue: '121 000 Ft', boxSubtitle: 'Fix havi tételek', visualType: FastInfoVisualType.ring, progress: 0.48),
  FastInfoCardDefinition(id: 'fix_koltseg_aranya_havi_keretbol', title: 'Fix költség aránya a havi keretből', pillValue: '48%', boxValue: '48%', boxSubtitle: 'Havi keretből', visualType: FastInfoVisualType.progress, progress: 0.48),
  FastInfoCardDefinition(id: 'mar_levont_fix_kiadasok', title: 'Már levont fix kiadások', pillValue: '79k', boxValue: '79 000 Ft', boxSubtitle: 'Már teljesült fix tételek', visualType: FastInfoVisualType.progress, progress: 0.65),
  FastInfoCardDefinition(id: 'meg_varhato_fix_kiadasok', title: 'Még várható fix kiadások', pillValue: '42k', boxValue: '42 000 Ft', boxSubtitle: 'Hátralévő fix tételek', visualType: FastInfoVisualType.progress, progress: 0.35),
  FastInfoCardDefinition(id: 'elmaradt_ismetlo_feldolgozas', title: 'Elmaradt ismétlődő feldolgozás', pillValue: '0', boxValue: 'Nincs elmaradás', boxSubtitle: 'Minden naprakész', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'legnagyobb_fix_kiadas', title: 'Legnagyobb fix kiadás', pillValue: 'Lakbér', boxValue: 'Lakbér', boxSubtitle: 'Legnagyobb fix tétel', visualType: FastInfoVisualType.bar, progress: 0.78),
  FastInfoCardDefinition(id: 'fix_koltsegek_utan_marado_keret', title: 'Fix költségek után maradó keret', pillValue: '129k', boxValue: '129 000 Ft', boxSubtitle: 'Fix tételek után', visualType: FastInfoVisualType.progress, progress: 0.52),
  FastInfoCardDefinition(id: 'biztonsagi_tartalek', title: 'Biztonsági tartalék', pillValue: '92k', boxValue: '92 000 Ft', boxSubtitle: 'Becsült puffer', visualType: FastInfoVisualType.ring, progress: 0.61),
  FastInfoCardDefinition(id: 'minimum_egyenleg_figyelmeztetes', title: 'Minimum egyenleg figyelmeztetés', pillValue: 'OK', boxValue: 'OK', boxSubtitle: 'Minimum felett', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'keszpenz_vs_kartyas_arany', title: 'Készpénz vs kártyás arány', pillValue: '12/88', boxValue: '12% / 88%', boxSubtitle: 'Készpénz és kártya', visualType: FastInfoVisualType.bar),
  FastInfoCardDefinition(id: 'bevetel_ebben_a_honapban', title: 'Bevétel ebben a hónapban', pillValue: '420k', boxValue: '420 000 Ft', boxSubtitle: 'Havi bevétel', visualType: FastInfoVisualType.bar, progress: 0.84),
  FastInfoCardDefinition(id: 'kiadas_bevetel_arany', title: 'Kiadás/bevétel arány', pillValue: '44%', boxValue: '44%', boxSubtitle: 'Kiadás a bevételhez képest', visualType: FastInfoVisualType.progress, progress: 0.44),
  FastInfoCardDefinition(id: 'netto_havi_cashflow', title: 'Nettó havi cashflow', pillValue: '+236k', boxValue: '+236 000 Ft', boxSubtitle: 'Bevétel mínusz kiadás', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'ho_vegi_becsult_maradek', title: 'Hó végi becsült maradék', pillValue: '149k', boxValue: '149 000 Ft', boxSubtitle: 'Becsült maradék', visualType: FastInfoVisualType.sparkline),
  FastInfoCardDefinition(id: 'megtakaritasi_cel_haladas', title: 'Megtakarítási cél haladás', pillValue: '62%', boxValue: '62%', boxSubtitle: 'Cél teljesülése', visualType: FastInfoVisualType.ring, progress: 0.62),
  FastInfoCardDefinition(id: 'havi_megtakaritasi_rata', title: 'Havi megtakarítási ráta', pillValue: '21%', boxValue: '21%', boxSubtitle: 'Bevételhez képest', visualType: FastInfoVisualType.progress, progress: 0.21),
  FastInfoCardDefinition(id: 'puffer_napok_szama', title: 'Puffer napok száma', pillValue: '11 nap', boxValue: '11 nap', boxSubtitle: 'Tartalék becslés', visualType: FastInfoVisualType.ring, progress: 0.37),
  FastInfoCardDefinition(id: 'figyelt_app_allapota', title: 'Figyelt app állapota', pillValue: 'aktív', boxValue: 'Aktív', boxSubtitle: 'App figyelés bekapcsolva', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'notification_listener_allapota', title: 'Notification listener állapota', pillValue: 'OK', boxValue: 'OK', boxSubtitle: 'Értesítésfigyelő aktív', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'utolso_sikeres_szinkron', title: 'Utolsó sikeres szinkron', pillValue: '12:40', boxValue: '12:40', boxSubtitle: 'Legutóbbi sikeres frissítés', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'utolso_backup', title: 'Utolsó backup', pillValue: 'tegnap', boxValue: 'Tegnap', boxSubtitle: 'Biztonsági mentés', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'adatbazis_sorok_szama', title: 'Adatbázis sorok száma', pillValue: '1.2k', boxValue: '1 240 sor', boxSubtitle: 'Lokális adatbázis', visualType: FastInfoVisualType.bar, progress: 0.40),
  FastInfoCardDefinition(id: 'hianyos_tranzakciok', title: 'Hiányos tranzakciók', pillValue: '3', boxValue: '3 hiányos', boxSubtitle: 'Ellenőrzést igényel', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'duplikatumgyanus_tetelek', title: 'Duplikátumgyanús tételek', pillValue: '2', boxValue: '2 gyanús', boxSubtitle: 'Lehetséges duplikátumok', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'parse_pontossag', title: 'Parse pontosság', pillValue: '96%', boxValue: '96%', boxSubtitle: 'Becsült feldolgozási arány', visualType: FastInfoVisualType.progress, progress: 0.96),
  FastInfoCardDefinition(id: 'import_export_statusz', title: 'Import/export státusz', pillValue: 'OK', boxValue: 'OK', boxSubtitle: 'Nincs folyamatban lévő művelet', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'debug_riasztasok', title: 'Debug riasztások', pillValue: '0', boxValue: '0 riasztás', boxSubtitle: 'Nincs aktív debug jelzés', visualType: FastInfoVisualType.status),
];

FastInfoCardDefinition? fastInfoCardById(String id) {
  for (final card in fastInfoCardCatalog) {
    if (card.id == id) return card;
  }
  return null;
}
