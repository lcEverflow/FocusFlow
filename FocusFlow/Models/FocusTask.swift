import Foundation

/// 任务：番茄钟围绕任务展开，进度按「已投入专注时间 / 预计总耗时」累计。
/// 命名 FocusTask 以避开 Swift Concurrency 的 `Task`。
struct FocusTask: Identifiable, Codable, Hashable {
    enum Status: String, Codable {
        case active
        case completed
    }

    var id: UUID = UUID()
    var title: String
    var priority: TaskPriority = .medium
    /// 预计总耗时（分钟）
    var estimatedMinutes: Int = 120
    /// 单次专注时长（分钟）
    var focusMinutes: Int = 25
    var status: Status = .active
    var createdAt: Date = Date()
    var completedAt: Date?
    /// 已投入的专注秒数（含未跑满一整个番茄的部分）
    var investedSeconds: Int = 0
    /// 完整跑完的番茄数
    var completedPomodoros: Int = 0

    var estimatedSeconds: Int { estimatedMinutes * 60 }

    /// 按预计耗时 / 单次专注拆分出的计划番茄数
    var plannedPomodoros: Int {
        max(1, Int((Double(estimatedMinutes) / Double(max(focusMinutes, 1))).rounded(.up)))
    }

    var progress: Double {
        guard estimatedSeconds > 0 else { return 0 }
        return min(1.0, Double(investedSeconds) / Double(estimatedSeconds))
    }

    var isCompleted: Bool { status == .completed }

    /// 已投入时间达到预估
    var reachedEstimate: Bool { investedSeconds >= estimatedSeconds }
}
