# 饮知项目地图

## 当前结论
- 产品主线：`随手记录咖啡 / 奶茶 -> 计算当前咖啡因与入睡残留 -> 帮用户理解自己的节奏`
- 架构主线：`本地优先、后端辅助`
- 当前状态：首页、记录、分析、我的已经收敛到离线优先的最小体验；本地记录、确定性咖啡因计算、个人设置、个人饮品模板和 `SyncProvider + iCloud` 缝已落地

## 当前真源
- 架构：`docs/decisions/ADR-0003-local-first-architecture.md`
- 系统总览：`docs/architecture/system-overview.md`
- 产品范围：`docs/product/v1-scope.md`
- 质量要求：`docs/quality/verification-matrix.md`
- 文档导航：`docs/README.md`
- 变更导航：`openspec/README.md`

## 模块地图
- iOS App 入口：`ios/Yinzhi/App/YinzhiApp.swift`
- iOS 设计系统：`ios/Yinzhi/Core/Design/`
- iOS Typed Clients：`ios/Yinzhi/Core/Networking/`
- 本地缓存与同步边界：`ios/Yinzhi/Core/Storage/`
- 共享 Swift 领域逻辑：`Sources/YinzhiCore/`
- 后端入口：`backend/app/main.py`
- 后端 API：`backend/app/api/routes/`
- 后端领域与持久化：`backend/app/domain/`、`backend/app/persistence/`
- LLM 适配层：`backend/app/services/llm.py`

## 当前模块职责
- `iOS App`
  - 当前主系统
  - 负责页面、离线记录、本地设置、咖啡因 / 入睡影响计算消费、系统能力集成
- `Local Data + SyncProvider`
  - 当前用户日志、个人设置、个人饮品模板的主数据边界
  - `iCloud` 是增强路径，`LocalOnly` 是合法模式
- `Backend`
  - 当前辅助系统
  - 负责品牌目录、support/admin、可选导出、LLM/support 适配、未来跨平台扩展缝

## 当前生效的 OpenSpec

### 主方向
- `openspec/changes/coffee-first-recording-reset/`
- `openspec/changes/offline-focus-surface-reset/`
- `openspec/changes/local-first-architecture-alignment/`

### 体验细化
- `openspec/changes/hicoffee-quick-capture/`
- `openspec/changes/mvp-experience-polish/`
- `openspec/changes/home-and-log-density-reset/`
- `openspec/changes/catalog-depth-and-template-management/`

### 文档治理
- `openspec/changes/documentation-and-spec-consolidation/`

### 基础历史
- `openspec/changes/bootstrap-yinzhi-v1-1/`

## 稳定决策
- 当前主记录链路不得依赖后端可用性
- 用户日志、个人设置和个人饮品模板在 Apple 生态内以本地数据为主真源
- 同步必须继续走 `SyncProvider`，页面层不直接接触 iCloud / CloudKit API
- 后端继续保留 typed API 和持久化边界，但定位为辅助系统而不是当前真源
- 咖啡因与入睡影响模型必须保持确定性、可测试、可跨 iPhone / Widget / Watch 复用
- 记录页优先级固定为：先完成记录，再浏览目录
- 图片识别必须保持本地 OCR + 可回退搜索
- 语音输入必须经过结构化确认，不直接把自由文本写成最终记录
- Liquid Glass 只用于高价值表面，必须保留旧系统 fallback

## 当前体验结论
- 首页：只保留当前体内咖啡因、入睡残留和 `记一杯`
- 记录：上方是记录入口，下方是品牌目录；目录饮品为横条 row；已增加咖啡因计算器二级页面
- 分析：收口为咖啡因时间视图，不再让糖分 / 补水等次要结构抢主位
- 我的：改为多级列表设置，具体设置与数据动作下沉到二级页面

## 验证状态
- 已通过：
  - `swift test`
  - `xcodebuild -project ios/Yinzhi.xcodeproj -scheme Yinzhi -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
  - `source .venv/bin/activate && pytest backend/tests -q`
- 已验证边界：
  - 本地快照 round-trip
  - 本地缓存全量替换
  - 离线记录后的品牌 / 冲煮方式保留
- 尚未完成：
  - 带正式 iCloud capability 的真机跨设备同步验收
  - Widget / Watch 的正式产物验证

## 未决问题
- iCloud / CloudKit 的正式 capability 与多设备真同步验收
- 品牌目录从 seed 走向可持续维护机制
- 语音短句 parser 与图片识别命中率继续提高
- 后端 support/admin 与目录管理的长期边界
- HarmonyOS 适配时的跨生态同步策略

## 下一步任务
1. 完成 iCloud 真同步验收，明确是否升级到更完整的 CloudKit 容器方案
2. 继续打磨记录页品牌目录、语音 parser 和图片识别命中率
3. 在当前离线结构上补截图回归、视觉细节和微交互
4. 规划并实现 Widget 与 Watch app 的最小可用目标
5. Apple 路线稳定后，再单开 HarmonyOS 适配研究
