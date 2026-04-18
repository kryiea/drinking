# Design

## Summary
本次变更聚焦“让现有鸿蒙工程在本机 `DevEco Studio 6` 环境下真正进入可验证状态”。范围不再是页面骨架，而是构建系统、SDK 版本和仓库文档三件事一起收口。

## Build System
- 继续采用 `Stage + ArkTS`。
- 构建入口使用仓库内 `harmony/hvigorw`，由它转发到 `DevEco Studio 6` 自带的 `Node + hvigor`。
- `harmony/local.properties` 继续指向 `/Applications/DevEco-Studio.app/Contents/sdk`。
- `DEVECO_SDK_HOME` 必须指向 `/Applications/DevEco-Studio.app/Contents/sdk`，不能指到 `sdk/default`。

## SDK Strategy
- 以 `DevEco Studio 6.0.2` 自带的 `HarmonyOS 6.0.2` SDK 为准。
- 根构建配置使用 `HarmonyOS 6` 对应的字符串版 `compatibleSdkVersion` / `targetSdkVersion`。
- 不再保留旧版 `app.compileSdkVersion` 字段。

## Validation Strategy
- 第一层：`./scripts/check-harmony-env.sh` 必须识别到 `DevEco Studio 6` 和其内置 SDK。
- 第二层：`cd harmony && ./hvigorw tasks` 必须可以成功列出任务，证明 schema 与 wrapper 已可用。
- 第三层：继续执行 `cd harmony && ./hvigorw PackageApp`，确保工程可以生成 unsigned `.app` / `.hap` 产物。
- 若仍失败，必须把失败点精确记录到文档；若成功，则把剩余问题收敛到 `signingConfig` 与设备安装验证。

## Documentation Strategy
- `harmony/README.md` 记录当前 DevEco Studio 6 路径、SDK 版本和构建命令。
- `docs/architecture/local-environment.md` 记录本机已安装的 HarmonyOS 6 工具链状态。
- `agent.md` 与 `openspec/README.md` 更新到当前活动变更和真实验证状态。
