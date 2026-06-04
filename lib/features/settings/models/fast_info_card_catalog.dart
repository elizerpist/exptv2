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
  const FastInfoCardDefinition({required this.id, required this.title});

  final String id;
  final String title;
}

const defaultFastInfoPillCardIds = <String>[
  'havi_koltes',
  'koltesi_trend',
  'kiadas_bevetel_arany',
];

const defaultFastInfoBoxCardIds = <String>[
  'mai_koltes',
  'heti_koltes',
  'kovetkezo_ismetlo_kiadas',
];

const fastInfoCardCatalog = <FastInfoCardDefinition>[
  FastInfoCardDefinition(id: 'mai_koltes', title: 'Mai költés'),
  FastInfoCardDefinition(id: 'heti_koltes', title: 'Heti költés'),
  FastInfoCardDefinition(id: 'havi_koltes', title: 'Havi költés'),
  FastInfoCardDefinition(id: 'megtakaritas', title: 'Megtakarítás'),
  FastInfoCardDefinition(id: 'koltesi_trend', title: '30 napos költési trend'),
  FastInfoCardDefinition(
    id: 'legutobbi_tranzakcio',
    title: 'Utolsó tranzakció',
  ),
  FastInfoCardDefinition(
    id: 'varhato_ho_vegi_koltes',
    title: 'Várható hó végi költés',
  ),
  FastInfoCardDefinition(
    id: 'leggyorsabban_fogyo_kategorialimit',
    title: 'Kategórialimit állapot',
  ),
  FastInfoCardDefinition(
    id: 'leggyakoribb_kereskedo',
    title: 'Leggyakoribb kereskedő',
  ),
  FastInfoCardDefinition(
    id: 'atlagos_napi_koltes',
    title: 'Átlagos napi költés',
  ),
  FastInfoCardDefinition(id: 'no_spend_napok_szama', title: 'No-spend napok'),
  FastInfoCardDefinition(id: 'top_kategoria_ma', title: 'Top kategória ma'),
  FastInfoCardDefinition(
    id: 'top_kategoria_heten',
    title: 'Top kategória héten/hónapban',
  ),
  FastInfoCardDefinition(
    id: 'legnagyobb_novekedo_kategoria',
    title: 'Legnagyobb kategóriaváltozás',
  ),
  FastInfoCardDefinition(
    id: 'kovetkezo_ismetlo_kiadas',
    title: 'Közelgő ismétlődő kiadások',
  ),
  FastInfoCardDefinition(
    id: 'havi_fix_koltseg_osszesen',
    title: 'Havi fix költségek',
  ),
  FastInfoCardDefinition(id: 'bevetel_ebben_a_honapban', title: 'Havi bevétel'),
  FastInfoCardDefinition(
    id: 'kiadas_bevetel_arany',
    title: 'Kiadás/bevétel arány',
  ),
];

const fastInfoLegacyIdMap = <String, String>{
  'mai_maradek_keret': 'mai_koltes',
  'napi_ajanlott_maximum': 'mai_koltes',
  'mai_koltes_ajanlotthoz': 'mai_koltes',
  'mai_nap_atlaghoz_kepest': 'mai_koltes',
  'ma_rogzitett_tranzakciok_szama': 'mai_koltes',
  'heti_maradek_keret': 'heti_koltes',
  'ez_a_het_elozo_hethez': 'heti_koltes',
  'havi_limit_allapot': 'havi_koltes',
  'ez_a_honap_elozo_honaphoz': 'havi_koltes',
  'megtakaritasi_cel_haladas': 'megtakaritas',
  'havi_megtakaritasi_rata': 'megtakaritas',
  'havi_keret_egesi_sebesseg': 'koltesi_trend',
  'tulkoltes_kockazat': 'varhato_ho_vegi_koltes',
  'ho_vegi_becsult_maradek': 'varhato_ho_vegi_koltes',
  'limit_feletti_kategoriak_szama': 'leggyorsabban_fogyo_kategorialimit',
  'kategoria_limit_kozeleben': 'leggyorsabban_fogyo_kategorialimit',
  'kategoria_limit_tullepve': 'leggyorsabban_fogyo_kategorialimit',
  'puffer_napok_szama': 'atlagos_napi_koltes',
  'top_kategoria_honapban': 'top_kategoria_heten',
  'legjobban_csokkeno_kategoria': 'legnagyobb_novekedo_kategoria',
  'kovetkezo_7_nap_fix_kiadasai': 'kovetkezo_ismetlo_kiadas',
  'fix_koltseg_aranya_havi_keretbol': 'havi_fix_koltseg_osszesen',
  'mar_levont_fix_kiadasok': 'havi_fix_koltseg_osszesen',
  'meg_varhato_fix_kiadasok': 'havi_fix_koltseg_osszesen',
  'legnagyobb_fix_kiadas': 'havi_fix_koltseg_osszesen',
  'fix_koltsegek_utan_marado_keret': 'havi_fix_koltseg_osszesen',
  'netto_havi_cashflow': 'kiadas_bevetel_arany',
};

FastInfoCardDefinition? fastInfoCardById(String id) {
  for (final card in fastInfoCardCatalog) {
    if (card.id == id) return card;
  }
  return null;
}

String? canonicalFastInfoCardId(String id) {
  final canonical = fastInfoLegacyIdMap[id] ?? id;
  return fastInfoCardById(canonical) == null ? null : canonical;
}
