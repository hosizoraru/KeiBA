# KeiBA 性能基线

更新日期：2026-05-29

## 目的

记录 SwiftUI + UIKit/AppKit 混合架构的关键性能指标基线，用于后续对比检测性能退化。

## 测试环境

- iPhone 17 Pro simulator (iOS 26.5)
- iPad Pro 11-inch (M5) simulator (iOS 26.5)
- macOS (Apple Silicon)

## 基线指标

### 启动性能

| 指标 | iPhone | iPad | macOS | 说明 |
|---|---|---|---|---|
| 冷启动到首屏 | < 2s | < 2.5s | < 1.5s | 从 app 启动到总览页可交互 |
| 首次数据加载 | < 3s | < 4s | < 2s | 从启动到 GameKee 数据返回并渲染 |

### 内存使用

| 指标 | iPhone | iPad | macOS | 说明 |
|---|---|---|---|---|
| 基线内存 | < 80MB | < 100MB | < 120MB | 总览页空闲状态 |
| 图鉴页峰值 | < 120MB | < 150MB | < 180MB | 图鉴网格滚动时 |
| 影画预览峰值 | < 150MB | < 180MB | < 200MB | 打开大图/GIF 缩放时 |

### 帧率

| 场景 | 目标 | 说明 |
|---|---|---|
| 列表滚动 | ≥ 55 fps | 活动/卡池/图鉴列表 |
| CollectionView 滚动 | ≥ 55 fps | 影画鉴赏 UICollectionView |
| 媒体预览缩放 | ≥ 50 fps | UIScrollView/NSScrollView pinch zoom |

### 写入/读取

| 指标 | 目标 | 说明 |
|---|---|---|
| 图片缓存命中 | < 5ms | NSCache 内存命中 |
| 图片缓存磁盘命中 | < 50ms | 磁盘读取 + 签名验证 |
| 图片下载+缓存 | < 3s | 首次下载 1MB 以内图片 |

### CollectionView 布局

| 指标 | 目标 | 说明 |
|---|---|---|
| 首次布局 | < 100ms | 影画鉴赏 CollectionView 首次渲染 |
| 更新布局 | < 50ms | DiffableDataSource snapshot 应用 |
| 高度计算 | < 20ms | invalidateLayout + layoutIfNeeded |

## Instruments 检查项

### SwiftUI Body Updates

- 关注：总览页、图鉴页、影画鉴赏页
- 目标：每个页面 body 更新 < 50 个视图
- 告警：单次 body evaluation > 16ms

### Time Profiler

- 关注：主线程最长调用栈
- 目标：无单次调用 > 100ms
- 告警：`UICollectionView.layoutIfNeeded` > 50ms

### Allocations

- 关注：大图解码内存峰值
- 目标：单次解码 < 20MB
- 告警：`CGImage` 分配 > 30MB

### Core Animation FPS

- 关注：滚动帧率
- 目标：≥ 55 fps
- 告警：连续 3 帧 < 30 fps

## 已优化项

| 优化 | 文件 | 效果 |
|---|---|---|
| CollectionView 高度缓存 | `BaStudentGalleryCards.swift`、`BaTimelineCollectionContainer.swift` | 避免冗余 invalidateLayout/layoutIfNeeded |
| DiffableDataSource 去重 | 同上 | `appliedRows == rows` 短路检查 |
| URL 正则缓存 | `BaStudentGalleryMediaLayout.swift` | `NSRegularExpression` 编译一次复用 |
| NSCache 分级限额 | `BaPlatformPerformanceProfile.swift` | phone/pad/desktop 按设备分级 |
| 磁盘缓存清理 | `BaImageCache.swift`、`BaGuideMediaCache.swift` | 7/14 天过期自动清理 |
| ImageIO detached decode | `BaRemoteAnimatedImageSurface.swift` | 解码不阻塞主线程 |

## 测试方法

1. **构建验证**：`xcodebuild test` 全平台 189 测试通过
2. **UI 截图**：iPad Pro 11" 总览页截图验证渲染正确
3. **Instruments**：需要真机或模拟器 GUI 操作
   - 打开 Instruments → Time Profiler
   - 操作关键路径（启动→图鉴→影画→预览→返回）
   - 记录主线程峰值
4. **内存**：Xcode Memory Graph Debugger 检查 bridge 泄漏
