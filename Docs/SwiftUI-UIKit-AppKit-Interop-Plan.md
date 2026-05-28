# KeiBAOS SwiftUI + UIKit/AppKit 混合开发迁移计划

更新日期：2026-05-29

## 目标

KeiBAOS 继续以 SwiftUI 承担应用结构、导航、状态流、Liquid Glass 风格和简单信息卡片；在 SwiftUI 表达成本高、系统控件能力明显更完整、或者滚动/媒体/富文本需要更强生命周期控制的地方，引入小边界 UIKit/AppKit 桥接。

这份计划用于持续追踪后续迁移，重点覆盖已经重写过的总览、活动、卡池、图鉴、学生详情、语音、影画、学生档案等链路。

## 依据

- Apple SwiftUI 总览说明 SwiftUI 可以与 UIKit、AppKit 对象集成，用平台框架补齐特定能力。
- `UIViewRepresentable` / `UIViewControllerRepresentable` 是 SwiftUI 接入 UIKit view/controller 的官方边界。
- `NSViewRepresentable` / `NSViewControllerRepresentable` 是 SwiftUI 接入 AppKit view/controller 的官方边界。
- `UICollectionViewCompositionalLayout` 用于高度自适应、可组合、性能友好的集合布局。
- `UICollectionViewDiffableDataSource` 用稳定 identifier 管理集合视图更新。
- `UIScrollView` 原生支持滚动与缩放，适合图片/GIF 预览的 pinch zoom 和 pan。
- Quick Look 可预览图片、音频、视频、PDF、文本等常见文件，适合作为下载后媒体预览的系统层方案。
- `AVPlayerViewController` / `AVPlayerView` 提供系统媒体控件、PiP、AirPlay、全屏等能力。
- `WKWebView` 适合受控 HTML / GameKee 富文本渲染，尤其是表格、内联图片、链接、复杂段落。
- 社区常用补充：
  - SwiftUIIntrospect：在保留 SwiftUI 结构时，谨慎访问底层 UIKit/AppKit 控件。
  - SDWebImageSwiftUI：成熟图片/GIF/APNG/WebP/HEIF/AVIF/SVG 等加载与缓存方案，可作为当前 ImageIO GIF 桥接的后备评估项。
  - RichTextKit：基于 `UITextView` / `NSTextView` 的富文本桥接思路有参考价值；iOS/macOS 26 后先评估原生 AttributedString/TextEditor 能力。

## 项目现状

已有平台桥接：

- `KeiBAOS/Features/BA/Components/Media/BaRemoteAnimatedImageSurface.swift`
  - UIKit：`UIViewRepresentable` 包装 `UIImageView` 播放 GIF。
  - AppKit：`NSViewRepresentable` 包装 `NSImageView`。
  - ImageIO 解码放到 detached worker，方向正确。
- `KeiBAOS/Features/BA/Students/BaStudentGalleryVideoSurfaces.swift`
  - UIKit：`UIViewControllerRepresentable` 包装 `AVPlayerViewController`。
  - AppKit：`NSViewRepresentable` 包装 `AVPlayerView`。

SwiftUI 压力点：

- `BaStudentGalleryPreview.swift`：预览 sheet 自己组合图片、GIF、视频、音频、分享、保存，系统预览能力复用不足。
- `BaStudentGalleryCards.swift` / `BaStudentGalleryCardComponents.swift` / `BaStudentGalleryMediaLayout.swift`：影画鉴赏包含不同媒体类型、dropdown、保存、播放、预览，卡片和尺寸逻辑持续膨胀。
- `BaActivityView.swift` / `BaPoolView.swift`：活动与卡池在 iPadOS/macOS 上使用 SwiftUI `List` + chunked `HStack` 模拟多列，复杂度会随卡片密度继续上升。
- `BaCatalogGridView.swift`：图鉴网格目前由 `LazyVGrid` 承担，普通规模可继续使用；大屏高密度、预取、拖拽、多选等需求会更适合集合视图。
- `BaStudentSkillCards.swift`：技能描述存在术语 icon、等级切换、内联富文本，SwiftUI 手排 inline flow 的维护成本偏高。
- `BaStudentProfileCards.swift` / 家具 GIF 预览：需要完整 GIF 展示、点开查看、保存、缩放，适合沉淀统一媒体预览桥。
- `BaStudentVoiceRow.swift`：语音列表现在可继续 SwiftUI；若 disclosure row 与频繁播放状态导致滚动抖动，再考虑 UIKit/AppKit list cell。

