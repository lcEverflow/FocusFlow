import SwiftUI

/// 今日统计：总专注时长、完成番茄数、按任务分布。
struct StatsView: View {
    @Environment(AppEnvironment.self) private var app
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SubpageHeader(title: "今日统计", onBack: onClose)
            Divider()

            HStack(spacing: 12) {
                summaryCard(
                    value: TimeFormat.hm(app.records.todayFocusSeconds()),
                    caption: "专注时长"
                )
                summaryCard(
                    value: "\(app.records.todayPomodoroCount())",
                    caption: "完成番茄 🍅"
                )
            }
            .padding(12)

            Divider()

            let stats = app.records.todayTaskStats()
            if stats.isEmpty {
                Text("今天还没有专注记录")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 24)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        let maxSeconds = stats.first?.seconds ?? 1
                        ForEach(stats) { stat in
                            statRow(stat, maxSeconds: maxSeconds)
                        }
                    }
                    .padding(12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func summaryCard(value: String, caption: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.05)))
    }

    private func statRow(_ stat: RecordStore.DailyTaskStat, maxSeconds: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(stat.title)
                    .font(.callout)
                    .lineLimit(1)
                Spacer()
                Text("\(TimeFormat.hm(stat.seconds)) · \(stat.pomodoros)🍅")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(stat.seconds), total: Double(max(maxSeconds, 1)))
                .progressViewStyle(.linear)
                .tint(.orange)
        }
    }
}
