import AppKit

/// 阶段结束音效（参考 TomatoBar 的 ding 体验）。
/// 用系统内置音色（/System/Library/Sounds），零打包资源、零第三方依赖；
/// 后续要换自定义音频时，把实现改为 AVAudioPlayer + bundle 资源即可。
final class SoundService {
    /// 专注结束：清脆的"叮"
    func playFocusEnd() {
        play("Glass")
    }

    /// 休息结束：轻提示音
    func playBreakEnd() {
        play("Ping")
    }

    private func play(_ name: String) {
        NSSound(named: name)?.play()
    }
}
