# 饮知 HarmonyOS 端

这个目录现在已经不是占位目录，而是 `饮知` 的 HarmonyOS `Stage + ArkTS` 工程根目录，而且已经在本机 `DevEco Studio 6.0.2 + HarmonyOS 6.0.2` 环境下跑通了 `PackageApp`。

## 当前已完成
- `Stage + ArkTS` 工程骨架
- `首页 / 记录 / 分析 / 我的` 四个一级页面
- 本地饮品 starter pack
- 本地咖啡因衰减与入睡预测
- 本地咖啡因计算器
- 本地快照 store seam
- HarmonyOS CLI 环境脚本

## 当前目录
- `AppScope/`: 应用元信息
- `entry/`: 主 module 与 ArkTS 源码
- `build-profile.json5`: 顶层构建配置
- `hvigor/`、`hvigorfile.ts`: 构建入口占位
- `oh-package.json5`: 工程包描述

## 当前验证结果
- 已通过：
  - `cd harmony && ./hvigorw tasks`
  - `cd harmony && ./hvigorw PackageApp`
- 当前产物：
  - `harmony/build/outputs/default/harmony-default-unsigned.app`
  - `harmony/entry/build/default/outputs/default/entry-default-unsigned.hap`
  - `harmony/entry/build/default/outputs/default/app/entry-default.hap`
- 当前签名状态：
  - `PackageApp` 已成功，但默认 product 还没有 `signingConfig`
  - 因此当前是可打包、未正式签名的本地产物

## 本机环境
- 官方 HarmonyOS CLI 已安装到：
  - `/Users/luca/.harmony/tools/commandline-tools/command-line-tools/`
- 可用工具：
  - `sdkmgr`
  - `ohpm`
  - `codelinter`
- 仓库脚本：
  - `./scripts/setup-harmony-cli.sh`
  - `./scripts/check-harmony-env.sh`
  - `./scripts/prepare-harmony-project.sh`
- SDK 路径模板：
  - `harmony/local.properties.example`
- 构建入口：
  - `harmony/hvigorw`
- 当前有效的 DevEco SDK 根：
  - `/Applications/DevEco-Studio.app/Contents/sdk`
- 当前有效的环境变量：
  - `DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk`

## 当前已知边界
- 当前本机可以正常执行：
  - `sdkmgr list`
  - `ohpm ping`
  - `codelinter --help`
  - `cd harmony && ./hvigorw tasks`
  - `cd harmony && ./hvigorw PackageApp`
- 当前仓库已经完成 HarmonyOS 6 的工程 schema、`modelVersion`、SDK 根路径和 ArkTS 兼容性修复。
- 公开 Harmony CLI 的 `sdkmgr` 视野仍停留在旧通道，直接安装 HarmonyOS 6 组件并不稳定；当前可用构建依赖的是 `DevEco Studio 6.0.2` 自带的 SDK 根。
- 当前剩余工作主要是：
  - 配置正式 `signingConfig`
  - 连接真机 / 模拟器做安装验证
  - 继续补系统能力与交互细节

## 约束
- HarmonyOS 端继续遵守“本地优先、后端辅助”
- 当前先对齐 iOS MVP 的页面结构与核心计算，不把系统能力接线当作第一步
- 相机 / 语音 / 相册 / 正式同步后续继续补齐
