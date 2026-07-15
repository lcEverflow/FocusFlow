import Foundation
import Observation
import AppKit

/// 轻量自建更新检查（零第三方依赖）：查 GitHub Releases API 比对版本，
/// 有新版则通知 + 在 UI 引导下载。不做静默自动安装（那需要 Sparkle 级方案）。
///
/// - 触发：App 启动时节流检查（每 24h 一次）+ 设置里手动「检查更新」。
/// - 通知：仅 best-effort（用户已授权通知时才弹），点击打开发布页；in-app banner 为可靠通道。
@MainActor
@Observable
final class UpdateService {
    enum Status: Equatable {
        case idle
        case checking
        case upToDate(latest: String)
        case available(ReleaseInfo)
        case failed(String)
    }

    struct ReleaseInfo: Equatable {
        let version: String      // 归一化 "1.2.0"
        let tag: String          // 原始 "v1.2.0"
        let pageURL: URL         // release 页面
        let dmgURL: URL?         // .dmg 直链（若有）
    }

    private(set) var status: Status = .idle

    let currentVersion: String

    @ObservationIgnored private let owner = "lcEverflow"
    @ObservationIgnored private let repo = "FocusFlow"
    @ObservationIgnored private let notifications: NotificationService?
    @ObservationIgnored private let defaults: UserDefaults

    private enum Keys {
        static let lastCheck = "updates.lastCheckAt"
        static let lastNotifiedVersion = "updates.lastNotifiedVersion"
    }

    init(notifications: NotificationService? = nil, defaults: UserDefaults = .standard) {
        self.notifications = notifications
        self.defaults = defaults
        self.currentVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
    }

    /// 检查更新。`force=false`（启动自动检查）距上次不足 24h 则跳过；手动检查传 `true`。
    func checkForUpdates(force: Bool) async {
        if case .checking = status { return }
        if !force, let last = defaults.object(forKey: Keys.lastCheck) as? Date,
           Date().timeIntervalSince(last) < 24 * 3600 {
            return
        }
        status = .checking
        defaults.set(Date(), forKey: Keys.lastCheck)
        do {
            let release = try await fetchLatest()
            if Self.isNewer(release.version, than: currentVersion) {
                status = .available(release)
                notifyOnce(release)
            } else {
                status = .upToDate(latest: release.version)
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    /// 打开下载：优先 .dmg 直链，否则 release 页面。
    func openDownload() {
        guard case .available(let info) = status else { return }
        NSWorkspace.shared.open(info.dmgURL ?? info.pageURL)
    }

    // MARK: - 网络

    private func fetchLatest() async throws -> ReleaseInfo {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest")!
        var req = URLRequest(url: url)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("FocusFlow-Updater", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 15
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw UpdateError.noResponse }
        guard http.statusCode == 200 else { throw UpdateError.badStatus(http.statusCode) }
        let gh = try JSONDecoder().decode(GHRelease.self, from: data)
        let dmg = gh.assets.first { $0.name.lowercased().hasSuffix(".dmg") }
        return ReleaseInfo(
            version: Self.normalize(gh.tag_name),
            tag: gh.tag_name,
            pageURL: URL(string: gh.html_url) ?? url,
            dmgURL: dmg.flatMap { URL(string: $0.browser_download_url) }
        )
    }

    /// 每个新版本只通知一次，避免每天启动都打扰。
    private func notifyOnce(_ release: ReleaseInfo) {
        guard defaults.string(forKey: Keys.lastNotifiedVersion) != release.version else { return }
        defaults.set(release.version, forKey: Keys.lastNotifiedVersion)
        notifications?.notifyUpdateAvailable(version: release.tag, url: release.pageURL)
    }

    // MARK: - 版本号比较（去 v 前缀，按数字段逐段比较）

    static func normalize(_ tag: String) -> String {
        var s = tag.trimmingCharacters(in: .whitespaces)
        if s.first == "v" || s.first == "V" { s.removeFirst() }
        return s
    }

    /// a 是否比 b 新（语义化，缺省段按 0）。
    static func isNewer(_ a: String, than b: String) -> Bool {
        let pa = parts(a), pb = parts(b)
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0
            let y = i < pb.count ? pb[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    private static func parts(_ v: String) -> [Int] {
        normalize(v).split(separator: ".").map { Int($0.prefix { $0.isNumber }) ?? 0 }
    }

    // MARK: - 私有类型

    private enum UpdateError: LocalizedError {
        case noResponse
        case badStatus(Int)
        var errorDescription: String? {
            switch self {
            case .noResponse: return "无网络响应"
            case .badStatus(let c): return "GitHub 返回 HTTP \(c)"
            }
        }
    }

    private struct GHRelease: Decodable {
        let tag_name: String
        let html_url: String
        let assets: [Asset]
        struct Asset: Decodable {
            let name: String
            let browser_download_url: String
        }
    }
}