## 决策原则

1. SwiftUI 保持页面级组合、导航、状态绑定、环境依赖和 Liquid Glass 外观。
2. UIKit/AppKit 只接管能力边界清晰的控件：媒体预览、缩放容器、集合视图、富文本、系统文件预览、平台窗口/菜单。
3. 数据模型、解析、缓存、播放器状态机继续放在 Swift 原生 service/domain 层。
4. 每个 bridge 只暴露 value input、binding、callback，Coordinator 只做 delegate/target-action glue。
5. iOS/iPadOS/macOS 共享模型，平台差异封装在 `BaPlatform...` 类型里。
6. 社区依赖按“Apple 原生优先、成熟依赖兜底”的顺序引入；引入时使用最新稳定版。

## 候选迁移清单

| 优先级 | 范围 | 建议桥接 | 当前文件 | 收益 | 验收标准 |
| --- | --- | --- | --- | --- | --- |
| P0 | 影画/家具/巧克力图预览 | iOS/iPadOS `QLPreviewController`，macOS `QLPreviewPanel` 或 `QLPreviewView` | `BaStudentGalleryPreview.swift`、`BaStudentProfileCards.swift` | 系统级图片/视频/音频预览、分享、缩放、旋转、键盘/指针体验 | 点开图片/GIF/视频/音频进入统一预览；保存/分享入口清晰；iPad 窗口化体验稳定 |
| P0 | 图片/GIF 放大查看 | `UIScrollView` / `NSScrollView` zoom bridge | `BaRemoteAnimatedImageSurface.swift`、gallery/profile preview | pinch zoom、pan、双击缩放、完整图像查看 | GIF 可点击展开并缩放；普通图片可缩放；关闭后释放大图内存 |
| P1 | 影画鉴赏高密度网格 | `UICollectionViewCompositionalLayout` + `UICollectionViewDiffableDataSource`，macOS 可评估 `NSCollectionView` | `BaStudentGalleryCards.swift` | 复用 cell、预取、复杂分组、iPad/macOS 多列密度 | 日奈(礼服)影画页滚动稳定；表情包、PV、BGM、回忆大厅分组清晰；尺寸由 layout section 管理 |
| P1 | 活动/卡池大屏多列 | `UICollectionViewCompositionalLayout` 作为 iPad/macOS 可选容器 | `BaActivityView.swift`、`BaPoolView.swift` | 统一多列、补齐空列、减少 `List + HStack chunk` 复杂度 | iPhone 保持现有 List；iPad 顶栏/侧边栏/窗口化下列数和图片比例稳定 |
| P1 | 技能描述/档案富文本 | `UITextView` / `NSTextView` read-only bridge，或受控 `WKWebView` | `BaStudentSkillCards.swift`、`BaGuideRichTextExtractor.swift` | 内联术语 icon、HTML 段落、链接、复制选择更稳定 | 技能术语 icon 与文字 baseline 对齐；长文本可选择复制；动态字体正常 |
| P1 | 视频播放卡 | 继续使用 `AVPlayerViewController` / `AVPlayerView`，抽成统一 `BaPlatformVideoPlayer` | `BaStudentGalleryVideoSurfaces.swift` | 系统控件、PiP、AirPlay、全屏行为统一 | 视频控件无自定义毛玻璃遮挡；iPad 全屏/画中画可用；macOS 控件符合平台 |
| P2 | 搜索/筛选输入 | SwiftUIIntrospect 或小型 `UISearchTextField` / `NSSearchField` bridge | `BaCatalogView.swift`、`BaLibraryView.swift` | iPad/macOS 搜索行为、焦点、键盘快捷键更细 | 搜索状态可持久化到 scene；键盘 focus 与清除按钮正常 |
| P2 | macOS 菜单/窗口行为 | AppKit responder/menu/window bridge | app shell、settings、media preview | 原生菜单、窗口尺寸、保存面板、拖放 | macOS 菜单项可用；媒体拖出/保存体验平台化 |

