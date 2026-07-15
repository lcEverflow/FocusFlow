import Foundation
import Observation

/// 专注/休息记录（append-only），今日统计直接在此聚合。
@MainActor
@Observable
final class RecordStore {
    private(set) var records: [PomodoroRecord] = []

    @ObservationIgnored private let store: DataStore
    private static let file = "records.json"

    init(store: DataStore) {
        self.store = store
        records = store.load([PomodoroRecord].self, from: Self.file) ?? []
    }

    func append(_ record: PomodoroRecord) {
        records.append(record)
        store.save(records, to: Self.file)
    }

    // MARK: - 今日统计

    func focusRecords(on date: Date = Date()) -> [PomodoroRecord] {
        records.filter {
            $0.kind == .focus && Calendar.current.isDate($0.endedAt, inSameDayAs: date)
        }
    }

    func todayFocusSeconds() -> Int {
        focusRecords().reduce(0) { $0 + $1.seconds }
    }

    func todayPomodoroCount() -> Int {
        focusRecords().filter(\.completedFully).count
    }

    struct DailyTaskStat: Identifiable {
        var id: String { title }
        let title: String
        let seconds: Int
        let pomodoros: Int
    }

    /// 今日按任务聚合的专注统计，时长降序
    func todayTaskStats() -> [DailyTaskStat] {
        let groups = Dictionary(grouping: focusRecords()) {
            $0.taskID?.uuidString ?? "adhoc-\($0.taskTitle)"
        }
        return groups.values.map { rs in
            DailyTaskStat(
                title: rs.first?.taskTitle ?? "未命名任务",
                seconds: rs.reduce(0) { $0 + $1.seconds },
                pomodoros: rs.filter(\.completedFully).count
            )
        }
        .sorted { $0.seconds > $1.seconds }
    }

    // MARK: - 近 N 天趋势

    struct DailyFocus: Identifiable {
        var id: Date { day }
        let day: Date          // 当天 0 点
        let seconds: Int
    }

    /// 最近 N 天每日专注时长（含无记录的 0 天），按日期升序（今天在最后）。
    func recentDailyFocus(days: Int = 7) -> [DailyFocus] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var byDay: [Date: Int] = [:]
        for r in records where r.kind == .focus {
            byDay[cal.startOfDay(for: r.endedAt), default: 0] += r.seconds
        }
        return (0..<days).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            return DailyFocus(day: day, seconds: byDay[day] ?? 0)
        }
    }
}
