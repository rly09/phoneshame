import SwiftUI
import WidgetKit

struct RotWidgetView: View {
  let entry: RotWidgetEntry

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(red: 0.04, green: 0.29, blue: 0.32), Color(red: 0.0, green: 0.2, blue: 0.22)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      VStack(alignment: .leading, spacing: 10) {
        Text("TODAY'S ROT")
          .font(.caption.weight(.semibold))
          .foregroundColor(.white.opacity(0.7))

        Text(entry.totalTimeLabel)
          .font(.system(size: 30, weight: .bold, design: .rounded))
          .foregroundColor(.white)

        Text("Rot score \(entry.score)")
          .font(.headline.weight(.semibold))
          .foregroundColor(Color(red: 1.0, green: 0.61, blue: 0.44))

        Text(
          entry.hasData
            ? "\(entry.topApp) • \(entry.topTimeLabel)"
            : "Open the app to sync today's stats"
        )
        .font(.subheadline)
        .foregroundColor(.white)
        .lineLimit(2)

        Spacer(minLength: 0)

        Text("\(entry.trackedAppsCount) apps tracked")
          .font(.caption2)
          .foregroundColor(.white.opacity(0.65))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .padding(16)
    }
  }
}
