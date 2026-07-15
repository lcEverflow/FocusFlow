import SwiftUI

/// 统计：今日概览、近 7 天专注趋势、今日按任务分布。
struct StatsView: View {
    @Environment(AppEnvironment.self) private var app
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SubpageHeader(title: "统计", onBack: onClose)
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

            weekSection
                .padding(12)

            Divider()

            HStack {
                Text("今日任务分布").font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

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

    // MARK: - 近 7 天趋势（精简手绘柱状：共享基线，今天高亮）

    private var weekSection: some View {
        let week = app.records.recentDailyFocus(days: 7)
        let total = week.reduce(0) { $0 + $1.seconds }
        let maxSec = max(week.map(\.seconds).max() ?? 0, 1)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("近 7 天").font(.subheadline.weight(.semibold))
                Spacer()
                Text("共 \(TimeFormat.hm(total)) · 日均 \(TimeFormat.hm(total / 7))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(week) { d in
                    VStack(spacing: 4) {
                        Text(d.seconds > 0 ? "\(d.seconds / 60)" : " ")
                            .font(.system(size: 9))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isToday(d.day) ? Color.orange : Color.orange.opacity(0.35))
                            .frame(height: barHeight(d.seconds, max: maxSec))
                        Text(dayLabel(d.day))
                            .font(.system(size: 10))
                            .foregroundStyle(isToday(d.day) ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func barHeight(_ seconds: Int, max: Int) -> CGFloat {
        let minH: CGFloat = 4, maxH: CGFloat = 64
        return minH + (maxH - minH) * CGFloat(seconds) / CGFloat(max)
    }

    private func isToday(_ date: Date) -> Bool { Calendar.current.isDateInToday(date) }

    /// 今天显示「今」，其余显示中文星期简写。
    private func dayLabel(_ date: Date) -> String {
        if isToday(date) { return "今" }
        let wd = Calendar.current.component(.weekday, from: date) // 1=周日
        return ["日", "一", "二", "三", "四", "五", "六"][wd - 1]
    }
}
