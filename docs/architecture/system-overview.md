# 饮知系统架构总览

## 目标
饮知当前采用“本地优先、后端辅助”的架构路线，确保核心记录链路在 Apple 生态内无网也可用，同时保留目录、support/admin 和未来跨平台扩展的工程后路。

## 系统分层
- `iOS App`: SwiftUI 客户端，负责界面、本地持久化、离线记录、确定性咖啡因计算、系统能力集成、Typed Client 与同步编排。
- `Local Data + Sync`: 本地数据访问与 `SyncProvider` 同步层。当前 Apple 生态内以 `ICloudKeyValueSyncProvider / LocalOnlySyncProvider` 为主。
- `Python API`: FastAPI 模块化单体，负责品牌目录、support/admin、可选导出、LLM/support 适配、开发联调和未来跨平台同步扩展缝。
- `Data/Admin`: 当前后端持久化与管理后台基础设施。开发期默认 SQLite，后续需要时可切换 PostgreSQL / Redis / 对象存储。

## 真源策略
- 当前 Apple 生态内，用户日志、个人设置、个人饮品模板以本地数据为主真源。
- 同步通过 `SyncProvider` 隔离；`iCloud` 是增强路径，`LocalOnly` 是合法运行模式。
- 后端不再作为当前用户日志的默认真源，而是承担目录、后台和未来跨生态同步接入点。

## API 边界
- `/v1/auth/apple`
- `/v1/profile`
- `/v1/goals`
- `/v1/drink-definitions`
- `/v1/drink-definitions/brew-calculator`
- `/v1/drink-logs`
- `/v1/daily-insights`
- `/v1/recommendations`
- `/v1/exports`
- `/v1/admin/*`
- `/support`

说明：
- 这些接口目前仍存在于后端代码中，便于开发联调、support/admin 与未来扩展。
- 但当前产品路线下，主记录链路不以后端接口可用性作为前提条件。

## 饮品与辅助能力
- 饮品目录以品牌化定义为主，支持 `brandCollection`、风味标签、冲泡方法和默认配方摘要。
- 本地记录模型保留 `brand` 与 `preparationMethod` 字段，便于本地计算与未来目录对齐。
- 冲泡计算首版提供 hand brew / espresso-machine 风格的参数计算，便于记录页直接给出克数、出液量和预估咖啡因。
- LLM 能力当前定位为 support 平台的开发者联调入口，严格走 OpenAI 兼容接口，不进入用户主记录链路。

## iOS 体验边界
- 首页、记录、分析、我的四个顶级区块。
- Liquid Glass 仅应用于导航条、关键卡片、主 CTA、状态 chips 和弹出层。
- iOS 26+ 使用系统玻璃 API；iOS 17-25 使用 `ultraThinMaterial` fallback。
- 首页强调当前咖啡因与入睡残留；记录页强调快速录入与品牌目录；分析页强调咖啡因时间视图；我的页强调多级设置。

## 后续演进
- 完成 iCloud / CloudKit 真同步验收，补 Apple 生态内真实多设备一致性验证。
- 保持后端作为品牌目录、support/admin 和可选远程能力承载层，而不是重新默认接管本地主链路。
- 如果未来扩展 Android / Web / HarmonyOS，再评估新的远程 `SyncProvider` 或服务端真源方案。
