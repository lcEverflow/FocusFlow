import Foundation
import Observation

/// 全局偏好设置，UserDefaults 持久化。任务可用自己的单次专注时长覆盖默认值。
@MainActor
@Observable
final class SettingsStore {
    private enum Keys {
        static let defaultFocusMinutes = "settings.defaultFocusMinutes"
        static let shortBreakMinutes = "settings.shortBreakMinutes"
        static let longBreakMinutes = "settings.longBreakMinutes"
        static let longBreakEvery = "settings.longBreakEvery"
        static let autoStartBreak = "settings.autoStartBreak"
        static let autoStartNextFocus = "settings.autoStartNextFocus"
        static let showTaskTitleInMenuBar = "settings.showTaskTitleInMenuBar"
        static let notificationSound = "settings.notificationSound"
        static let endSoundEnabled = "settings.endSoundEnabled"
    }

    var defaultFocusMinutes: Int { didSet { persist() } }
    var shortBreakMinutes: Int { didSet { persist() } }
    var longBreakMinutes: Int { didSet { persist() } }
    /// 每完成 N 个番茄后进入长休息
    var longBreakEvery: Int { didSet { persist() } }
    var autoStartBreak: Bool { didSet { persist() } }
    var autoStartNextFocus: Bool { didSet { persist() } }
    var showTaskTitleInMenuBar: Bool { didSet { persist() } }
    var notificationSound: Bool { didSet { persist() } }
    /// 阶段结束时播放音效（独立于系统通知声）
    var endSoundEnabled: Bool { didSet { persist() } }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaultFocusMinutes = defaults.object(forKey: Keys.defaultFocusMinutes) as? Int ?? 25
        shortBreakMinutes = defaults.object(forKey: Keys.shortBreakMinutes) as? Int ?? 5
        longBreakMinutes = defaults.object(forKey: Keys.longBreakMinutes) as? Int ?? 15
        longBreakEvery = defaults.object(forKey: Keys.longBreakEvery) as? Int ?? 4
        autoStartBreak = defaults.object(forKey: Keys.autoStartBreak) as? Bool ?? true
        autoStartNextFocus = defaults.object(forKey: Keys.autoStartNextFocus) as? Bool ?? true
        showTaskTitleInMenuBar = defaults.object(forKey: Keys.showTaskTitleInMenuBar) as? Bool ?? true
        notificationSound = defaults.object(forKey: Keys.notificationSound) as? Bool ?? true
        endSoundEnabled = defaults.object(forKey: Keys.endSoundEnabled) as? Bool ?? true
    }

    private func persist() {
        defaults.set(defaultFocusMinutes, forKey: Keys.defaultFocusMinutes)
        defaults.set(shortBreakMinutes, forKey: Keys.shortBreakMinutes)
        defaults.set(longBreakMinutes, forKey: Keys.longBreakMinutes)
        defaults.set(longBreakEvery, forKey: Keys.longBreakEvery)
        defaults.set(autoStartBreak, forKey: Keys.autoStartBreak)
        defaults.set(autoStartNextFocus, forKey: Keys.autoStartNextFocus)
        defaults.set(showTaskTitleInMenuBar, forKey: Keys.showTaskTitleInMenuBar)
        defaults.set(notificationSound, forKey: Keys.notificationSound)
        defaults.set(endSoundEnabled, forKey: Keys.endSoundEnabled)
    }
}
