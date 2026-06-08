enum CalendarMenuMode { category, summary, heatmap }

extension CalendarMenuModeX on CalendarMenuMode {
  String get title => switch (this) {
    CalendarMenuMode.category => 'Domináns kategória',
    CalendarMenuMode.summary => 'Összefoglaló',
    CalendarMenuMode.heatmap => 'Hőtérkép',
  };
}
