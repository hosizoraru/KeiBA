# KeiBAOS 平台功能路线图

更新日期：2026-05-29

## 目的

追踪 SwiftUI + UIKit/AppKit 混合架构基础上的新平台功能开发。本文件独立于 `SwiftUI-UIKit-AppKit-Interop-Plan`（已完成），专注未来增量功能。

## 依赖关系

本路线图依赖 interop 计划中已建立的基础设施：

- `BaPlatformMediaPreview`：系统媒体预览
- `BaPlatformVideoPlayer`：统一视频播放
- `BaPlatformSearchField`：平台搜索桥接
- `BaSelectableRichTextView`：富文本桥接
- `BaTimelineCollectionContainer` / `BaStudentGalleryCollectionContainer`：CollectionView 容器
- `BaGuideMediaCache` / `BaImageCache`：缓存层

## 功能清单

### F-001：上下文菜单增强

| 属性 | 值 |
|---|---|
| 状态 | **已完成** |
| 优先级 | P1 |
| 平台 | iOS / iPadOS / macOS |
| 范围 | 影画卡片、活动卡片、卡池卡片、图鉴条目 |
| 收益 | 长按/右键快速操作：预览、保存、分享、收藏 |
| 工作量 | 小 |

描述：

为影画、活动、卡池卡片添加 `.contextMenu` 修饰符，提供平台原生的长按/右键菜单。SwiftUI `.contextMenu` 在 iOS/iPadOS/macOS 上自动适配交互方式。

验收标准：

- iOS/iPadOS 长按弹出菜单
- macOS 右键弹出菜单
- 菜单项包含：预览、保存到相册、分享、复制链接
- 菜单图标和文字符合平台惯例

---

### F-002：键盘快捷键增强

| 属性 | 值 |
|---|---|
| 优先级 | P2 |
| 平台 | iPadOS / macOS |
| 范围 | 全局导航 |
| 收益 | 外接键盘时的高效操作 |
| 工作量 | 小 |

描述：

为 iPadOS（外接键盘）和 macOS 添加常用键盘快捷键：

- `Cmd + F`：聚焦搜索框
- `Cmd + R`：刷新数据
- `Cmd + N`：新建收藏
- `Cmd + ,`：打开设置

验收标准：

- iPadOS 外接键盘时快捷键可用
- macOS 菜单栏显示快捷键
- 快捷键不与系统冲突

---

### F-003：WidgetKit 适配

| 属性 | 值 |
|---|---|
| 优先级 | P2 |
| 平台 | iOS / iPadOS |
| 范围 | 主屏幕小组件 |
| 收益 | 快速查看 AP/体力/活动状态 |
| 工作量 | 中 |

描述：

添加 WidgetKit 小组件，显示关键状态信息：

- 小组件（Small）：AP 当前值 + 回复时间
- 中组件（Medium）：AP + 体力 + 下次回复
- 大组件（Large）：活动时间线摘要

需要将关键数据暴露给 Widget 通过 App Groups 或 Widget Center。

验收标准：

- 主屏幕添加小组件正常显示
- 数据每 15 分钟自动刷新
- 深色/浅色模式适配
- 不影响主 app 电量

---

### F-004：Shortcuts / App Intents

| 属性 | 值 |
|---|---|
| 状态 | **已完成** |
| 优先级 | P2 |
| 平台 | iOS / iPadOS / macOS |
| 范围 | Siri 快捷指令 |
| 收益 | 语音触发常用操作 |
| 工作量 | 中 |

描述：

添加 App Intents 支持，让用户通过 Siri 或 Shortcuts app 执行：

- "查看我的 AP"：显示当前 AP 状态
- "查看活动"：显示即将开始的活动
- "查看学生详情"：搜索并显示指定学生

验收标准：

- Shortcuts app 中可发现 KeiBAOS 意图
- Siri 语音触发正常响应
- 意图参数支持学生名称搜索

---

### F-005：Live Activities

| 属性 | 值 |
|---|---|
| 优先级 | P3 |
| 平台 | iOS / iPadOS |
| 范围 | 锁屏 / 灵动岛 |
| 收益 | 实时显示 AP 回复倒计时 |
| 工作量 | 中 |

描述：

添加 Live Activity 显示 AP 回复倒计时，用户无需打开 app 即可查看。

- 灵动岛：显示 AP 回复进度条
- 锁屏：显示剩余时间

验收标准：

- 灵动岛正常显示
- 锁屏小组件正常显示
- AP 回复后自动更新
- 超过 8 小时自动结束

---

### F-006：拖放增强

| 属性 | 值 |
|---|---|
| 优先级 | P3 |
| 平台 | iPadOS / macOS |
| 范围 | 影画图片拖放到其他 app |
| 收益 | 跨应用分享图片 |
| 工作量 | 小 |

描述：

当前 macOS 已支持 `.draggable`。iPadOS 需要添加 `UIDragInteraction` 桥接或使用 SwiftUI `.draggable`（iOS 16+）。

验收标准：

- iPadOS 可拖出图片到 Notes/Messages
- macOS 可拖出图片到 Finder/其他 app
- GIF 拖出时保持动画格式

---

### F-007：SharePlay 集成

| 属性 | 值 |
|---|---|
| 优先级 | P3 |
| 平台 | iOS / iPadOS / macOS |
| 范围 | 共享媒体预览 |
| 收益 | 与朋友一起查看影画 |
| 工作量 | 高 |

描述：

通过 SharePlay 让多个用户同步查看同一媒体内容。需要 GroupActivities 框架集成。

验收标准：

- FaceTime 通话中可共享影画预览
- 多人同步播放/暂停视频
- 参与者可独立缩放图片

---

## 优先级排序

| 优先级 | 功能 | 原因 |
|---|---|---|
| P1 | F-001 上下文菜单 | 投入小，体验提升明显 |
| P2 | F-002 键盘快捷键 | 提升 iPadOS/macOS 效率 |
| P2 | F-003 WidgetKit | 用户高频需求（AP 状态） |
| P2 | F-004 Shortcuts | Siri 生态入口 |
| P3 | F-005 Live Activities | 锁屏体验，但开发成本较高 |
| P3 | F-006 拖放增强 | macOS 已完成，iPadOS 补齐 |
| P3 | F-007 SharePlay | 协作场景，需求频次较低 |

## 平台适配检查表

| 功能 | iOS | iPadOS | macOS | watchOS |
|---|---|---|---|---|
| F-001 上下文菜单 | ✅ | ✅ | ✅ | - |
| F-002 键盘快捷键 | - | ✅ | ✅ | - |
| F-003 WidgetKit | ✅ | ✅ | - | - |
| F-004 Shortcuts | ✅ | ✅ | ✅ | - |
| F-005 Live Activities | ✅ | ✅ | - | - |
| F-006 拖放增强 | - | ✅ | ✅ (已完成) | - |
| F-007 SharePlay | ✅ | ✅ | ✅ | - |

## 技术依赖

| 功能 | 框架 | 最低版本 |
|---|---|---|
| F-001 | SwiftUI `.contextMenu` | iOS 14 / macOS 11 |
| F-002 | SwiftUI `.keyboardShortcut` | iOS 15 / macOS 12 |
| F-003 | WidgetKit | iOS 14 / macOS 11 |
| F-004 | App Intents | iOS 16 / macOS 13 |
| F-005 | ActivityKit | iOS 16.1 |
| F-006 | SwiftUI `.draggable` | iOS 16 / macOS 13 |
| F-007 | GroupActivities | iOS 15 / macOS 12 |
