import SwiftUI

/// 任务列表：进行中按优先级排序，已完成折叠在下方。
struct TaskListView: View {
    @Environment(AppEnvironment.self) private var app
    @Binding var route: MenuRoute
    @State private var showCompleted = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if app.tasks.activeTasks.isEmpty && app.tasks.completedTasks.isEmpty {
                    Text("还没有任务，点击下方「新建任务」开始")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 20)
                }

                ForEach(app.tasks.activeTasks) { task in
                    TaskRowView(task: task, route: $route)
                }

                if !app.tasks.completedTasks.isEmpty {
                    completedSection
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var completedSection: some View {
        VStack(spacing: 2) {
            Button {
                withAnimation { showCompleted.toggle() }
            } label: {
                HStack {
                    Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                    Text("已完成（\(app.tasks.completedTasks.count)）")
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
                ForEach(app.tasks.completedTasks) { task in
                    TaskRowView(task: task, route: $route)
                }
            }
        }
    }
}
