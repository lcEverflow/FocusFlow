import SwiftUI

/// 单个任务行：优先级、标题、番茄进度；悬停出现快捷按钮，右键完整操作。
struct TaskRowView: View {
    @Environment(AppEnvironment.self) private var app
    let task: FocusTask
    @Binding var route: MenuRoute
    @State private var hovering = false

    private var isCurrent: Bool { app.pomodoro.currentTaskID == task.id }
    /// 该任务正处于计时中（专注或休息阶段）
    private var isRunningThis: Bool { isCurrent && app.pomodoro.phase != nil }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.callout)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("🍅 \(task.completedPomodoros)/\(task.plannedPomodoros)")
                    Text("\(TimeFormat.hm(task.investedSeconds)) / \(TimeFormat.hm(task.estimatedSeconds))")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                ProgressView(value: task.progress)
                    .progressViewStyle(.linear)
                    .controlSize(.small)
                    .tint(task.reachedEstimate ? .green : task.priority.color)
            }

            Spacer(minLength: 4)

            if !task.isCompleted {
                Button {
                    app.pomodoro.start(task: task)
                } label: {
                    Image(systemName: isRunningThis ? "waveform" : "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(isRunningThis ? Color.secondary : Color.orange)
                }
                .buttonStyle(.borderless)
                .disabled(isRunningThis)
                .help(isRunningThis ? "专注进行中" : "开始专注")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isCurrent ? Color.orange.opacity(0.12)
                      : hovering ? Color.primary.opacity(0.05)
                      : Color.clear)
        )
        .onHover { hovering = $0 }
        .contextMenu { menuItems }
    }

    @ViewBuilder
    private var menuItems: some View {
        if !task.isCompleted {
            Button("开始专注") { app.pomodoro.start(task: task) }
            Button("编辑") { route = .editor(task) }
            Button("标记完成") { app.setTaskCompleted(task, true) }
        } else {
            Button("恢复为进行中") { app.setTaskCompleted(task, false) }
        }
        Divider()
        Button("删除", role: .destructive) { app.deleteTask(task) }
    }
}
