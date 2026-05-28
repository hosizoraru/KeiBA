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

### Phase 1：统一系统媒体预览

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

### Phase 2：Zoomable 媒体表面

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

### Phase 3：影画鉴赏集合视图试点

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

### Phase 4：活动/卡池大屏容器评估

策略：

- iPhone 保留现有 SwiftUI List。
- iPad/macOS 仅在宽度达到阈值时启用 collection view bridge。
- 复用现有 `BaActivityRowDisplayModel` / `BaPoolRowDisplayModel`，保持数据链路干净。

验收：

- iPad 11 寸侧边栏、顶栏、台前调度窗口均能稳定多列。
- 活动图片完整显示，卡池学生头像无截断误导。
- 摘要区和列表区滚动不互相影响。

### Phase 5：技能/档案富文本桥接

策略：

- 先做 read-only `BaRichTextView`，输入为 `AttributedString` 或 sanitized HTML。
- 技能术语 icon 通过 attachment 或 HTML img token 渲染。
- 档案长文本启用选择/复制，保留 SwiftUI card 外壳。

验收：

- 日奈(礼服)技能描述 icon 齐全。
- 长技能描述换行自然，动态字体可读。
- 复制内容保留文本语义。

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

## 追踪表

| ID | 任务 | 状态 | 目标文件 | 备注 |
| --- | --- | --- | --- | --- |
| INTEROP-001 | 建立 Quick Look 媒体预览桥 | 已完成 | `Features/BA/Components/Media/BaPlatformMediaPreview.swift` | 已接入影画与互动家具预览；远程媒体先下载到本地文件，再交给 iOS/iPadOS Quick Look 或 macOS Quick Look view |
| INTEROP-002 | 建立 Zoomable 图片/GIF bridge | 已完成 | `Features/BA/Components/Media/BaPlatformMediaPreview.swift` | 已作为 Quick Look 不可用时的本地图片 fallback；UIKit/AppKit 均支持双击缩放与恢复 |
| INTEROP-003 | 影画鉴赏 CollectionView 试点 | 已完成 | `Features/BA/Students/BaStudentGalleryCards.swift` | iPadOS 第一版已接入非滚动 UICollectionView，cell 继续承载现有 SwiftUI 卡片；完整测试通过 |
| INTEROP-004 | 活动/卡池 iPad 宽屏 CollectionView 评估 | 已完成 | `Features/BA/Timeline/` | 第一版接入共享非滚动 UICollectionView 容器，数据模型复用现有 snapshot；完整测试通过 |
| INTEROP-005 | 技能富文本 read-only bridge | 待办 | `Features/BA/Students/` | 优先术语 icon baseline |
| INTEROP-006 | 档案长文本选择/复制 bridge | 待办 | `Features/BA/Students/` | 与技能富文本共用基础组件 |
| INTEROP-007 | macOS Quick Look / 保存面板优化 | 待办 | `Features/BA/Components/Media/` | AppKit responder/window 边界 |
| INTEROP-008 | SwiftUIIntrospect 小范围评估 | 待办 | 待定 | 只用于搜索、List、ScrollView 微调 |
| INTEROP-009 | SDWebImageSwiftUI 依赖评估 | 待办 | Package / project settings | 当前 GIF bridge 数据不足时启用 |

## 风险与约束

- Bridge 生命周期由 SwiftUI 驱动，`make/update/dismantle` 必须可重复执行。
- Coordinator 只保存 delegate 和事件 glue，业务状态继续由 SwiftUI/Observable service 拥有。
- CollectionView/Quick Look 引入后，accessibility label、Dynamic Type、VoiceOver 顺序需要单独验证。
- SwiftUIIntrospect 需要显式覆盖平台版本，升级 iOS/iPadOS/macOS 大版本时要更新版本声明。
- 第三方依赖需要锁定最新稳定版，并记录替代方案和回滚路径。

## 推荐路线

先落 `INTEROP-001` 和 `INTEROP-002`，因为它们直接覆盖影画鉴赏、互动家具、学生档案、媒体预览多个痛点，收益最大且边界清晰。随后用影画鉴赏作为 `UICollectionViewCompositionalLayout` 试点，再决定活动/卡池是否迁移到同一容器。

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
