import SwiftUI

/// 弹窗顶部的计时面板：当前任务、阶段、倒计时与操作按钮。
struct TimerPanelView: View {
    @Environment(AppEnvironment.self) private var app

    private var pomodoro: PomodoroController { app.pomodoro }

    var body: some View {
        VStack(spacing: 8) {
            if let phase = pomodoro.phase {
                activePanel(phase)
            } else if let task = pomodoro.currentTask, !task.isCompleted {
                idleWithTaskPanel(task)
            } else {
                Text("选择一个任务，开始专注 🍅")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - 计时中/暂停中

    @ViewBuilder
    private func activePanel(_ phase: PomodoroController.Phase) -> some View {
        HStack {
            Label(
                phase.label + (pomodoro.isPaused ? "（已暂停）" : ""),
                systemImage: phase.isBreak ? "cup.and.saucer.fill" : "flame.fill"
            )
            .font(.caption)
            .foregroundStyle(phase.isBreak ? Color.teal : Color.orange)
            Spacer()
            if let task = pomodoro.currentTask {
                Text("🍅 \(task.completedPomodoros)/\(task.plannedPomodoros)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        if let task = pomodoro.currentTask {
            Text(task.title)
                .font(.headline)
                .lineLimit(1)
        }

        Text(TimeFormat.mmss(pomodoro.remaining))
            .font(.system(size: 34, weight: .semibold, design: .rounded))
            .monospacedDigit()

        ProgressView(value: phaseProgress)
            .progressViewStyle(.linear)
            .tint(phase.isBreak ? .teal : .orange)

        HStack(spacing: 10) {
            controlButton(
                pomodoro.isPaused ? "继续" : "暂停",
                systemImage: pomodoro.isPaused ? "play.fill" : "pause.fill"
            ) {
                pomodoro.isPaused ? pomodoro.resume() : pomodoro.pause()
            }
            controlButton("跳过", systemImage: "forward.end.fill") {
                pomodoro.skip()
            }
            controlButton("结束", systemImage: "stop.fill", role: .destructive) {
                pomodoro.stop()
            }
        }
    }

    /// 当前阶段进度（0~1）
    private var phaseProgress: Double {
        guard pomodoro.plannedSeconds > 0 else { return 0 }
        return min(1, pomodoro.elapsedInPhase / pomodoro.plannedSeconds)
    }

    // MARK: - 空闲但有任务（手动继续模式）

    @ViewBuilder
    private func idleWithTaskPanel(_ task: FocusTask) -> some View {
        Text(task.title)
            .font(.headline)
            .lineLimit(1)
        Text(task.reachedEstimate ? "预计投入已全部达成 🎉" : "本阶段已结束，随时继续")
            .font(.caption)
            .foregroundStyle(.secondary)
        HStack(spacing: 10) {
            controlButton("继续专注", systemImage: "play.fill") {
                pomodoro.startNextFocus()
            }
            controlButton("结束会话", systemImage: "stop.fill", role: .destructive) {
                pomodoro.stop()
            }
        }
    }

    private func controlButton(
        _ title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.small)
    }
}
