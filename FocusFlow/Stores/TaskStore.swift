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

    /// 进行中任务：优先级降序，同级按创建时间
    var activeTasks: [FocusTask] {
        tasks.filter { !$0.isCompleted }.sorted { a, b in
            if a.priority != b.priority { return a.priority < b.priority }
            return a.createdAt < b.createdAt
        }
    }

    var completedTasks: [FocusTask] {
        tasks.filter(\.isCompleted).sorted {
            ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
        }
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
