# Proposal: Documentation And Spec Consolidation

## Why
当前仓库已经积累了多轮产品和架构变更，长期文档、ADR、`agent.md` 和 OpenSpec 变更文档都在不断增长。虽然大部分内容有效，但阅读路径、当前真源、历史变更与现行方向之间的边界还不够清楚，导致：
- 新接手的人或 AI 很难快速判断“现在到底该看哪份文档”
- 历史 change 与当前生效 change 混在一起，容易误读早期目标为现行目标
- `agent.md` 的时间线型堆叠越来越长，项目地图价值下降

## What
- 新增面向仓库协作者的文档导航页，明确长期文档与 OpenSpec 的阅读顺序
- 整理 OpenSpec 变更索引，区分基础历史、当前生效和补充细化类 change
- 重写 `agent.md`，把项目地图从“累积日志”收口成“当前真源地图”
- 优化长期文档，统一当前产品、架构和质量语言
- 对早期 bootstrap spec 补充历史说明，避免把早期 AI / recommendation 目标误认为当前要求

## Success Criteria
- 新协作者可以在 3 分钟内找到当前架构、当前范围、当前质量要求和当前生效的变更集合
- `agent.md` 不再依赖长时间线堆叠来表达当前状态
- `docs/` 与 `openspec/` 都有清晰导航入口
- 早期历史 spec 不再轻易误导当前产品方向
