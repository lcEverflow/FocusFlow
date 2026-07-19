import SwiftUI

/// 任务列表：今日进行中按优先级排序，昨日遗留未完成折叠在「未完成」区，今日已完成折叠在最下方。
struct TaskListView: View {
    @Environment(AppEnvironment.self) private var app
    @Binding var route: MenuRoute
    @State private var showOlderActive = false
    @State private var showCompleted = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                let todayActive = app.tasks.todayActiveTasks
                let olderActive = app.tasks.olderActiveTasks
                let todayDone = app.tasks.todayCompletedTasks

                if todayActive.isEmpty && olderActive.isEmpty && todayDone.isEmpty {
                    Text("还没有任务，点击下方「新建任务」开始")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 20)
                }

                ForEach(todayActive) { task in
                    TaskRowView(task: task, route: $route)
                }

                if !olderActive.isEmpty {
                    olderActiveSection(olderActive)
                }

                if !todayDone.isEmpty {
                    completedSection(todayDone)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func olderActiveSection(_ tasks: [FocusTask]) -> some View {
        VStack(spacing: 2) {
            Button {
                withAnimation { showOlderActive.toggle() }
            } label: {
                HStack {
                    Image(systemName: showOlderActive ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                    Text("未完成（\(tasks.count)）")
                        .font(.caption)
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
            .padding(.top, 6)

            if showOlderActive {
                ForEach(tasks) { task in
                    TaskRowView(task: task, route: $route)
                }
            }
        }
    }

    private func completedSection(_ tasks: [FocusTask]) -> some View {
        VStack(spacing: 2) {
            Button {
                withAnimation { showCompleted.toggle() }
            } label: {
                HStack {
                    Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                    Text("已完成（\(tasks.count)）")
                        .font(.caption)
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
            .padding(.top, 6)

            if showCompleted {
                ForEach(tasks) { task in
                    TaskRowView(task: task, route: $route)
                }
            }
        }
    }
}
