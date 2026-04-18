# Design

## Summary
先完成“仓库层面的端入口建设”，而不是直接跳到 HarmonyOS 工程实现。这样可以在不打乱当前 iOS 主线的前提下，为后续鸿蒙适配保留清晰的目录与文档落点。

## Directory Decision
- 目录名采用 `harmony/`
- 原因：
  - 与 `ios/`、`backend/` 的 ASCII 命名风格一致
  - 便于脚本、CI、跨平台工具和未来文档引用
  - 避免在工程工具链中使用中文目录名带来的不确定性

## Initial Contents
- `harmony/README.md`
  - 说明这是鸿蒙端根目录
  - 记录当前只完成根目录 bootstrap
  - 预留后续推荐结构和架构约束

## Documentation Impact
- `README.md`
  - 仓库结构中加入 `harmony/`
- `agent.md`
  - 模块地图与下一步任务中识别鸿蒙端根目录已建立
- `openspec/README.md`
  - 将 `harmony-root-bootstrap` 纳入当前有效的文档治理 / 平台入口变更

## Follow-up
- 后续真正开始 HarmonyOS 适配时，应单开新的 OpenSpec change，至少覆盖：
  - DevEco / ArkTS 工程初始化方案
  - 本地存储与同步策略
  - 与 iOS 共享的领域模型边界
  - 页面优先级与 MVP 范围
