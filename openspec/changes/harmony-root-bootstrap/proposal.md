# Proposal

## Why
- 仓库已经明确把 HarmonyOS 适配列为后续方向，但当前根目录还没有明确的鸿蒙端入口。
- 如果继续在没有端根目录的情况下讨论鸿蒙适配，后续文档、脚本和工程文件容易散落，增加 AI 持续接手成本。

## What Changes
- 在仓库根目录新增 `harmony/`，作为鸿蒙端的正式根目录。
- 在 `harmony/README.md` 中定义当前阶段、后续建议结构和工程约束。
- 同步更新 `agent.md`、`README.md` 和 `openspec/README.md`，让仓库导航正式识别鸿蒙端入口。

## Non-Goals
- 本次不初始化 DevEco Studio 工程。
- 本次不实现 HarmonyOS 页面、同步、网络或构建脚本。
- 本次不改变当前 iOS 与后端的主开发重心。
