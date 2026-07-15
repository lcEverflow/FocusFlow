# FocusFlow 🍅

常驻 macOS 菜单栏的「任务管理 + 番茄钟」工具。与普通番茄钟的区别：番茄钟围绕**任务**展开——为任务设定预计总耗时与单次专注时长，系统自动拆分为多个番茄，并累计整体完成进度，适合长期、多任务的工作节奏。

纯原生技术栈：Swift + SwiftUI（`MenuBarExtra`），零第三方依赖。

## 安装 / 运行

**方式零：下载 DMG**

从 [Releases](https://github.com/lcEverflow/FocusFlow/releases) 下载最新 `FocusFlow-x.y.z.dmg`，拖入 Applications 即可。
（Ad-hoc 签名，首次打开如被 Gatekeeper 拦截：右键 → 打开，或 `xattr -dr com.apple.quarantine /Applications/FocusFlow.app`）

**方式一：Xcode（推荐开发者）**

```bash
open FocusFlow.xcodeproj
```

⌘R 直接运行。要求 Xcode 16+ / macOS 14+。

**方式二：仅有 Command Line Tools**

```bash
bash Scripts/build.sh
open build/FocusFlow.app
```

**打包 DMG**

```bash
bash Scripts/make-dmg.sh 1.1.3   # → build/FocusFlow-1.1.3.dmg
```

应用为菜单栏常驻（`LSUIElement`），启动后看菜单栏的 ⏱ 图标，不会出现 Dock 图标和主窗口。

## 已实现功能

- 常驻菜单栏：空闲显示图标；计时中直接显示 `任务名 24:31`（任务名可在设置中关闭）
- 快捷键：弹窗打开时 `⌘W` 收起弹窗、`⌘Q` 退出程序
- 任务管理：新建 / 编辑 / 删除 / 标记完成，优先级（高/中/低）排序
- 任务拆分：按「预计总耗时 ÷ 单次专注时长」自动拆为 N 个番茄，展示 `🍅 2/5` 与整体进度条
- 番茄钟：专注 → 短休息，每 N 个番茄进入长休息；暂停 / 继续 / 跳过 / 结束
- 自动流转：专注结束自动休息、休息结束自动开始下一个专注（均可关闭）
- 系统通知：专注/休息结束提醒（带主题配图：专注🍅 / 休息☕）；任务预计投入达成时特别祝贺；可关提示音
- 结束音效：专注结束"叮"（Glass）、休息结束轻提示（Ping），系统音色零资源，可在设置关闭
- 时间记账：提前结束/跳过的专注也按实际时长记入任务进度（只是不计完整番茄数）
- 统计分析：今日总专注时长/番茄数、近 7 天专注趋势（柱状 + 总计/日均）、今日按任务分布
- 本地持久化：JSON 落盘于 `~/Library/Application Support/FocusFlow/`，人类可读
- 重启恢复：计时快照落盘，重启后恢复运行中/暂停中的计时；App 未运行期间阶段自然结束的，补记账后回到空闲
- 检查更新：启动时（每 24h 一次）+ 设置里手动，查 GitHub Releases 比对版本；有新版则弹通知 + 弹窗顶部提示，一键前往下载（零第三方依赖，非静默自动安装）

## 项目结构

```
FocusFlow/
├── FocusFlow.xcodeproj          # Xcode 16+ 工程（文件夹同步式，加文件零维护）
├── Scripts/build.sh             # 无 Xcode 构建脚本（CLT swiftc → .app）
└── FocusFlow/
    ├── App/
    │   ├── FocusFlowApp.swift       # @main，MenuBarExtra 场景
    │   └── AppEnvironment.swift     # 组合根：装配子系统 + 跨模块门面操作
    ├── Models/                      # 纯数据模型（Codable，无业务依赖）
    │   ├── FocusTask.swift          # 任务：预计耗时、拆分番茄数、进度派生
    │   ├── TaskPriority.swift
    │   └── PomodoroRecord.swift     # 专注/休息记录（append-only）
    ├── Stores/                      # @Observable 状态容器，唯一事实来源
    │   ├── TaskStore.swift
    │   ├── RecordStore.swift        # 含今日统计聚合
    │   └── SettingsStore.swift      # UserDefaults 持久化
    ├── Services/
    │   ├── Persistence/DataStore.swift   # 持久化协议 + JSON 文件实现
    │   ├── Timer/CountdownEngine.swift   # 纯倒计时状态机（墙钟制，不漂移）
    │   ├── Timer/PomodoroController.swift # 番茄钟编排：阶段推进/记账/通知/快照
    │   └── NotificationService.swift
    ├── Views/
    │   ├── MenuBar/                 # 菜单栏标签 + 弹窗根视图 + 计时面板
    │   ├── Home/                    # 主页、任务列表、任务行
    │   ├── Editor/                  # 任务表单
    │   ├── Stats/                   # 今日统计
    │   └── Settings/
    └── Support/TimeFormat.swift
```

## 核心架构

**分层与依赖方向**：`Views → AppEnvironment → Stores/Services → Models`，单向依赖，视图不直接碰持久化。

1. **组合根 `AppEnvironment`**：唯一装配点，通过 SwiftUI `.environment()` 注入。跨子系统的操作（如删除正在计时的任务）必须走它的门面方法，业务规则不散落在视图里。
2. **双层计时**：`CountdownEngine` 是不懂业务的倒计时状态机——基于墙钟 `endDate` 而非 tick 累加，Timer 抖动、卡顿、系统睡眠都不会漂移；`PomodoroController` 负责业务编排：下一阶段是什么、时间记给谁、要不要通知、快照落盘。
3. **持久化抽象 `DataStore`**：协议隔离，当前是 JSON 文件实现；换 SwiftData / CloudKit / 多设备同步只需替换实现，Stores 不动。
4. **状态恢复**：计时现场以 `Snapshot` 落盘（阶段、截止时间、任务、连续番茄数），启动时恢复；已过期的阶段离线补记账。
5. **记账与统计分离**：任务上只存累计值（已投入秒数、完成番茄数），明细以 `PomodoroRecord` append-only 记录，统计从明细聚合——这是后续数据分析/图表的原始数据源。

**关键取舍**
- `@Observable`（macOS 14+）而非 ObservableObject：细粒度依赖追踪，菜单栏每 0.25s 刷新只重绘读了 `remaining` 的视图。
- 提前结束的专注照常记账：目标是「任务总投入」而非「番茄仪式感」，进度不因中断丢失。
- 所有 UI 都在菜单栏弹窗内（含表单/统计/设置的轻量路由），不开主窗口。

## 后续优化建议

- **标签（Tag）**：`FocusTask` 加 `tags: [String]`，列表加过滤即可，模型已预留扩展空间
- **AI 拆解任务**：Editor 中接入 LLM，把大目标拆成子任务序列（结构上只需新增一个 Service）
- **日历 / Obsidian 同步**：基于 `PomodoroRecord` 明细导出（EventKit / Markdown 文件），无需改核心
- **数据分析**：周/月趋势、任务预估准确度（预计 vs 实际），Swift Charts 绘制
- **多设备同步**：`DataStore` 换 CloudKit 实现
- **体验细节**：全局快捷键、勿扰模式联动、菜单栏进度环图标、任务预估超支提醒
