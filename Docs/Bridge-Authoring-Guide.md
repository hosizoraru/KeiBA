# KeiBAOS Bridge 编写指南

更新日期：2026-05-29

## 何时需要 Bridge

SwiftUI 在以下场景表达成本高或能力不足时，引入 UIKit/AppKit bridge：

- 媒体预览（Quick Look、视频播放器、图片缩放）
- 高密度集合布局（`UICollectionViewCompositionalLayout`）
- 富文本渲染（`UITextView` / `NSTextView` read-only）
- 平台原生控件（`NSSearchField`、`NSSavePanel`）
- 系统能力（PiP、AirPlay、拖放）

不需要 bridge 的场景：表单、静态布局、简单交互、数据解析。

## 标准模式

### 1. UIViewRepresentable / NSViewRepresentable

```swift
struct BaPlatformXxxView: View {
    let value: SomeInput
    var onEvent: ((Event) -> Void)?

    var body: some View {
        #if canImport(UIKit)
            BaPlatformXxxRepresentable(value: value, onEvent: onEvent)
        #elseif canImport(AppKit)
            BaPlatformXxxRepresentable(value: value, onEvent: onEvent)
        #else
            // Fallback for unsupported platforms
            Text("Unsupported")
        #endif
    }
}
```

### 2. Coordinator 模式

```swift
#if canImport(UIKit)
private struct BaPlatformXxxRepresentable: UIViewRepresentable {
    let value: SomeInput
    let onEvent: ((Event) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onEvent: onEvent)
    }

    func makeUIView(context: Context) -> SomeUIView {
        let view = SomeUIView()
        view.delegate = context.coordinator
        // Configure view...
        return view
    }

    func updateUIView(_ uiView: SomeUIView, context: Context) {
        context.coordinator.onEvent = onEvent
        // Update view...
    }

    static func dismantleUIView(_ uiView: SomeUIView, coordinator: Coordinator) {
        uiView.delegate = nil
        // Release resources...
    }

    final class Coordinator: NSObject, SomeDelegate {
        var onEvent: ((Event) -> Void)?
        init(onEvent: ((Event) -> Void)?) { self.onEvent = onEvent }
        // Delegate methods...
    }
}
#endif
```

### 3. 必须项清单

| 项目 | 说明 |
|---|---|
| `makeCoordinator()` | 创建 Coordinator，只保存 delegate 和事件 glue |
| `makeUIView/makeNSView` | 创建原生控件，设置 delegate/target-action |
| `updateUIView/updateNSView` | 仅更新变化的属性，避免全量重建 |
| `dismantleUIView/dismantleNSView` | 释放 delegate、player、临时资源 |
| `[weak self]` | Coordinator 闭包中避免循环引用 |
| Accessibility | 所有交互元素必须有 `accessibilityLabel` |
| Dynamic Type | UIKit 使用 `adjustsFontForContentSizeCategory`；SwiftUI 自动 |

### 4. 命名约定

- Bridge 类型：`BaPlatform` 前缀（如 `BaPlatformVideoPlayer`）
- Coordinator：内部 `Coordinator` 类
- 文件位置：`Features/BA/Components/Media/` 或 `Features/BA/Components/Shared/`

### 5. 测试策略

- 单元测试覆盖 Coordinator 逻辑和数据转换
- 构建验证覆盖 `make/update/dismantle` 路径
- 运行时验证覆盖真实 UI 渲染和交互

## 已有 Bridge 速查

| Bridge | 文件 | UIKit | AppKit |
|---|---|---|---|
| Quick Look 预览 | `BaPlatformMediaPreview.swift` | `QLPreviewController` | `QLPreviewView` |
| 图片缩放 | `BaPlatformMediaPreview.swift` | `UIScrollView` + `UIImageView` | `NSScrollView` + `NSImageView` |
| 视频播放 | `BaPlatformVideoPlayer.swift` | `AVPlayerViewController` | `AVPlayerView` |
| GIF 动画 | `BaRemoteAnimatedImageSurface.swift` | `UIImageView` (animated) | `NSImageView` (animates) |
| 富文本 | `BaSelectableRichTextView.swift` | `UITextView` | `NSTextView` |
| 搜索框 | `BaPlatformSearchField.swift` | `UISearchTextField` | `NSSearchField` |
| Collection | `BaTimelineCollectionContainer.swift` | `UICollectionView` | - |
| Collection（影画） | `BaStudentGalleryCards.swift` | `UICollectionView` | - |
