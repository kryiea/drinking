# Spec

## Requirement: HarmonyOS Project Must Be Configured For DevEco Studio 6
仓库 MUST 让 `harmony/` 工程在本机 `DevEco Studio 6` 环境下使用可识别的构建 schema 和 SDK 版本。

### Scenario: Build profile uses HarmonyOS 6 compatible schema
- **WHEN** 协作者查看 `harmony/build-profile.json5`
- **THEN** 顶层配置不再包含旧版 `app.compileSdkVersion`
- **AND** 产品配置使用字符串版 `compatibleSdkVersion` / `targetSdkVersion`

## Requirement: HarmonyOS Build Entry Must Be Verifiable Locally
仓库 MUST 提供可重复执行的 HarmonyOS 构建入口与环境说明。

### Scenario: hvigor tasks can be listed
- **WHEN** 协作者在仓库内执行 `cd harmony && ./hvigorw tasks`
- **THEN** 能成功列出可用任务，而不是停在 schema 配置错误

### Scenario: Environment docs reflect current build status
- **WHEN** 协作者查看 HarmonyOS 环境文档
- **THEN** 能知道当前本机使用的是 `DevEco Studio 6.0.2` 与 `HarmonyOS 6.0.2` SDK
- **AND** 若仍存在剩余编译阻塞，文档会明确记录具体失败点
