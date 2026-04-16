# Design: Local-First Architecture Alignment

## Goal
将仓库的正式架构叙事统一为：
- `iOS App + 本地持久化` 是核心产品系统
- `SyncProvider + iCloud/CloudKit` 是 Apple 生态内同步策略
- `Backend` 是辅助系统，而不是默认业务真源

## Route Definition

### 主系统
- 用户日志
- 用户设置
- 个人饮品模板
- 咖啡因与入睡相关的确定性计算
- 离线记录与展示

这些能力必须在无后端连接时仍可使用。

### 同步系统
- Apple 生态优先使用 `SyncProvider`
- 当前已落地 `ICloudKeyValueSyncProvider / LocalOnlySyncProvider`
- 将来若出现跨生态同步需求，再通过新的 provider 接回服务端

### 辅助后端
- 品牌目录 seed 与发布
- 开发者 support / admin
- 可选导出与远程任务
- LLM / 识别 / 远程配置的适配入口
- 未来 Android / Web / HarmonyOS 的跨生态扩展缝

后端可增强体验，但不得成为当前主记录链路的硬依赖。

## Affected Documents
- `docs/architecture/system-overview.md`
- `docs/product/v1-scope.md`
- `docs/quality/verification-matrix.md`
- `docs/decisions/ADR-0001-full-stack-architecture.md`
- `docs/decisions/ADR-0002-apple-first-user-sync.md`
- `docs/decisions/ADR-0003-local-first-architecture.md`（新增）
- `agent.md`
- `AGENTS.md`

## ADR Strategy
- `ADR-0001` 改为 `Superseded by ADR-0003`
- `ADR-0002` 改为 `Superseded by ADR-0003`
- 新增 `ADR-0003`，正式定义当前路线

这样可以保留历史上下文，又避免未来协作误以为“服务端真源”仍是当前默认方案。

## Validation
- 文档内容互相不冲突：系统总览、ADR、项目地图与协作规则使用同一架构表述
- `agent.md` 中的“最近决策”“模块地图”“下一步任务”与新路线一致
- 至少运行一轮仓库级基础验证，确认文档变更未伴随未发现的代码环境异常
