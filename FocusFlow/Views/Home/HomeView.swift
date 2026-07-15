import SwiftUI
import AppKit

/// 弹窗主页：头部（今日概览 + 入口）、计时面板、任务列表、底栏。
struct HomeView: View {
    @Environment(AppEnvironment.self) private var app
    @Binding var route: MenuRoute

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            TimerPanelView()
            Divider()
            TaskListView(route: $route)
            Divider()
            footer
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("FocusFlow")
                .font(.headline)
            Spacer()
            Text("今日 \(app.records.todayPomodoroCount())🍅 · \(TimeFormat.hm(app.records.todayFocusSeconds()))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                route = .stats
            } label: {
                Image(systemName: "chart.bar.fill")
            }
            .buttonStyle(.borderless)
            .help("今日统计")
            Button {
                route = .settings
            } label: {
                Image(systemName: "gearshape.fill")
            }
            .buttonStyle(.borderless)
            .help("设置")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        HStack {
            Button {
                route = .editor(nil)
            } label: {
                Label("新建任务", systemImage: "plus")
            }
            .controlSize(.small)
            Spacer()
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
