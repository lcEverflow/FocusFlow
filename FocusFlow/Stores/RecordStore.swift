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
}
