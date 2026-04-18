# Design

## Summary
本次采用“先对齐架构与页面骨架，再逐步补齐系统能力”的方式推进 HarmonyOS 适配。工程目标不是做一个演示目录，而是建立可以继续迭代的 ArkTS 工程入口，并把当前 iOS MVP 的核心体验迁过去。

## Platform Architecture
- 目录：`harmony/`
- 工程模型：`Stage + ArkTS`
- 当前平台定位：
  - `iOS` 仍是当前最成熟实现
  - `HarmonyOS` 进入正式实现阶段
  - 两端都遵守“本地优先、后端辅助”的架构路线

## Feature Mapping

### 首页
- 对齐 iOS 的“今晚状态页”结构：
  - 当前体内咖啡因
  - 入睡时预计残留
  - 从现在到入睡的紧凑时间视图
  - 最近记录
  - 底部 `记一杯`

### 记录页
- 对齐 iOS 的记录主路径：
  - 搜索
  - 快捷操作 strip
  - 品牌 rail
  - 最近 / 我的饮品 / 品牌目录
  - 直接点一行即记录
- HarmonyOS 首版对语音 / 拍照 / 相册入口先提供 UI 落点和占位反馈，等待后续系统能力接线

### 咖啡因计算器
- 对齐 iOS 的答案页结构：
  - 冲煮方式切换
  - 参数卡
  - 估算结果
  - `存为我的饮品` / `记这一杯`

### 分析页
- 对齐 iOS 当前的极简分析表达：
  - 现在值
  - 入睡值
  - 时间视图
  - 今日事件

### 我的
- 保持多级设置的信息层级，但首轮先以内联分组卡片实现：
  - 入睡时间
  - 代谢速度
  - 同步状态说明
  - 我的饮品
  - 开发连接说明

## Data Strategy
- HarmonyOS 端当前使用本地 fixture + 本地状态编排，延续本地优先方向。
- 咖啡因计算、入睡预测与品牌 starter pack 直接迁移为 ArkTS 领域代码。
- 本地持久化先建立明确 seam，并通过文档记录下一步将接入正式 Preferences / database 存储。

## Environment Strategy
- 通过 `scripts/setup-harmony-cli.sh` 安装官方 HarmonyOS 命令行工具到用户目录：
  - `sdkmgr`
  - `ohpm`
  - `codelinter`
- 不修改宿主机 VPN / 系统代理。
- 截至 `2026-04-18`，公开可直接下载的稳定 `DevEco Studio 3.1` 官方说明仍覆盖 `HarmonyOS 3.1 及以下`；`HarmonyOS 6` 需走当前 Beta / preview 通道。
- 当前已知阻塞：`sdkmgr install toolchains:9` 在本机返回 `Could not found download url`，需要后续继续处理官方 SDK 下载链路。

## Validation
- 当前优先验证：
  - Harmony CLI 可执行
  - 工程目录结构完整
  - ArkTS 源码已生成
  - 仓库文档已同步识别 HarmonyOS 端
- 在 SDK 下载链路修通前，不承诺完成最终编译验证
