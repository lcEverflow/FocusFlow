import Foundation

enum TimeFormat {
    /// 倒计时展示：`24:59`
    static func mmss(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded()))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    /// 累计时长展示：`2小时15分` / `45分钟`
    static func hm(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 && minutes > 0 { return "\(hours)小时\(minutes)分" }
        if hours > 0 { return "\(hours)小时" }
        return "\(minutes)分钟"
    }
}
