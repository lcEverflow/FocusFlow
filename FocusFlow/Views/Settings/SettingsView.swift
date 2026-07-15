import SwiftUI

/// 偏好设置：时长节奏、自动流转、菜单栏展示、提示音。
struct SettingsView: View {
    @Environment(AppEnvironment.self) private var app
    let onClose: () -> Void

    var body: some View {
        @Bindable var settings = app.settings

        VStack(spacing: 0) {
            SubpageHeader(title: "设置", onBack: onClose)
            Divider()

            Form {
                Section("时长") {
                    Stepper(value: $settings.defaultFocusMinutes, in: 5...180, step: 5) {
                        LabeledContent("默认专注时长", value: "\(settings.defaultFocusMinutes) 分钟")
                    }
                    Stepper(value: $settings.shortBreakMinutes, in: 1...60) {
                        LabeledContent("短休息", value: "\(settings.shortBreakMinutes) 分钟")
                    }
                    Stepper(value: $settings.longBreakMinutes, in: 5...90, step: 5) {
                        LabeledContent("长休息", value: "\(settings.longBreakMinutes) 分钟")
                    }
                    Stepper(value: $settings.longBreakEvery, in: 2...8) {
                        LabeledContent("长休息间隔", value: "每 \(settings.longBreakEvery) 个番茄")
                    }
                }

                Section("流转") {
                    Toggle("专注结束后自动休息", isOn: $settings.autoStartBreak)
                    Toggle("休息结束后自动开始下一个专注", isOn: $settings.autoStartNextFocus)
                }

                Section("展示与提醒") {
                    Toggle("菜单栏显示任务名", isOn: $settings.showTaskTitleInMenuBar)
                    Toggle("结束音效 🔔", isOn: $settings.endSoundEnabled)
                    Toggle("通知提示音", isOn: $settings.notificationSound)
                }

                Section("关于") {
                    LabeledContent("当前版本", value: "v\(app.updates.currentVersion)")
                    updateRow
                }
            }
            .formStyle(.grouped)
            .frame(maxHeight: .infinity)
        }
    }

    /// 更新检查行：随 UpdateService.status 切换（检查中 / 已最新 / 有新版 / 失败）。
    @ViewBuilder
    private var updateRow: some View {
        switch app.updates.status {
        case .idle:
            Button("检查更新") { Task { await app.updates.checkForUpdates(force: true) } }
        case .checking:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("检查中…").foregroundStyle(.secondary)
            }
        case .upToDate(let latest):
            HStack {
                Label("已是最新（v\(latest)）", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Spacer()
                Button("重新检查") { Task { await app.updates.checkForUpdates(force: true) } }
                    .controlSize(.small)
            }
        case .available(let info):
            HStack {
                Label("发现新版本 \(info.tag)", systemImage: "arrow.down.circle.fill")
                    .foregroundStyle(.orange)
                Spacer()
                Button("下载") { app.updates.openDownload() }
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
            }
        case .failed(let msg):
            HStack {
                Label("检查失败", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.secondary)
                    .help(msg)
                Spacer()
                Button("重试") { Task { await app.updates.checkForUpdates(force: true) } }
                    .controlSize(.small)
            }
        }
    }
}