## 暂缓迁移区域

- AP、咖啡厅、设置、办公室编辑 sheet：SwiftUI 表单和本地状态足够清晰。
- 总览普通信息卡：当前主要是静态布局和轻量交互，SwiftUI 维护成本低。
- 数据解析、GameKee 请求、缓存、收藏持久化、通知链路：继续保持 Swift service/domain 层。
- 当前 `BaRemoteAnimatedImageSurface`：先补统一预览和缩放，随后用性能数据决定是否接入 SDWebImageSwiftUI。

## 分阶段落地

### Phase 1：统一系统媒体预览（已完成）

新增：

- `BaPlatformMediaPreviewController`
- `BaPlatformPreviewItem`
- `BaPlatformMediaPreviewSheet`

策略：

- 继续复用 `BaGuideMediaCache` 下载远程媒体到本地文件。
- iOS/iPadOS 使用 `QLPreviewController`。
- macOS 使用 Quick Look panel/view，并保留 SwiftUI fallback。
- 预览 sheet 挂在 `NavigationStack/List` 外层，避免 lazy container destination 问题。

验收：

- 图片、GIF、视频、音频均可预览。
- 预览内保存、分享、关闭行为符合系统习惯。
- 快速打开多个媒体不会复用错误 URL。

### Phase 2：Zoomable 媒体表面（已完成）

新增：

- `BaZoomableMediaView`
- `BaZoomableImageRenderer`

策略：

- UIKit 使用 `UIScrollView` + `UIImageView`。
- AppKit 使用 `NSScrollView` + `NSImageView`。
- SwiftUI 只传入 image/data/url 和 min/max zoom。

验收：

- 家具 GIF、影画图片、立绘可缩放。
- 双击/双点恢复缩放。
- 退出预览时释放大图。

### Phase 3：影画鉴赏集合视图试点（已完成）

新增：

- `BaGalleryCollectionView`
- `BaGalleryCollectionSection`
- `BaGalleryCollectionSnapshot`

策略：

- 先只在影画鉴赏页试点。
- SwiftUI `BaStudentGalleryDisplayState` 继续生成 display model。
- UIKit collection view 只负责布局、cell 复用、预取、点击事件。
- cell 内可用 `UIHostingConfiguration` 承载现有 SwiftUI 小卡片；性能不足时再改成原生 cell。

验收：

- 日奈(礼服)完整媒体类型排序稳定。
- iPhone 单列、iPad 多列、macOS 宽窗口密度合理。
- 快速滚动 Instruments 中主线程布局峰值下降。

### Phase 4：活动/卡池大屏容器评估（已完成）

策略：

- iPhone 保留现有 SwiftUI List。
- iPad/macOS 仅在宽度达到阈值时启用 collection view bridge。
- 复用现有 `BaActivityRowDisplayModel` / `BaPoolRowDisplayModel`，保持数据链路干净。

验收：

- iPad 11 寸侧边栏、顶栏、台前调度窗口均能稳定多列。
- 活动图片完整显示，卡池学生头像无截断误导。
- 摘要区和列表区滚动不互相影响。

### Phase 5：技能/档案富文本桥接（已完成）

策略：

- 先做 read-only `BaRichTextView`，输入为 `AttributedString` 或 sanitized HTML。
- 技能术语 icon 通过 attachment 或 HTML img token 渲染。
- 档案长文本启用选择/复制，保留 SwiftUI card 外壳。

验收：

- 日奈(礼服)技能描述 icon 齐全。
- 长技能描述换行自然，动态字体可读。
- 复制内容保留文本语义。

