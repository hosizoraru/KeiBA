# KeiBAOS Widget Extension 配置指南

更新日期：2026-05-29

## 项目 Target 架构

```
KeiBAOS/                          # 主 app target
KeiBAOSiOSWidgets/                # ✅ iOS WidgetKit Extension（Dashboard widgets）
KeiBAOSiOSWidgetsExtension/       # iOS Widget Extension 代码目录
KeiBAOSLiveActivities/            # ✅ Live Activity + Dynamic Island
KeiBAOSWatch/                     # ✅ Watch app
KeiBAOSWatchWidgets/              # ✅ Watch Dashboard Widget
KeiBAOSTests/                     # ✅ 单元测试（189 个）
```

## 功能覆盖

| 功能 | Target | 状态 |
|---|---|---|
| iOS Dashboard Widget | `KeiBAOSiOSWidgetsExtension` | ✅ 已创建 |
| Live Activity（锁屏/灵动岛） | `KeiBAOSLiveActivities` | ✅ 完整实现 |
| Watch Dashboard Widget | `KeiBAOSWatchWidgets` | ✅ 完整实现 |

## 验证步骤

1. 构建主 app：`xcodebuild build -scheme KeiBAOS`
2. 构建 iOS Widget：确认 `KeiBAOSiOSWidgetsExtension` 编译通过
3. 在 iPhone 模拟器中长按主屏幕 → 添加小组件
4. 搜索 "KeiBAOS" → 验证 Dashboard widgets 显示

## 注意事项

- iOS Widget 需要 iOS 17.0+（`containerBackground` modifier）
- Live Activity 已在 `KeiBAOSLiveActivities` 中实现，无需重复
- App Groups (`group.os.kei.KeiBAOS`) 已在主 app 和 widget extension 中配置
- `KeiBAOSiOSWidgets/` 包含 iOS 端 Dashboard Widget 源码
