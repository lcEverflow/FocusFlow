import Foundation
import Observation

/// 纯倒计时状态机：只负责计时，不含任何番茄钟业务语义。
///
/// 计时基于墙钟 endDate 而非 tick 累加——tick 只用来刷新 UI 和探测到期，
/// 因此 Timer 抖动、App 卡顿甚至系统睡眠都不会让计时漂移。
@MainActor
@Observable
final class CountdownEngine {
    enum State: Equatable {
        case idle
        case running(endDate: Date)
        case paused(remaining: TimeInterval)
    }

    private(set) var state: State = .idle
    private(set) var now: Date = Date()

    @ObservationIgnored var onFinished: (@MainActor () -> Void)?
    @ObservationIgnored private var timer: Timer?

    var remaining: TimeInterval {
        switch state {
        case .idle:
            return 0
        case .running(let endDate):
            return max(0, endDate.timeIntervalSince(now))
        case .paused(let remaining):
            return remaining
        }
    }

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    func start(seconds: TimeInterval) {
        now = Date()
        state = .running(endDate: now.addingTimeInterval(seconds))
        startTicking()
    }

    /// 恢复到既有截止时间（重启恢复场景）
    func resume(until endDate: Date) {
        now = Date()
        state = .running(endDate: endDate)
        startTicking()
    }

    func pause() {
        guard isRunning else { return }
        let left = remaining
        stopTicking()
        state = .paused(remaining: left)
    }

    func resume() {
        guard case .paused(let left) = state else { return }
        start(seconds: left)
    }

    func restorePaused(remaining: TimeInterval) {
        stopTicking()
        state = .paused(remaining: remaining)
    }

    func cancel() {
        stopTicking()
        state = .idle
    }

    private func startTicking() {
        stopTicking()
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTicking() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        now = Date()
        if case .running(let endDate) = state, now >= endDate {
            stopTicking()
            state = .idle
            onFinished?()
        }
    }
}
