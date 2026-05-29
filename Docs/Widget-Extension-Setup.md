# KeiBAOS Widget Extension 配置指南

更新日期：2026-05-29

## 项目现有架构

```
KeiBAOS/                          # 主 app target
KeiBAOSLiveActivities/            # ✅ Live Activity + Dynamic Island（已完成）
KeiBAOSWatch/                     # ✅ Watch app
KeiBAOSWatchWidgets/              # ✅ Watch widgets
KeiBAOSWidgetsShared/             # ✅ 共享 widget 代码（Dashboard widgets）
KeiBAOSTests/                     # ✅ 单元测试（189 个）
```

## 已完成

| 功能 | Target | 状态 |
|---|---|---|
| Live Activity（锁屏/灵动岛） | `KeiBAOSLiveActivities` | ✅ 完整实现 |
| Watch Dashboard Widget | `KeiBAOSWatchWidgets` | ✅ 完整实现 |
| 共享 Widget 组件 | `KeiBAOSWidgetsShared` | ✅ 已有 |

## 待创建：iOS WidgetKit Extension

项目目前缺少 **iOS 端的 WidgetKit Extension**。`KeiBAOSWidgetsShared/` 中的 Dashboard Widget 代码可复用。

### 步骤 1：创建 iOS Widget Extension Target

1. Xcode → File → New → Target
2. 选择 **iOS** → **Widget Extension**
3. Product Name: `KeiBAOSiOSWidgets`
4. Bundle Identifier: `os.kei.KeiBAOS.iOSWidgets`
5. 部署目标: iOS 17.0+
6. 不勾选 "Include Configuration Intent"

### 步骤 2：复用共享 Widget 代码

将 `KeiBAOSWidgetsShared/` 中的文件添加到新 target：

- `BaDashboardWidgets.swift` - Widget 定义
- `BaDashboardWidgetProvider.swift` - Timeline Provider
- `BaDashboardWidgetComponents.swift` - 共享 UI 组件
- `BaDashboardResourceWidgets.swift` - 资源 Widget
- `BaDashboardTimelineWidgets.swift` - 时间线 Widget

### 步骤 3：配置 App Groups

1. 在主 app target 和 iOS Widget target 中都启用 App Groups capability
2. 设置 App Group identifier: `group.os.kei.KeiBAOS`
3. 主 app 通过 `UserDefaults(suiteName:)` 写入数据
4. Widget 通过同一 suite name 读取数据

### 步骤 4：创建 Widget Bundle

在新 target 中创建入口文件：

```swift
import SwiftUI
import WidgetKit

@main
struct KeiBAOSiOSWidgetsBundle: WidgetBundle {
    var body: some Widget {
        BaDashboardResourcesWidget()
        BaDashboardTimelineWidget()
    }
}
```

### 步骤 5：验证

1. 构建主 app 和 iOS Widget target
2. 在 iPhone 模拟器中长按主屏幕 → 添加小组件
3. 搜索 "KeiBAOS" → 验证 Dashboard widgets 显示

## 注意事项

- iOS Widget 需要 iOS 17.0+（`containerBackground` modifier）
- Live Activity 已在 `KeiBAOSLiveActivities` 中实现，无需重复
- `KeiBAOSWidgetsShared/` 是共享代码，Watch 和 iOS widget 都可复用
- App Groups 必须在主 app 和所有 widget target 中都配置