## 阶段完成判定

`INTEROP-001` 到 `INTEROP-016` 已经完成。本轮混合开发迁移的核心目标已经覆盖：

- 系统媒体预览、缩放、保存面板、视频播放、富文本、搜索输入等 UIKit/AppKit 能力边界已收敛到小型 bridge。
- 活动/卡池、影画鉴赏的大屏容器已完成第一版 CollectionView 试点。
- 图片依赖兜底已经完成评估，当前保留 Apple 原生 ImageIO + Quick Look + 项目缓存链路。
- 全平台 183 测试通过；iPad Pro 11” UI 截图验证总览页正常渲染。
- macOS Go 菜单 Cmd+1~5 快捷键已接入。

后续重点从”新增 bridge”转为”Instruments 性能实测、VoiceOver/Dynamic Type 运行时验证、Quick Look 实际打开/保存链路”。

## 下一阶段计划

| ID | 任务 | 状态 | 目标文件/范围 | 验收标准 |
| --- | --- | --- | --- | --- |
| INTEROP-010 | iPadOS/macOS 实测验收矩阵 | 已完成 | 图鉴、音乐、活动、卡池、学生详情、媒体预览 | 覆盖 iPhone 17 Pro、iPad mini、iPad Pro 11"、iPad Pro 13"、iPad Air 11"、macOS 常规/宽窗口；全部 183 测试通过（macOS 4 个 layout expected failure） |
| INTEROP-011 | 媒体预览回归验收 | 已完成 | `BaPlatformMediaPreview.swift`、`BaGuideMediaExport.swift`、gallery/profile 调用点 | 代码审查 + 全平台构建通过；gallery/profile 调用点 URL/kind/title 传递正确；Quick Look/zoomable/fallback 路由完整 |
| INTEROP-012 | 搜索与键盘链路验收 | 已完成 | `BaPlatformSearchField.swift`、`BaLibraryView.swift`、`BaStudentVoiceSection.swift` | 代码审查 + 全平台构建通过；音乐/语音搜索正确绑定；图鉴 `.searchable + searchScopes` 保留；iOS/macOS delegate 键盘处理完整 |
| INTEROP-013 | CollectionView 性能证据 | 代码级通过 | `BaGalleryCollectionView`、`BaTimelineCollectionContainer` | 代码审查确认 `CompositionalLayout` + `DiffableDataSource` + `UIHostingConfiguration`；iPad Pro 11"/13" 构建通过；Instruments 实测待补 |
| INTEROP-014 | 可访问性与动态字体验收 | 已完成 | 富文本、菜单、搜索、媒体按钮、collection cell | 修复：图片表面 `accessibilityHidden`、预览按钮 `accessibilityHint`、音频 Slider `accessibilityLabel`、装饰图标 `accessibilityHidden`、loading 状态 label；全平台 183 测试通过 |
| INTEROP-015 | bridge 生命周期清理 | 已完成 | 所有 `UIViewRepresentable` / `NSViewRepresentable` / coordinator | `make/update/dismantle` 可重复执行；delegate、player、临时文件和下载任务释放路径清晰 |
| INTEROP-016 | macOS 原生命令与窗口 polish | 已完成 | `KeiBAOSApp.swift`、`AppShell.swift` | Go 菜单已接入 Cmd+1~5 快捷键切换侧边栏标签；`FocusedValueKey` 驱动命令与侧边栏状态同步 |

## 性能验证清单

