import Foundation

/// 一段完成的专注/休息记录，统计与后续数据分析的原始数据源。
struct PomodoroRecord: Identifiable, Codable {
    enum Kind: String, Codable {
        case focus
        case rest
    }

    var id: UUID = UUID()
    var taskID: UUID?
    /// 冗余任务名，任务被删除后统计仍可读
    var taskTitle: String
    var kind: Kind
    var startedAt: Date
    var endedAt: Date
    var seconds: Int
    /// 是否完整跑满（false = 被跳过/提前结束）
    var completedFully: Bool
}
