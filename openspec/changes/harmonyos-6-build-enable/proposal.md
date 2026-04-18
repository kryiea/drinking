# Proposal

## Why
- HarmonyOS 端已经有 `Stage + ArkTS` 工程骨架和页面代码，但还没有在本机的 `DevEco Studio 6` 环境下完成真实构建接线。
- 当前阻塞已经从“没有 SDK”收敛成“工程配置仍停留在旧版 schema”，需要一次专门的构建修复，把项目正式对齐 `HarmonyOS 6`。
- 如果不把这一步补齐，鸿蒙端会一直停留在“代码存在但无法验证”的状态，无法进入后续 UI 对齐和系统能力适配。

## What Changes
- 将 `harmony/` 顶层构建配置升级为 `DevEco Studio 6 / HarmonyOS 6.0.2` 可识别的 schema。
- 明确使用本机 `DevEco Studio 6` 自带 SDK，并补齐项目构建入口。
- 修复当前阻塞构建的工程配置问题，至少跑通 `hvigor tasks`，并尽可能推进到 `assembleHap`。
- 更新 HarmonyOS 环境文档、项目地图和 OpenSpec 导航，记录当前真实可验证状态。

## Non-Goals
- 本次不承诺所有 HarmonyOS 系统能力已经接入完成。
- 本次不要求鸿蒙端和 iOS 在每一个视觉细节上完全一致。
- 本次不引入新的后端或跨端架构路线调整。
