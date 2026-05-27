enum CalendarMenuMode { normal, summary, heatmap, category }

extension CalendarMenuModeX on CalendarMenuMode {
  String get title => switch (this) {
    CalendarMenuMode.normal => 'Küszöbérték nézet',
    CalendarMenuMode.summary => 'Összefoglaló',
    CalendarMenuMode.heatmap => 'Hőtérkép',
    CalendarMenuMode.category => 'Domináns kategória',
  };
}
