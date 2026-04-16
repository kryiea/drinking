# OpenSpec 导航

OpenSpec 记录的是“为什么发生这次变更、怎么设计、做了什么、哪些要求仍然生效”。

如果你只是想快速理解当前产品和架构，请先看：
- [`docs/README.md`](../docs/README.md)
- [`agent.md`](../agent.md)

## 如何阅读变更

### 1. 基础历史
这些 change 主要说明仓库是如何搭起来的，不代表今天的全部产品方向。
- `bootstrap-yinzhi-v1-1`

### 2. 当前主方向
这些 change 共同定义了当前仍然生效的产品与架构路线。
- `coffee-first-recording-reset`
  - 把产品主轴收敛到“记录 + 咖啡因影响理解”
- `offline-focus-surface-reset`
  - 把一级页面进一步收敛到离线优先的最小体验
- `local-first-architecture-alignment`
  - 把仓库架构路线正式统一为“本地优先、后端辅助”

### 3. 当前有效的体验细化
这些 change 不改变主方向，但仍然为当前 UI / 交互提供有效约束。
- `hicoffee-quick-capture`
- `mvp-experience-polish`
- `home-and-log-density-reset`
- `home-glance-redesign`
- `record-selector-and-calculator-refresh`
- `contrast-illustration-and-appearance`
- `log-brand-catalog-and-contrast-polish`
- `catalog-depth-and-template-management`

### 4. 文档治理
这些 change 主要用于整理信息结构、维护协作质量。
- `documentation-and-spec-consolidation`

## 当前推荐阅读顺序
1. `local-first-architecture-alignment`
2. `offline-focus-surface-reset`
3. `coffee-first-recording-reset`
4. 需要细化某个页面或体验时，再看对应 refinement change

## 冲突处理规则
- 如果历史 change 与 `ADR-0003` 冲突，以 `ADR-0003` 为准
- 如果多个 change 对同一页面有不同约束：
  - 优先看更晚、且仍与当前方向一致的 change
  - 再参考 `agent.md` 中的“当前阶段 / 稳定决策 / 下一步任务”

## Change 内部阅读顺序
每个 change 按这个顺序读：
1. `proposal.md`
2. `design.md`
3. `specs/*/spec.md`
4. `tasks.md`

## 维护约定
- 新的重大方向变化，优先新增 change，不要直接改历史 change 伪装成一直如此
- 历史 change 可以保留，但应通过导航文档说明它是否仍然代表当前方向
- 如果某次迭代只是对现有方向做细化，优先补齐已有 change 和长期文档，不再额外制造重复的说明文件
