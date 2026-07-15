import Foundation
import Observation

/// 番茄钟流程编排：阶段推进、任务时间记账、通知触发、状态快照。
///
/// 与 CountdownEngine 的分工——engine 是不懂业务的倒计时，
/// controller 决定"下一个阶段是什么、时间记给谁、要不要通知"。
@MainActor
@Observable
final class PomodoroController {
    enum Phase: String, Codable {
        case focus
        case shortBreak
        case longBreak

        var isBreak: Bool { self != .focus }

        var label: String {
            switch self {
            case .focus: "专注中"
            case .shortBreak: "短休息"
            case .longBreak: "长休息"
            }
        }
    }

    /// 落盘快照：App 重启后据此恢复计时现场
    struct Snapshot: Codable {
        enum EngineState: Codable {
            case running(endDate: Date)
            case paused(remaining: TimeInterval)
        }

        var phase: Phase
        var engineState: EngineState
        var taskID: UUID?
        var phaseStartedAt: Date
        var plannedSeconds: TimeInterval
        var focusStreak: Int
    }

    let engine = CountdownEngine()

    /// nil = 空闲
    private(set) var phase: Phase?
    private(set) var currentTaskID: UUID?
    private(set) var plannedSeconds: TimeInterval = 0
    /// 本轮连续完成的番茄数，决定长休息节奏
    private(set) var focusStreak: Int = 0

    @ObservationIgnored private var phaseStartedAt: Date?

    private let settings: SettingsStore
    private let tasks: TaskStore
    private let records: RecordStore
    private let notifications: NotificationService
    private let sounds: SoundService
    private let store: DataStore
    private static let snapshotFile = "timer-state.json"

    init(
        settings: SettingsStore,
        tasks: TaskStore,
        records: RecordStore,
        notifications: NotificationService,
        sounds: SoundService,
        store: DataStore
    ) {
        self.settings = settings
        self.tasks = tasks
        self.records = records
        self.notifications = notifications
        self.sounds = sounds
        self.store = store
        engine.onFinished = { [weak self] in
            self?.advancePhase(fully: true)
        }
        restore()
    }

    // MARK: - 派生状态

    var currentTask: FocusTask? {
        currentTaskID.flatMap { tasks.task(id: $0) }
    }

    var remaining: TimeInterval { engine.remaining }
    var isRunning: Bool { engine.isRunning }
    var isPaused: Bool { engine.isPaused }
    var isIdle: Bool { phase == nil }

    /// 当前阶段已进行的秒数（供任务实时进度展示）
    var elapsedInPhase: TimeInterval {
        phase == nil ? 0 : max(0, plannedSeconds - engine.remaining)
    }

    // MARK: - 用户操作

    func start(task: FocusTask) {
        if phase != nil { stop() }
        notifications.requestAuthorizationIfNeeded()
        if currentTaskID != task.id {
            focusStreak = 0
        }
        currentTaskID = task.id
        begin(.focus)
    }

    /// 空闲（但保留当前任务）时继续下一个专注，长休息计数不清零。
    func startNextFocus() {
        guard phase == nil, let task = currentTask, !task.isCompleted else { return }
        notifications.requestAuthorizationIfNeeded()
        begin(.focus)
    }

    func pause() {
        engine.pause()
        saveSnapshot()
    }

    func resume() {
        engine.resume()
        saveSnapshot()
    }

    /// 跳过当前阶段：专注阶段按实际已进行时间记账（不算完整番茄）
    func skip() {
        guard phase != nil else { return }
        advancePhase(fully: false)
    }

    /// 结束整个会话，回到空闲；专注阶段的已进行时间照常记账
    func stop() {
        if phase == .focus {
            creditFocus(elapsedSeconds(), fully: false, endedAt: Date())
        }
        reset()
    }

    // MARK: - 阶段推进

    private func begin(_ newPhase: Phase) {
        phase = newPhase
        phaseStartedAt = Date()
        plannedSeconds = duration(for: newPhase)
        engine.start(seconds: plannedSeconds)
        saveSnapshot()
    }

    private func duration(for phase: Phase) -> TimeInterval {
        switch phase {
        case .focus:
            let minutes = currentTask?.focusMinutes ?? settings.defaultFocusMinutes
            return TimeInterval(max(1, minutes) * 60)
        case .shortBreak:
            return TimeInterval(max(1, settings.shortBreakMinutes) * 60)
        case .longBreak:
            return TimeInterval(max(1, settings.longBreakMinutes) * 60)
        }
    }

