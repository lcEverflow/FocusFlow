import Foundation
import Observation

/// 组合根（Composition Root）：装配各子系统，并作为跨模块操作的统一门面。
///
/// 视图层只依赖本类型暴露的子系统；涉及多个子系统协作的操作
/// （如删除正在计时的任务）必须走这里的门面方法，避免视图散落业务规则。
@MainActor
@Observable
final class AppEnvironment {
    let settings: SettingsStore
    let tasks: TaskStore
    let records: RecordStore
    let notifications: NotificationService
    let sounds: SoundService
    let pomodoro: PomodoroController

    init(store: DataStore = JSONFileStore()) {
        let settings = SettingsStore()
        let tasks = TaskStore(store: store)
        let records = RecordStore(store: store)
        let notifications = NotificationService()
        let sounds = SoundService()
        self.settings = settings
        self.tasks = tasks
        self.records = records
        self.notifications = notifications
        self.sounds = sounds
        self.pomodoro = PomodoroController(
            settings: settings,
            tasks: tasks,
            records: records,
            notifications: notifications,
            sounds: sounds,
            store: store
        )
    }

    // MARK: - 跨子系统门面操作

    /// 删除任务；若该任务正在计时，先结束会话（已专注时间照常记账）。
    func deleteTask(_ task: FocusTask) {
        if pomodoro.currentTaskID == task.id { pomodoro.stop() }
        tasks.delete(id: task.id)
    }

    /// 标记任务完成/未完成；完成时若正在计时则先结束会话。
    func setTaskCompleted(_ task: FocusTask, _ completed: Bool) {
        if completed, pomodoro.currentTaskID == task.id { pomodoro.stop() }
        tasks.setCompleted(id: task.id, completed)
    }
}
