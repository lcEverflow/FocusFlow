import SwiftUI

/// 新建/编辑任务表单。编辑时保留已投入时间等进度字段。
struct TaskEditorView: View {
    @Environment(AppEnvironment.self) private var app
    /// nil = 新建
    let editing: FocusTask?
    let onClose: () -> Void

    @State private var title = ""
    @State private var priority: TaskPriority = .medium
    @State private var estimatedMinutes = 120
    @State private var focusMinutes = 25
    @State private var loaded = false

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// 按当前表单值预览拆分出的番茄数
    private var plannedPomodoros: Int {
        max(1, Int((Double(estimatedMinutes) / Double(max(focusMinutes, 1))).rounded(.up)))
    }

    var body: some View {
        VStack(spacing: 0) {
            SubpageHeader(title: editing == nil ? "新建任务" : "编辑任务", onBack: onClose)
            Divider()

            Form {
                TextField("任务名称", text: $title, prompt: Text("例如：阅读论文"))

                Picker("优先级", selection: $priority) {
                    ForEach(TaskPriority.allCases) { priority in
                        Text(priority.label).tag(priority)
                    }
                }
                .pickerStyle(.segmented)

                Stepper(value: $estimatedMinutes, in: 15...6000, step: 15) {
                    LabeledContent("预计总耗时", value: TimeFormat.hm(estimatedMinutes * 60))
                }

                Stepper(value: $focusMinutes, in: 5...180, step: 5) {
                    LabeledContent("单次专注", value: "\(focusMinutes) 分钟")
                }

                Text("将拆分为 \(plannedPomodoros) 个番茄 🍅")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .formStyle(.columns)
            .padding(12)

            Spacer(minLength: 0)
            Divider()
            HStack {
                Button("取消", action: onClose)
                    .controlSize(.small)
                Spacer()
                Button("保存", action: save)
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .onAppear(perform: populate)
    }

    /// Environment 在 init 里拿不到，首次出现时再填充初始值
    private func populate() {
        guard !loaded else { return }
        loaded = true
        if let task = editing {
            title = task.title
            priority = task.priority
            estimatedMinutes = task.estimatedMinutes
            focusMinutes = task.focusMinutes
        } else {
            focusMinutes = app.settings.defaultFocusMinutes
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if var task = editing {
            task.title = trimmed
            task.priority = priority
            task.estimatedMinutes = estimatedMinutes
            task.focusMinutes = focusMinutes
            app.tasks.update(task)
        } else {
            app.tasks.add(FocusTask(
                title: trimmed,
                priority: priority,
                estimatedMinutes: estimatedMinutes,
                focusMinutes: focusMinutes
            ))
        }
        onClose()
    }
}
