# KeiBA

[![CI][ci-badge]][ci-workflow] ![Platforms][platforms-badge] ![Swift][swift-badge]

[English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

KeiBA 是面向 Blue Archive 玩家的一款原生 Apple 平台伴侣 App。Blue
Archive 在中文社区里常见称呼包括“蔚蓝档案”（国服官方名）、“碧蓝档案”（早期和社区常用名）
以及简称 BA。KeiBA 围绕老师每天最常打开的 BA 场景构建：AP 与咖啡厅 AP、日程和活动、
招募卡池、学生档案、记忆大厅 BGM、提醒、小组件、Live Activities 和 Apple Watch 快速查看。

项目仍在活跃开发中。主 App 覆盖 iOS、iPadOS 和 macOS 26；watchOS 伴侣、
WidgetKit 小组件和 Live Activities 与主项目放在同一个仓库里，并纳入本地验证和 CI
路径。当前功能会优先服务日服、国际服以及中文玩家常见的 BA 工作流，同时尽量保持
Apple 平台上的原生交互习惯。

## 本地化和术语

BA 在不同服区和社区里存在不少译名差异。KeiBA 的文档和 UI 会尽量贴近玩家实际说法：

- 中文说明会优先使用“老师、学生、夏莱、咖啡厅、招募、战术对抗赛、记忆大厅”等常见词。
- “蔚蓝档案”和“碧蓝档案”都会被尊重；前者更接近国服官方名，后者在中文社区和旧资料里仍然常见。
- “奇普托斯 / 基沃托斯”“夏莱 / 沙勒”等译名会按当前页面语境处理，不为了统一而牺牲可读性。
- 数据说明会尽量说清来自公开攻略资料或 GameKee 风格数据，而不是暗示这是官方服务。

## 功能亮点

- 总览 AP、咖啡厅 AP、每日重置、咖啡厅访问、摸头、邀请券、战术对抗赛刷新、老师身份和
  多服务器档案，减少“上线前还要算一下”的心智负担。
- 浏览当前和即将开始的活动、招募卡池与日程时间线，数据来自公开 BA 攻略资料。
- 搜索学生、NPC 和卫星角色资料，查看档案、技能、武器、画廊媒体、语音和相关展示信息。
- 播放收藏学生的记忆大厅 BGM，支持本地音频缓存和系统媒体控制。
- 规划本地提醒，并通过 Live Activities / Dynamic Island 展示关键进度，例如 AP 回复或活动倒计时。
- 使用 iOS 小组件和 watchOS Smart Stack 快速查看 AP、咖啡厅 AP、活动和招募状态。
- 通过 WatchConnectivity 把 iPhone 上的紧凑仪表盘快照同步到 Apple Watch。
- 维护英文、日文、简体中文界面文案，并尽量贴近各服区 BA 玩家实际使用的术语。

## 平台覆盖

| 平台或入口 | 状态 | 说明 |
| --- | --- | --- |
| iPhone | 活跃开发 | 主要日常入口，覆盖总览、图鉴、音乐、通知、小组件和 Live Activities。 |
| iPad | 活跃开发 | 与主 App 共用目标，针对大窗口、指针、键盘和分栏体验做适配。 |
| Mac | 活跃开发 | 从主 App 目标构建，关注 macOS 工具栏、侧边栏、键盘、指针和窗口行为。 |
| Apple Watch | 开发中 | 提供老师仪表盘、Smart Stack 小组件、通知状态、AP 和日程摘要。 |
| 小组件 | 活跃开发 | iOS 仪表盘小组件和 watchOS Smart Stack 读取共享仪表盘快照。 |
| Live Activities | 活跃开发 | 在支持的设备上把提醒进度展示到锁屏和 Dynamic Island。 |

## 仓库结构

| 路径 | 用途 |
| --- | --- |
| `KeiBA/` | 主 App 源码、BA 功能模块、共享 UI、资源、Localization 和支持代码。 |
| `KeiBAShared/` | 主 App 与 Live Activities 扩展共享的类型。 |
| `KeiBALiveActivities/` | Live Activities、锁屏和 Dynamic Island 展示扩展。 |
| `KeiBAiOSWidgets/` | iOS WidgetKit 仪表盘小组件。 |
| `KeiBAWatch/` | watchOS 伴侣 App。 |
| `KeiBAWatchShared/` | iPhone、Watch 和小组件共享的 Codable 仪表盘快照模型。 |
| `KeiBAWatchWidgets/` | watchOS WidgetKit / Smart Stack 扩展。 |
| `KeiBATests/` | 解析、设置、通知、媒体、小组件、Watch 快照和布局单元测试。 |
| `Docs/` | 功能覆盖、平台路线图、UIKit/AppKit 互操作、Widget 设置和性能基线。 |
| `scripts/` | 本地维护和 CI 辅助脚本。 |

## 环境要求

| 工具或平台 | 基线 |
| --- | --- |
| Xcode | 本地开发建议使用 Xcode 26.5 或更新版本。 |
| SDK | iOS 26.5、iOS Simulator 26.5、macOS 26.5、watchOS 26.5。 |
| 部署目标 | iOS 26.0+、iPadOS 26.0+、macOS 26.0+、watchOS 26.0+。 |
| 工程格式 | Xcode 26.3 project format，`objectVersion` 100。 |
| 技术栈 | Swift、SwiftUI、Swift Concurrency、Observation、WidgetKit、ActivityKit、App Intents、WatchConnectivity、Swift Package Manager。 |

Swift Package 依赖通过 Xcode project 解析，锁定在提交的 `Package.resolved` 中：

- [AudioStreaming](https://github.com/dimitris-c/AudioStreaming.git)
- [ogg-binary-xcframework](https://github.com/sbooth/ogg-binary-xcframework)
- [vorbis-binary-xcframework][vorbis-binary-xcframework]

## 本地构建

使用 Xcode 26.5 或更新版本打开 `KeiBA.xcodeproj`，选择 `KeiBA` scheme，然后在
iOS 26 模拟器、iPadOS 26 模拟器、macOS 26 或已签名的实体 iPhone/iPad 上运行。
选择 `KeiBAWatch` scheme 可构建 watchOS 伴侣 App。

命令行示例：

```sh
xcodebuild build \
  -project KeiBA.xcodeproj \
  -scheme KeiBA \
  -destination 'generic/platform=iOS Simulator'

xcodebuild build \
  -project KeiBA.xcodeproj \
  -scheme KeiBA \
  -destination 'generic/platform=macOS'

xcodebuild build \
  -project KeiBA.xcodeproj \
  -scheme KeiBAWatch \
  -destination 'generic/platform=watchOS Simulator'
```

在实体 iPhone 或 iPad 上安装 Release 版本：

1. 选择 `KeiBA` scheme 和目标设备。
2. 打开 `Product > Scheme > Edit Scheme...`。
3. 在 `Run > Info` 中把 `Build Configuration` 改成 `Release`。
4. 确认 App、Widget/Live Activities 扩展、Watch App 和 Watch Widget 扩展都配置了
   Apple Team。
5. 使用 `Product > Run` 构建、签名、安装并启动 Release 版本。

需要生成可分发构建时，选择 `Any iOS Device (arm64)`，使用 `Product > Archive`，
再在 Organizer 中按需要的 Apple 签名方式导出。

## 测试和验证

快速本地检查：

```sh
jq empty KeiBA/Localizable.xcstrings
jq empty KeiBALiveActivities/Localizable.xcstrings
jq empty KeiBAWatch/Localizable.xcstrings
jq empty KeiBAWatchWidgets/Localizable.xcstrings
git diff --check
```

单元测试：

```sh
xcodebuild test \
  -project KeiBA.xcodeproj \
  -scheme KeiBA \
  -destination 'platform=macOS'
```

聚焦图鉴筛选测试：

```sh
xcodebuild test \
  -project KeiBA.xcodeproj \
  -scheme KeiBA \
  -destination 'platform=macOS' \
  -only-testing:KeiBATests/BaCatalogFilterTests
```

涉及可见 UI 的改动，应在对应模拟器或实体设备上验证，并在 PR 中附截图或录屏。本
checkout 的本地 agent 验证习惯是使用 Build iOS Apps 的浏览器内模拟器镜像：

- project: `KeiBA.xcodeproj`
- scheme: `KeiBA`
- bundle id: `os.kei.KeiBA`
- simulator: `iPhone 17 Pro`

## CI 和构建产物

GitHub Actions 会在 `macos-26` 上运行本地化校验、iOS 模拟器构建与测试、watchOS
模拟器构建、macOS 构建与测试、Watch/Widget 快照测试、用户数据同步测试，以及未签名
打包任务。

推送到 `main` 和手动触发 workflow 时，会上传侧载测试用产物：

- `KeiBA-iOS-<version>-unsigned.ipa`
- `KeiBA-macOS-<version>-unsigned.dmg`

这些产物未签名，适合本地冒烟测试或后续重新签名，不是已经 notarize、TestFlight 或
App Store 可直接发布的包。

只修改 README、Docs 或 GitHub community 文件时，CI 会通过路径过滤跳过 App 构建，
避免浪费 macOS 构建时间。

## 版本策略

KeiBA 把 Apple bundle 版本和 CI 构建产物名分开管理：

- `MARKETING_VERSION` / `CFBundleShortVersionString` 使用 `1.0.0` 这类三段式版本。
- `CURRENT_PROJECT_VERSION` / `CFBundleVersion` 在 CI 中使用仓库 commit 数。
- 非 tag 构建的 CI 产物名会追加 git 元信息，例如 `1.0.1-162.g6d0c346`；App bundle
  内部仍保持 Apple 兼容的版本字段。

CI 版本解析脚本会读取最新合并的语义化 tag（`v1.2.3` 或 `1.2.3`）。tag 构建使用该
发布版本；tag 之后的构建使用下一个 patch 版本，并在产物名中加入 commit 距离和短 SHA。

## 数据和隐私

KeiBA 读取公开 Blue Archive / BA 攻略数据。Blue Archive 名称、角色、美术、音乐、
语音和相关游戏素材归各自权利方所有。BA 日服官网可见于
[bluearchive.jp](https://bluearchive.jp)；KeiBA 不是官方 App，也不提供账号、课金或游戏
服务器支持。

App 当前会在本地保存用户偏好，包括办公室设置、收藏、缓存媒体元数据、Watch 仪表盘
快照、同步的看板学生头像缩略图、Widget 仪表盘快照和通知偏好。未来 iCloud 同步工作
应保持同步载荷小而明确，并支持用户主动重置。

安全问题请看 [SECURITY.md](SECURITY.md)，普通问题报告请看 [SUPPORT.md](SUPPORT.md)。

## 贡献

贡献应保持小而聚焦，并尊重 Apple 平台差异。开始前请阅读
[CONTRIBUTING.md](CONTRIBUTING.md)，PR 中写清验证命令；可见 UI 改动请附对应平台的
模拟器或设备截图。

相关项目文档：

- [BA 功能覆盖](Docs/BAFeatureCoverage.md)
- [平台功能路线图](Docs/Platform-Features-Roadmap.md)
- [SwiftUI / UIKit / AppKit 互操作计划](Docs/SwiftUI-UIKit-AppKit-Interop-Plan.md)
- [Widget 扩展设置](Docs/Widget-Extension-Setup.md)
- [性能基线](Docs/Performance-Baselines.md)

## License

License 尚未最终选择。在添加 license 前，本仓库所有权利由仓库所有者保留。

[ci-badge]: https://github.com/hosizoraru/KeiBA/actions/workflows/ci.yml/badge.svg
[ci-workflow]: https://github.com/hosizoraru/KeiBA/actions/workflows/ci.yml
[platforms-badge]: https://img.shields.io/badge/platforms-iOS%20%7C%20iPadOS%20%7C%20macOS%20%7C%20watchOS-0a7ea4
[swift-badge]: https://img.shields.io/badge/Swift-6-orange
[vorbis-binary-xcframework]: https://github.com/sbooth/vorbis-binary-xcframework