    private func advancePhase(fully: Bool) {
        guard let current = phase else { return }
        let elapsed = fully ? Int(plannedSeconds) : elapsedSeconds()
        engine.cancel()

        switch current {
        case .focus:
            creditFocus(elapsed, fully: fully, endedAt: Date())
            if fully {
                focusStreak += 1
                if settings.endSoundEnabled { sounds.playFocusEnd() }
                notifications.notifyFocusEnded(
                    taskTitle: currentTask?.title,
                    reachedEstimate: currentTask?.reachedEstimate ?? false,
                    sound: settings.notificationSound
                )
            }
            let next: Phase = focusStreak > 0 && focusStreak.isMultiple(of: settings.longBreakEvery)
                ? .longBreak
                : .shortBreak
            if settings.autoStartBreak {
                begin(next)
            } else {
                becomeIdleKeepingTask()
            }

        case .shortBreak, .longBreak:
            recordRest(elapsed)
            if fully {
                if settings.endSoundEnabled { sounds.playBreakEnd() }
                notifications.notifyBreakEnded(
                    taskTitle: currentTask?.title,
                    sound: settings.notificationSound
                )
            }
            if settings.autoStartNextFocus,
               let task = currentTask, !task.isCompleted, !task.reachedEstimate {
                begin(.focus)
            } else {
                becomeIdleKeepingTask()
            }
        }
    }

    /// 回到空闲但保留任务选择，便于一键继续
    private func becomeIdleKeepingTask() {
        engine.cancel()
        phase = nil
        phaseStartedAt = nil
        plannedSeconds = 0
        store.remove(file: Self.snapshotFile)
    }

    private func reset() {
        becomeIdleKeepingTask()
        currentTaskID = nil
        focusStreak = 0
    }

    private func elapsedSeconds() -> Int {
        max(0, Int((plannedSeconds - engine.remaining).rounded()))
    }

    // MARK: - 记账

    private func creditFocus(_ seconds: Int, fully: Bool, endedAt: Date) {
        guard seconds > 0 else { return }
        if let id = currentTaskID {
            tasks.credit(taskID: id, seconds: seconds, fullPomodoro: fully)
        }
        records.append(PomodoroRecord(
            taskID: currentTaskID,
            taskTitle: currentTask?.title ?? "未命名任务",
            kind: .focus,
            startedAt: phaseStartedAt ?? endedAt.addingTimeInterval(-TimeInterval(seconds)),
            endedAt: endedAt,
            seconds: seconds,
            completedFully: fully
        ))
    }

    private func recordRest(_ seconds: Int) {
        guard seconds > 0 else { return }
        records.append(PomodoroRecord(
            taskID: currentTaskID,
            taskTitle: currentTask?.title ?? "休息",
            kind: .rest,
            startedAt: phaseStartedAt ?? Date(),
            endedAt: Date(),
            seconds: seconds,
            completedFully: false
        ))
    }

    // MARK: - 快照与恢复

    private func saveSnapshot() {
        guard let phase, let phaseStartedAt else {
            store.remove(file: Self.snapshotFile)
            return
        }
        let engineState: Snapshot.EngineState
        switch engine.state {
        case .running(let endDate):
            engineState = .running(endDate: endDate)
        case .paused(let remaining):
            engineState = .paused(remaining: remaining)
        case .idle:
            store.remove(file: Self.snapshotFile)
            return
        }
        store.save(Snapshot(
            phase: phase,
            engineState: engineState,
            taskID: currentTaskID,
            phaseStartedAt: phaseStartedAt,
            plannedSeconds: plannedSeconds,
            focusStreak: focusStreak
        ), to: Self.snapshotFile)
    }

    private func restore() {
        guard let snapshot = store.load(Snapshot.self, from: Self.snapshotFile) else { return }
        currentTaskID = snapshot.taskID
        focusStreak = snapshot.focusStreak
        phaseStartedAt = snapshot.phaseStartedAt
        plannedSeconds = snapshot.plannedSeconds
        phase = snapshot.phase

        switch snapshot.engineState {
        case .paused(let remaining):
            engine.restorePaused(remaining: remaining)
        case .running(let endDate):
            if endDate > Date() {
                engine.resume(until: endDate)
            } else {
                // App 未运行期间该阶段已自然结束：补记账后回到空闲，等用户回来再继续
                if snapshot.phase == .focus {
                    creditFocus(Int(snapshot.plannedSeconds), fully: true, endedAt: endDate)
                    focusStreak += 1
                }
                becomeIdleKeepingTask()
            }
        }
    }
}
