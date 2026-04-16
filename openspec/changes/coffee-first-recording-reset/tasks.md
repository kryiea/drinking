# Tasks

- [x] Freeze product scope around coffee-first recording and remove user-facing AI recommendation goals from current spec
- [x] Redesign Home / Log / Insights / Profile information architecture around fast logging and caffeine impact
- [x] Refactor catalog domain into brand sections, compact rows, and user-defined drink templates
- [x] Add deterministic caffeine-curve engine and sleep-marker visualization contract
- [x] Design and implement structured voice-input parsing and confirmation flow
- [x] Introduce Apple-first sync seam with local store and iCloud provider strategy
- [x] Define Widget surfaces and Watch app scope before target creation
- [x] Document HarmonyOS follow-up as a later-phase architecture plan, not a current implementation item
- [x] Update ADR, project map, product docs, and quality gates before implementation

## Notes
- `Apple-first sync seam` 当前已完成 `UserLocalSnapshot + SyncProvider + iCloud KVS provider + 本地缓存导入导出 + UI 状态接线`。
- 当前本地环境已经验证了代码路径、快照序列化和 app 内状态切换，但尚未在带正式 iCloud capability / 签名的环境里完成真机同步验收；CloudKit 能力仍在后续阶段。
