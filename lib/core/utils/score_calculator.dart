class ScoreCalculator {
  /// Calculate score 0–1000 based on total daily screen time
  /// 0–2 hrs = 0–200 (healthy)
  /// 2–4 hrs = 200–500 (moderate)
  /// 4–6 hrs = 500–800 (bad)
  /// 6+ hrs = 800–1000 (shameful)
  static int calculateRotScore(int totalMinutes) {
    if (totalMinutes <= 120) {
      return ((totalMinutes / 120) * 200).round();
    } else if (totalMinutes <= 240) {
      final additional = totalMinutes - 120;
      return 200 + ((additional / 120) * 300).round();
    } else if (totalMinutes <= 360) {
      final additional = totalMinutes - 240;
      return 500 + ((additional / 120) * 300).round();
    } else {
      final additional = totalMinutes - 360;
      // Cap at 1000, reach 1000 at 8 hours (480 mins)
      final score = 800 + ((additional / 120) * 200).round();
      return score > 1000 ? 1000 : score;
    }
  }

  /// Calculates "What you could have done" alternatives based on total time
  /// E.g. read X pages (assume 30 pages/hr), run X km (assume 10 km/hr), etc.
  static List<String> getAlternatives(int totalMinutes) {
    final hours = totalMinutes / 60.0;
    if (hours < 0.5) return [];

    final pages = (hours * 30).round();
    final km = (hours * 10).round();
    final meals = (hours * 1.5).round();

    return [
      "Read $pages pages",
      "Ran $km km",
      "Cooked $meals meals"
    ];
  }
}
