# Spec

## Requirement: HarmonyOS Root Directory
仓库 MUST 在根目录提供一个明确、可追踪的鸿蒙端根目录。

### Scenario: Root directory exists
- **WHEN** 协作者查看仓库根目录
- **THEN** 可以看到 `harmony/` 作为鸿蒙端入口

### Scenario: Harmony root is documented
- **WHEN** 协作者进入 `harmony/`
- **THEN** 可以通过 `harmony/README.md` 了解当前阶段、后续建议结构和基本约束

## Requirement: HarmonyOS Root Must Be Reflected In Repo Navigation
仓库导航文档 MUST 识别鸿蒙端根目录已经建立。

### Scenario: Root README includes harmony
- **WHEN** 协作者阅读根目录 `README.md`
- **THEN** 能在仓库结构中看到 `harmony/`

### Scenario: Project map includes harmony
- **WHEN** 协作者阅读 `agent.md`
- **THEN** 能在模块地图或下一步任务中看到鸿蒙端根目录已经建立
