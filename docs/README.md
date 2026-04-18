# 饮知文档导航

这份文档用于回答三个问题：
- 当前产品到底做什么
- 当前架构到底以什么为主
- 继续开发时，应该先看哪些长期文档

## 推荐阅读顺序
1. [ADR-0003：本地优先应用架构与后端辅助角色](./decisions/ADR-0003-local-first-architecture.md)
2. [系统架构总览](./architecture/system-overview.md)
3. [v1 范围说明](./product/v1-scope.md)
4. [质量验证矩阵](./quality/verification-matrix.md)
5. [本地开发环境](./architecture/local-environment.md)
6. 根目录 [agent.md](../agent.md)
7. 根目录 [README.md](../README.md)
8. HarmonyOS 端 [harmony/README.md](../harmony/README.md)

## 当前真源

### 架构真源
- `docs/decisions/ADR-0003-local-first-architecture.md`
- 当前路线：`本地优先、后端辅助`

### 产品真源
- `docs/product/v1-scope.md`
- 当前路线：`离线记录 + 咖啡因 / 入睡影响理解 + iOS / HarmonyOS 并行客户端`

### 质量真源
- `docs/quality/verification-matrix.md`
- 当前重点：主链路不能依赖后端成功、计算必须确定性、页面层不得绕过 typed seam

### 项目地图
- 根目录 `agent.md`
- 作用：给协作者和 AI 快速说明当前阶段、模块地图、活跃变更与下一步任务

## 如何理解 OpenSpec
- 长期文档描述“当前稳定方向”
- OpenSpec 描述“变更过程”和“每一轮迭代的设计边界”
- 如果历史 change 与当前长期文档冲突：
  - 优先以 `ADR-0003`
  - 再看 `agent.md`
  - 再看最近仍生效的 OpenSpec change

更多变更导航请看 [openspec/README.md](../openspec/README.md)。

## 历史文档说明
- `ADR-0001` 和 `ADR-0002` 仍保留，是为了保留架构演进历史
- 它们已经被 `ADR-0003` 收敛，不再单独代表当前路线
- 历史 OpenSpec change 也继续保留，但页面、架构和产品结论请优先以 `agent.md`、`README.md` 与本目录当前真源文档为准

## 当前文档分工
- `README.md`: 面向第一次进入仓库的人，快速理解产品、页面、截图和启动方式
- `docs/*`: 面向持续开发者，给出长期稳定的架构、产品与质量约束
- `openspec/*`: 面向每一轮变更，说明为什么改、怎么改、哪些任务完成了

## 维护约定
- 改动当前架构或主链路时，同时更新：
  - `agent.md`
  - 相关 ADR / 架构文档
  - 对应 OpenSpec change
- 不要用新增文档替代已有真源，除非同步更新导航入口
- 如果只是补充当前路线说明，优先合并回现有 `README.md`、本目录真源文档或已有 OpenSpec change，而不是继续新增平行说明文件
