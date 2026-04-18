# Spec

## Requirement: HarmonyOS App Root Must Contain A Real Stage Project Skeleton
仓库 MUST 在 `harmony/` 下提供可继续扩展的 HarmonyOS `Stage + ArkTS` 工程骨架，而不是只有占位目录。

### Scenario: Stage project files exist
- **WHEN** 协作者查看 `harmony/`
- **THEN** 能看到 `AppScope`、`entry`、顶层 build 配置和 ArkTS 源码目录

## Requirement: HarmonyOS Must Mirror The Current Four-Tab Information Architecture
HarmonyOS 端 MUST 提供与当前 iOS 主体验一致的四个一级区块。

### Scenario: Top-level tabs exist
- **WHEN** 协作者查看 HarmonyOS 端主页面源码
- **THEN** 能看到 `首页`、`记录`、`分析`、`我的` 四个一级区块

## Requirement: HarmonyOS Must Keep Local-First Caffeine Logic
HarmonyOS 端 MUST 本地实现咖啡因 / 入睡影响的确定性计算。

### Scenario: Local forecast logic exists
- **WHEN** 协作者查看 HarmonyOS 端领域代码
- **THEN** 能看到本地咖啡因剩余量、入睡残留和建议入睡时间的计算函数

### Scenario: Local calculator exists
- **WHEN** 协作者查看 HarmonyOS 端记录相关源码
- **THEN** 能看到手冲 / 意式 / 胶囊的本地咖啡因计算能力

## Requirement: HarmonyOS Environment Setup Must Be Reproducible
仓库 MUST 记录 HarmonyOS 命令行工具的可复用安装与验证方式。

### Scenario: Environment scripts exist
- **WHEN** 协作者查看 `scripts/`
- **THEN** 能找到 HarmonyOS CLI 安装或检查脚本

### Scenario: Environment status is documented
- **WHEN** 协作者查看本地环境文档
- **THEN** 能知道当前已安装的 HarmonyOS CLI 路径以及剩余 SDK 下载阻塞
