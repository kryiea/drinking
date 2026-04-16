# Design: Documentation And Spec Consolidation

## Scope
- `docs/README.md`（新增）
- `openspec/README.md`（新增）
- `agent.md`
- `docs/architecture/*.md`
- `docs/product/*.md`
- `docs/quality/*.md`
- `openspec/changes/bootstrap-yinzhi-v1-1/specs/bootstrap-spec.md`

## Principles
- 历史不删除，但必须标清“当前是否生效”
- 长期文档讲“当前真源”，OpenSpec 讲“变更过程”
- `agent.md` 应该是项目地图，不是无限增长的会议纪要

## Documentation Structure

### docs/
- `docs/README.md` 作为长期文档导航入口
- ADR、系统总览、产品范围、质量矩阵保持清晰阅读顺序
- 本地开发环境文档明确：后端是辅助开发能力，不是当前主链路前提

### openspec/
- `openspec/README.md` 作为变更导航入口
- change 按语义分组：
  - 基础历史
  - 当前主方向
  - 当前生效的交互/体验细化
  - 文档与架构对齐类 change
- 说明：若历史 change 与 `ADR-0003` 或更晚 change 冲突，以更晚决策和当前 change 为准

### agent.md
- 结构重写为：
  - 当前结论
  - 当前真源文档
  - 模块地图
  - 生效中的变更
  - 稳定决策
  - 验证状态
  - 未决问题
  - 下一步任务
- 删除大量重复时间线描述，保留高信号信息

## Spec Cleanup
- 为 bootstrap spec 增加历史说明，明确它记录的是仓库初始化能力，不是当前用户侧产品方向
- 不重写所有历史 spec 的目标，而是通过导航文档和说明文字减少误读

## Validation
- `docs/README.md` 与 `openspec/README.md` 能互相引用并指向当前真源
- `agent.md` 明显短于旧版，且能独立承担项目地图角色
- `swift test`
- `source .venv/bin/activate && pytest backend/tests -q`
