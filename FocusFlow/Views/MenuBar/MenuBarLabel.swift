import SwiftUI

/// 菜单栏常驻标签：空闲时只显示图标，计时中追加剩余时间（可选任务名）。
struct MenuBarLabel: View {
    let app: AppEnvironment

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
            if let text = title {
                Text(text)
                    .monospacedDigit()
            }
        }
    }

    private var symbol: String {
        guard let phase = app.pomodoro.phase else { return "timer" }
        if app.pomodoro.isPaused { return "pause.circle" }
        return phase.isBreak ? "cup.and.saucer.fill" : "timer"
    }

    private var title: String? {
        let pomodoro = app.pomodoro
        guard let phase = pomodoro.phase else { return nil }
        var parts: [String] = []
        if app.settings.showTaskTitleInMenuBar,
           phase == .focus,
           let task = pomodoro.currentTask {
            parts.append(truncated(task.title))
        }
        parts.append(TimeFormat.mmss(pomodoro.remaining))
        return parts.joined(separator: " ")
    }

    /// 菜单栏空间宝贵，任务名过长时截断
    private func truncated(_ text: String, limit: Int = 8) -> String {
        text.count <= limit ? text : String(text.prefix(limit)) + "…"
    }
}
