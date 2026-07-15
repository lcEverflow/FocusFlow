import SwiftUI

/// 弹窗内的轻量路由：菜单栏应用不开主窗口，所有页面都在弹窗内切换。
enum MenuRoute: Equatable {
    case home
    /// nil = 新建任务
    case editor(FocusTask?)
    case stats
    case settings
}

/// MenuBarExtra 弹窗的根视图，负责页面切换。
struct MenuBarContentView: View {
    @Environment(AppEnvironment.self) private var app
    @State private var route: MenuRoute = .home

    var body: some View {
        Group {
            switch route {
            case .home:
                HomeView(route: $route)
            case .editor(let task):
                TaskEditorView(editing: task) { route = .home }
            case .stats:
                StatsView { route = .home }
            case .settings:
                SettingsView { route = .home }
            }
        }
        // 固定尺寸：MenuBarExtra 的 window 弹层对动态内容高度变化的重算不可靠
        //（计时面板展开时底部列表会被裁剪），固定框架 + 内部弹性区域最稳。
        .frame(width: 380, height: 560)
    }
}

/// 子页面共用的「返回 + 标题」头部
struct SubpageHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
