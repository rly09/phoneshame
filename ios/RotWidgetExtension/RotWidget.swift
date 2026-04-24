import SwiftUI
import WidgetKit

struct RotWidgetEntry: TimelineEntry {
  let date: Date
  let totalTimeLabel: String
  let score: Int
  let topApp: String
  let topTimeLabel: String
  let trackedAppsCount: Int
  let hasData: Bool
}

struct RotWidgetProvider: TimelineProvider {
  private let suiteName = "group.com.example.phoneshame.widgets"

  func placeholder(in context: Context) -> RotWidgetEntry {
    RotWidgetEntry(
      date: Date(),
      totalTimeLabel: "2h 14m",
      score: 71,
      topApp: "Instagram",
      topTimeLabel: "1h 02m",
      trackedAppsCount: 8,
      hasData: true
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (RotWidgetEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<RotWidgetEntry>) -> Void) {
    let entry = loadEntry()
    let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }

  private func loadEntry() -> RotWidgetEntry {
    let defaults = UserDefaults(suiteName: suiteName)
    return RotWidgetEntry(
      date: Date(),
      totalTimeLabel: defaults?.string(forKey: "total_time_label") ?? "0m",
      score: defaults?.integer(forKey: "score") ?? 0,
      topApp: defaults?.string(forKey: "top_app") ?? "No data yet",
      topTimeLabel: defaults?.string(forKey: "top_time_label") ?? "0m",
      trackedAppsCount: defaults?.integer(forKey: "tracked_apps_count") ?? 0,
      hasData: defaults?.bool(forKey: "has_data") ?? false
    )
  }
}

struct RotWidget: Widget {
  let kind: String = "RotWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RotWidgetProvider()) { entry in
      RotWidgetView(entry: entry)
    }
    .configurationDisplayName("ROT Summary")
    .description("See your daily screen-time shame score on the home screen.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
