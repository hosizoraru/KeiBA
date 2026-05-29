# KeiBAOS Widget Extension 配置指南

更新日期：2026-05-29

## 概述

KeiBAOS 已准备好 WidgetKit 和 Live Activity 的 Swift 源码，需要在 Xcode 中创建 Extension target 来编译和运行。

## 文件位置

```
KeiBAOSWidget/
├── BaAPStatusWidget/
│   └── BaAPStatusWidget.swift    # WidgetKit 小组件（AP 状态）
└── BaAPActivity/
    └── BaAPActivity.swift         # Live Activity（锁屏/灵动岛）
```

## 步骤 1：创建 Widget Extension Target

1. Xcode → File → New → Target
2. 选择 iOS → Widget Extension
3. Product Name: `KeiBAOSWidget`
4. Bundle Identifier: `os.kei.KeiBAOS.widget`
5. 部署目标: iOS 17.0+
6. 不勾选 "Include Configuration Intent"
7. 完成后删除模板生成的 `KeiBAOSWidget.swift` 和 `KeiBAOSWidgetBundle.swift`

## 步骤 2：添加源文件

1. 将 `KeiBAOSWidget/BaAPStatusWidget/BaAPStatusWidget.swift` 拖入项目
2. 将 `KeiBAOSWidget/BaAPActivity/BaAPActivity.swift` 拖入项目
3. 确保两个文件都属于 `KeiBAOSWidget` target

## 步骤 3：配置 App Groups

Widget 和主 app 需要通过 App Groups 共享数据。

1. 在主 app target 和 widget target 中都启用 App Groups capability
2. 设置 App Group identifier: `group.os.kei.KeiBAOS`
3. 在主 app 中通过 `UserDefaults(suiteName:)` 写入 AP 数据
4. 在 widget 中通过同一 suite name 读取数据

## 步骤 4：配置 Live Activity（可选）

1. 在主 app target 中启用 Background Modes → Live Activities
2. 在 widget target 中启用 Live Activities capability
3. 使用 `ActivityKit` 请求开始 Live Activity：

```swift
import ActivityKit

func startAPActivity() {
    let attributes = BaAPActivityAttributes(apLimit: "240")
    let state = BaAPActivityAttributes.ContentState(
        apCurrent: "240",
        apLimit: "240",
        nextRecovery: "6 min"
    )
    do {
        let activity = try Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil)
        )
    } catch {
        print("Failed to start activity: \(error)")
    }
}
```

## 步骤 5：验证

1. 构建主 app 和 widget target
2. 在模拟器中长按主屏幕 → 添加小组件
3. 搜索 "KeiBAOS" → 选择 AP Status 小组件
4. 验证小组件显示 AP 数据

## 注意事项

- Widget 需要 iOS 17.0+（`containerBackground` modifier）
- Live Activity 需要 iOS 16.1+
- App Groups 必须在两个 target 中都配置
- Widget 数据通过 `UserDefaults` 或 `SwiftData` 共享
- Live Activity 的 `staleDate` 应设为 AP 回满时间
