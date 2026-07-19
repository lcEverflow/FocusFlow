import Foundation
import Observation

/// 任务集合的唯一事实来源，所有变更即时落盘。
@MainActor
@Observable
final class TaskStore {
    private(set) var tasks: [FocusTask] = []

    @ObservationIgnored private let store: DataStore
    private static let file = "tasks.json"

    init(store: DataStore) {
        self.store = store
        tasks = store.load([FocusTask].self, from: Self.file) ?? []
    }

    /// 进行中任务（全量，不分日期）：优先级降序，同级按创建时间
    var activeTasks: [FocusTask] {
        tasks.filter { !$0.isCompleted }.sorted { a, b in
            if a.priority != b.priority { return a.priority < b.priority }
            return a.createdAt < b.createdAt
        }
    }

    /// 今日进行中任务（今天创建的未完成任务）
    var todayActiveTasks: [FocusTask] {
        tasks.filter { !$0.isCompleted && Calendar.current.isDateInToday($0.createdAt) }
            .sorted { a, b in
                if a.priority != b.priority { return a.priority < b.priority }
                return a.createdAt < b.createdAt
            }
    }

    /// 昨日及更早的未完成任务（遗留）
    var olderActiveTasks: [FocusTask] {
        tasks.filter { !$0.isCompleted && !Calendar.current.isDateInToday($0.createdAt) }
            .sorted { a, b in
                if a.priority != b.priority { return a.priority < b.priority }
                return a.createdAt < b.createdAt
            }
    }

    /// 全部已完成任务（历史全量），当前仅内部/未来统计用。
    var completedTasks: [FocusTask] {
        tasks.filter(\.isCompleted).sorted {
            ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
        }
    }

    /// 今日完成的任务：主列表「已完成」区只展示当天完成的，避免昨日及更早的完成项
    /// 在此无限累计。历史完成项仍保留在 tasks.json，专注时长记录也仍在 records.json
    /// 供统计页回看——只是从每日看板里隐去，不丢数据。
    var todayCompletedTasks: [FocusTask] {
        tasks.filter { $0.isCompleted && Calendar.current.isDateInToday($0.completedAt ?? .distantPast) }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    func task(id: UUID) -> FocusTask? {
        tasks.first { $0.id == id }
    }

    func add(_ task: FocusTask) {
        tasks.append(task)
        persist()
    }

    func update(_ task: FocusTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        persist()
    }

    func delete(id: UUID) {
        tasks.removeAll { $0.id == id }
        persist()
    }

    func setCompleted(id: UUID, _ completed: Bool) {
        mutate(id) {
            $0.status = completed ? .completed : .active
            $0.completedAt = completed ? Date() : nil
        }
    }

    /// 为任务记账专注时间；fullPomodoro = 完整跑满一个番茄
    func credit(taskID: UUID, seconds: Int, fullPomodoro: Bool) {
        mutate(taskID) {
            $0.investedSeconds += seconds
            if fullPomodoro { $0.completedPomodoros += 1 }
        }
    }

    private func mutate(_ id: UUID, _ change: (inout FocusTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        change(&tasks[index])
        persist()
    }

    private func persist() {
        store.save(tasks, to: Self.file)
    }
}