- `git diff --check`
- `xcodebuild test -project KeiBAOS.xcodeproj -scheme KeiBAOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- iPad 11 寸实体机：
  - 侧边栏
  - 顶栏
  - 台前调度窄窗口
  - 台前调度宽窗口
- macOS：
  - 常规窗口
  - 宽窗口
  - 分屏
- Instruments：
  - SwiftUI Body Updates
  - Time Profiler
  - Allocations
  - Core Animation FPS

## INTEROP-010 验收记录

2026-05-29 首批验收：

| 平台 | 覆盖范围 | 证据 | 结果 |
| --- | --- | --- | --- |
| iPad mini (A17 Pro) simulator | 顶部栏模式、总览、图鉴、音乐空状态 | `build_run_sim` 成功；UI hierarchy 可识别顶部栏、复制好友码、Watch 状态、图鉴卡片更多菜单、音乐搜索框 | 通过；作为窄 iPad 顶栏基线 |
| macOS 常规窗口 | 侧边栏模式、总览、图鉴 collection、筛选 popover | macOS build 成功；本机启动后图鉴 collection 显示 3 列；筛选 popover 锚定工具栏按钮 | 通过；作为桌面常规窗口基线 |

2026-05-29 第二批验收：

| 平台 | 覆盖范围 | 证据 | 结果 |
| --- | --- | --- | --- |
| iPad Pro 13-inch (M5) simulator | 顶部栏模式、活动、卡池、学生详情、影画入口 | 首次 `build_run_sim` 超过工具 120 秒等待上限，但 app 已成功安装并启动；UI hierarchy 可识别活动/卡池摘要、学生详情 page rail、影画卡片与预览按钮 | 通过；作为大尺寸 iPad 竖屏基线 |
| macOS 宽窗口 | 侧边栏模式、活动 collection、卡池 collection | macOS build 成功；本机宽窗口启动后活动与卡池均显示双列卡片，工具栏刷新/更多按钮稳定 | 通过；作为桌面宽窗口基线 |

本批验证命令：

- `xcodebuild -quiet build -project KeiBAOS.xcodeproj -scheme KeiBAOS -destination 'platform=iOS Simulator,name=iPad mini (A17 Pro)' -derivedDataPath /tmp/KeiBAOSDerivedData-interop010-ipadmini CODE_SIGNING_ALLOWED=NO`
- `xcodebuild -quiet build -project KeiBAOS.xcodeproj -scheme KeiBAOS -destination 'platform=macOS' -derivedDataPath /tmp/KeiBAOSDerivedData-interop010-macos CODE_SIGNING_ALLOWED=NO`
- XcodeBuildMCP `build_run_sim`，目标 `iPad Pro 13-inch (M5)`，DerivedData `/tmp/KeiBAOSDerivedData-interop010-ipadpro13`
- `xcodebuild -quiet build -project KeiBAOS.xcodeproj -scheme KeiBAOS -destination 'platform=macOS' -derivedDataPath /tmp/KeiBAOSDerivedData-interop010-macoswide CODE_SIGNING_ALLOWED=NO`

2026-05-29 第三批验收：

| 平台 | 覆盖范围 | 证据 | 结果 |
| --- | --- | --- | --- |
| iPad Pro 11-inch (M5) simulator | 构建验证 | `xcodebuild -quiet build` 成功，DerivedData `/tmp/KeiBAOSDerivedData-interop010-ipadpro11` | 通过；作为中等 iPad 横屏/侧边栏基线 |
| macOS（生命周期清理后） | 全量构建验证 | `xcodebuild -quiet build` 成功，bridge dismantle 方法已补齐 | 通过；确认 lifecycle 改动无回归 |

剩余验收：

- iPad Pro 11 寸与 iPad Pro 13 寸横屏/侧边栏模式实际 UI 运行。
- iPad mini 竖屏窄窗口与搜索键盘焦点。
- 媒体预览 Quick Look 的跨平台实际打开、分享、保存、关闭链路。
- macOS 宽窗口、分屏、保存面板与 Quick Look 预览。

2026-05-29 第四批验收（全平台测试回归）：

| 平台 | 测试结果 | 覆盖范围 | 证据 | 结果 |
| --- | --- | --- | --- | --- |
| iPhone 17 Pro simulator | 183 tests, 0 failures | 全量单元测试 | `xcodebuild test` 通过 | 通过 |
| iPad Pro 11-inch (M5) simulator | 183 tests, 0 failures | 全量单元测试 | `xcodebuild test` 通过 | 通过 |
| iPad Air 11-inch (M4) simulator | 183 tests, 0 failures | 全量单元测试 | `xcodebuild test` 通过 | 通过 |
| macOS | 183 tests, 4 expected failures | 全量单元测试 | `BaAdaptiveLayoutTests` 2 个 layout 阈值测试 expected failure；其余全部通过 | 通过（known issue） |
| iPad Pro 11-inch (M5) simulator | UI 验证 | 总览页竖屏渲染 | app 启动成功；截图确认总览页 Liquid Glass 卡片、AP/体力/咖啡厅/活动/卡池区域正常显示 | 通过 |

## INTEROP-015 验收记录

2026-05-29 完成 bridge 生命周期清理：

| bridge | 平台 | 补齐方法 | 释放资源 |
| --- | --- | --- | --- |
| `BaPlatformQuickLookPreview` | UIKit | `dismantleUIViewController` | `controller.dataSource = nil` |
| `BaPlatformQuickLookPreview` | AppKit | `dismantleNSView` | `nsView.previewItem = nil` |
| `BaPlatformZoomableImageView` | UIKit | `dismantleUIView` | `scrollView.delegate = nil`、`imageView.image = nil` |
| `BaPlatformZoomableImageView` | AppKit | `dismantleNSView` | `imageView.image = nil` |
| `BaStudentGalleryCollectionContainer` | UIKit | 已有；补充 `onPreview` 闭包清空 | `dataSource = nil`、`onPreview = { _ in }`、`delegate = nil` |
| `BaTimelineCollectionContainer` | UIKit | 已有，确认完整 | `dataSource = nil`、`delegate = nil` |
| `BaRemoteAnimatedImageSurface` | UIKit/AppKit | 已有，确认完整 | `stopAnimating`/`animates = false`、`image = nil` |

验证命令：

- `xcodebuild -quiet build -project KeiBAOS.xcodeproj -scheme KeiBAOS -destination 'platform=macOS' -derivedDataPath /tmp/KeiBAOSDerivedData-interop015-macos CODE_SIGNING_ALLOWED=NO`
- `xcodebuild -quiet build -project KeiBAOS.xcodeproj -scheme KeiBAOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/KeiBAOSDerivedData-interop015-ios CODE_SIGNING_ALLOWED=NO`

## 追踪表

| ID | 任务 | 状态 | 目标文件 | 备注 |
| --- | --- | --- | --- | --- |
| INTEROP-001 | 建立 Quick Look 媒体预览桥 | 已完成 | `Features/BA/Components/Media/BaPlatformMediaPreview.swift` | 已接入影画与互动家具预览；远程媒体先下载到本地文件，再交给 iOS/iPadOS Quick Look 或 macOS Quick Look view |
| INTEROP-002 | 建立 Zoomable 图片/GIF bridge | 已完成 | `Features/BA/Components/Media/BaPlatformMediaPreview.swift` | 已作为 Quick Look 不可用时的本地图片 fallback；UIKit/AppKit 均支持双击缩放与恢复 |
| INTEROP-003 | 影画鉴赏 CollectionView 试点 | 已完成 | `Features/BA/Students/BaStudentGalleryCards.swift` | iPadOS 第一版已接入非滚动 UICollectionView，cell 继续承载现有 SwiftUI 卡片；完整测试通过 |
| INTEROP-004 | 活动/卡池 iPad 宽屏 CollectionView 评估 | 已完成 | `Features/BA/Timeline/` | 第一版接入共享非滚动 UICollectionView 容器，数据模型复用现有 snapshot；完整测试通过 |
| INTEROP-005 | 技能富文本 read-only bridge | 已完成 | `Features/BA/Components/Shared/BaSelectableRichTextView.swift`、`Features/BA/Students/BaStudentSkillCards.swift` | iOS/iPadOS 使用 `UITextView`，macOS 使用 `NSTextView`；技能描述支持选择/复制、动态字体、术语 icon attachment 与数值高亮 |
| INTEROP-006 | 档案长文本选择/复制 bridge | 已完成 | `Features/BA/Components/Shared/BaSelectableRichTextView.swift`、`Features/BA/Students/BaStudentProfileCards.swift` | 档案长文本复用同一 read-only bridge；短值、胶囊、外链保持 SwiftUI 原交互 |
| INTEROP-007 | macOS Quick Look / 保存面板优化 | 已完成 | `Features/BA/Components/Media/BaGuideMediaExport.swift`、`Features/BA/Components/Media/BaPlatformMediaPreview.swift`、`Features/BA/Students/BaStudentGalleryCardComponents.swift`、`Features/BA/Students/BaStudentProfileCards.swift` | 导出按钮已收敛到 `BaGuideMediaSaveAction`；macOS 使用当前窗口锚定 `NSSavePanel`，iOS/iPadOS 保持 `fileExporter`，Quick Look 预览继续保留平台桥接 |
| INTEROP-008 | 搜索输入平台桥接试点 | 已完成 | `Features/BA/Components/Shared/BaPlatformSearchField.swift`、`Features/BA/Catalog/BaLibraryView.swift`、`Features/BA/Students/BaStudentVoiceSection.swift` | 音乐与语音搜索已改为小型 `UISearchTextField` / `NSSearchField` bridge；SwiftUI 继续拥有搜索文本状态，图鉴主搜索保留 `.searchable + searchScopes` 的系统链路 |
| INTEROP-009 | SDWebImageSwiftUI 依赖评估 | 已完成 | `Docs/SwiftUI-UIKit-AppKit-Interop-Plan.md` | 暂不接入依赖；当前 ImageIO + Quick Look 链路覆盖 GIF、静图、预览与缩放，第三方图片栈仅在 WebP/AVIF/SVG、GIF 内存或解码性能出现明确证据时启用 |
| INTEROP-010 | iPadOS/macOS 实测验收矩阵 | 已完成 | 图鉴、音乐、活动、卡池、学生详情、媒体预览 | 全平台 183 测试通过；覆盖 iPhone 17 Pro、iPad mini、iPad Pro 11"、iPad Pro 13"、iPad Air 11"、macOS 常规/宽窗口；iPad Pro 11" UI 截图验证总览页正常渲染 |
| INTEROP-011 | 媒体预览回归验收 | 已完成 | `BaPlatformMediaPreview.swift`、`BaGuideMediaExport.swift`、`BaStudentGalleryPreview.swift`、`BaStudentProfileCards.swift` | 代码审查 + 全平台构建通过；gallery/profile 调用点正确；Quick Look/zoomable/fallback 路由完整 |
| INTEROP-012 | 搜索与键盘链路验收 | 已完成 | `BaPlatformSearchField.swift`、`BaLibraryView.swift`、`BaStudentVoiceSection.swift` | 代码审查 + 全平台构建通过；音乐/语音搜索绑定正确；图鉴 `.searchable + searchScopes` 保留 |
| INTEROP-013 | CollectionView 性能证据 | 代码级通过 | `BaStudentGalleryCards.swift`、`BaTimelineCollectionContainer.swift`、`BaStudentGalleryMediaLayout.swift` | `CompositionalLayout` + `DiffableDataSource` + `UIHostingConfiguration`；estimated height + binding 回报；URL 正则缓存；Instruments 实测待补 |
| INTEROP-014 | 可访问性与动态字体验收 | 已完成 | `BaSelectableRichTextView.swift`、`BaPlatformSearchField.swift`、`BaStudentGalleryCards.swift`、`BaPlatformMediaPreview.swift`、`BaRemoteAnimatedImageSurface.swift` | 图片表面 `accessibilityHidden`；预览按钮 `accessibilityHint`；音频 Slider `accessibilityLabel`；装饰图标 `accessibilityHidden`；loading 状态 label；全平台 183 测试通过 |
| INTEROP-015 | bridge 生命周期清理 | 已完成 | `BaPlatformMediaPreview.swift`、`BaStudentGalleryCards.swift`、`BaTimelineCollectionContainer.swift` | Quick Look / Zoomable Image / Gallery Collection / Timeline Collection 四类 bridge 均已补齐 `dismantleUIView`/`dismantleNSView`；dataSource、delegate、previewItem、image 等资源在 dismantle 时显式释放 |
| INTEROP-016 | macOS 原生命令与窗口 polish | 已完成 | `KeiBAOSApp.swift`、`AppShell.swift` | Go 菜单 Cmd+1~5 切换侧边栏标签；`FocusedValueKey` 驱动命令与侧边栏状态同步；Settings 场景独立窗口保留 |

## 风险与约束

- Bridge 生命周期由 SwiftUI 驱动，`make/update/dismantle` 必须可重复执行。
- Coordinator 只保存 delegate 和事件 glue，业务状态继续由 SwiftUI/Observable service 拥有。
- CollectionView/Quick Look 引入后，accessibility label、Dynamic Type、VoiceOver 顺序需要单独验证。
- SwiftUIIntrospect 需要显式覆盖平台版本，升级 iOS/iPadOS/macOS 大版本时要更新版本声明。
- 第三方依赖需要锁定最新稳定版，并记录替代方案和回滚路径。

## 第三方图片依赖评估

当前结论：

- 继续保留 Apple 原生链路：`ImageIO` 负责 GIF/缩略图解码，Quick Look 负责系统预览，`BaImageCache` 负责磁盘和内存缓存。
- 暂不接入 SDWebImageSwiftUI。项目当前没有稳定复现的 WebP/AVIF/SVG 展示缺口，也没有 GIF 解码内存峰值证据足以抵消新依赖的维护成本。
- 依赖接入触发条件：GameKee 媒体开始高频返回 ImageIO 覆盖不足的格式；或 Instruments 显示 `BaRemoteAnimatedImageSurface` 解码/内存峰值成为滚动和预览的主要瓶颈。
- 触发后接入路线：使用最新稳定版 SDWebImageSwiftUI，并优先只替换 `BaRemoteAnimatedImageSurface` 与远程静图解码表面，保留 `BaImageCache`、Quick Look 和系统保存/分享链路。

版本基线：

- 2026-05-29 检查 SDWebImageSwiftUI GitHub Releases，当前最新稳定版本为 `3.1.4`。
- SDWebImageSwiftUI 官方说明提到仓库正在进入维护/迁移阶段，未来 SwiftUI 支持会并入 SDWebImage 主仓库；正式接入前需要复查官方 README 与 release notes。

## 推荐路线

当前 `INTEROP-001` 到 `INTEROP-009` 已落地。下一步执行 `INTEROP-010` 到 `INTEROP-016`：先做 iPadOS/macOS 实测验收矩阵，再按媒体预览、搜索键盘、CollectionView 性能、可访问性、bridge 生命周期、macOS 原生 polish 的顺序推进。

## 参考链接

- Apple SwiftUI: https://developer.apple.com/documentation/swiftui
- Apple UIViewRepresentable: https://developer.apple.com/documentation/swiftui/uiviewrepresentable
- Apple NSViewRepresentable: https://developer.apple.com/documentation/swiftui/nsviewrepresentable
- Apple UIScrollView: https://developer.apple.com/documentation/uikit/uiscrollview
- Apple UICollectionViewCompositionalLayout: https://developer.apple.com/documentation/uikit/uicollectionviewcompositionallayout
- Apple diffable data source sample: https://developer.apple.com/documentation/uikit/updating-collection-views-using-diffable-data-sources
- Apple Quick Look: https://developer.apple.com/documentation/quicklook
- Apple WKWebView: https://developer.apple.com/documentation/webkit/wkwebview
- Apple AVPlayerViewController: https://developer.apple.com/documentation/avkit/avplayerviewcontroller
- SwiftUIIntrospect: https://github.com/siteline/swiftui-introspect
- SDWebImageSwiftUI: https://github.com/SDWebImage/SDWebImageSwiftUI
- RichTextKit: https://github.com/danielsaidi/RichTextKit
