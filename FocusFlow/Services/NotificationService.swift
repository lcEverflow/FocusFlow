import Foundation
import UserNotifications
import AppKit

/// 系统通知封装。首次真正需要发通知前才请求授权，避免启动即弹窗。
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    /// 无 bundle 环境（如 `swift run` 裸执行）下 UNUserNotificationCenter 会崩溃，直接降级为 no-op
    private let isAvailable = Bundle.main.bundleIdentifier != nil
    private var didRequestAuthorization = false

    override init() {
        super.init()
        if isAvailable {
            UNUserNotificationCenter.current().delegate = self
        }
    }

    func requestAuthorizationIfNeeded() {
        guard isAvailable, !didRequestAuthorization else { return }
        didRequestAuthorization = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyFocusEnded(taskTitle: String?, reachedEstimate: Bool, sound: Bool) {
        var body = taskTitle.map { "「\($0)」本次专注完成，休息一下吧。" } ?? "本次专注完成，休息一下吧。"
        if reachedEstimate {
            body += " 🎉 该任务的预计投入时长已全部达成！"
        }
        send(title: "专注结束 🍅", body: body, sound: sound)
    }

    func notifyBreakEnded(taskTitle: String?, sound: Bool) {
        let body = taskTitle.map { "继续「\($0)」的下一个专注吧。" } ?? "开始下一个专注吧。"
        send(title: "休息结束", body: body, sound: sound)
    }

    /// 发现新版本时提醒；点击通知打开发布页。best-effort：仅在用户已授权通知时展示。
    func notifyUpdateAvailable(version: String, url: URL) {
        guard isAvailable else { return }
        let content = UNMutableNotificationContent()
        content.title = "FocusFlow 有新版本 \(version)"
        content.body = "点击前往下载更新。"
        content.userInfo = ["url": url.absoluteString]
        let request = UNNotificationRequest(identifier: "update-\(version)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func send(title: String, body: String, sound: Bool) {
        guard isAvailable else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if sound { content.sound = .default }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // App 处于前台（菜单栏应用几乎总是）时也以横幅形式展示
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // 点击通知：若携带 url（更新提醒），打开对应页面
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let str = response.notification.request.content.userInfo["url"] as? String,
           let url = URL(string: str) {
            NSWorkspace.shared.open(url)
        }
        completionHandler()
    }
}
