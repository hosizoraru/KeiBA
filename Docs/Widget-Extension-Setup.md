# KeiBA Widget Extension 配置指南

更新日期：2026-05-29

## 项目 Target 架构

```
KeiBA/                          # 主 app target
KeiBAiOSWidgets/                # ✅ iOS WidgetKit Extension（Dashboard widgets）
KeiBAiOSWidgetsExtension/       # iOS Widget Extension 代码目录
KeiBALiveActivities/            # ✅ Live Activity + Dynamic Island
KeiBAWatch/                     # ✅ Watch app
KeiBAWatchWidgets/              # ✅ Watch Dashboard Widget
KeiBATests/                     # ✅ 单元测试（189 个）
```

## 功能覆盖

| 功能 | Target | 状态 |
|---|---|---|
| iOS Dashboard Widget | `KeiBAiOSWidgetsExtension` | ✅ 已创建 |
| Live Activity（锁屏/灵动岛） | `KeiBALiveActivities` | ✅ 完整实现 |
| Watch Dashboard Widget | `KeiBAWatchWidgets` | ✅ 完整实现 |

## 验证步骤

1. 构建主 app：`xcodebuild build -scheme KeiBA`
2. 构建 iOS Widget：确认 `KeiBAiOSWidgetsExtension` 编译通过
3. 在 iPhone 模拟器中长按主屏幕 → 添加小组件
4. 搜索 "KeiBA" → 验证 Dashboard widgets 显示

## 注意事项

- iOS Widget 需要 iOS 17.0+（`containerBackground` modifier）
- Live Activity 已在 `KeiBALiveActivities` 中实现，无需重复
- App Groups (`group.os.kei.KeiBA`) 已在主 app 和 widget extension 中配置
- `KeiBAiOSWidgets/` 包含 iOS 端 Dashboard Widget 源码
