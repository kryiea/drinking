# 饮知系统架构总览

## 目标
饮知 v1.1 采用前后端分离架构，确保 iOS 客户端、后端 API、数据与运营能力可以独立演进，同时让 AI 能依靠稳定文档与清晰接口持续维护。

## 系统分层
- `iOS App`: SwiftUI 客户端，负责界面、离线缓存、系统能力集成、Typed Client 与同步编排。
- `Python API`: FastAPI 模块化单体，负责鉴权、饮品目录、品牌与冲泡计算、饮品记录、洞察聚合、推荐决策、导出任务、LLM 接口适配和内部管理接口。
- `Data/Admin`: PostgreSQL、Redis、对象存储与内部管理后台能力。当前仓库已将核心数据持久化到 SQLAlchemy 仓储层，开发期默认 SQLite，生产目标仍是 PostgreSQL。

## 真源策略
- 服务端是真正的业务真源。
- iOS 本地缓存用于离线记录和 UI 响应，不承担跨设备一致性责任。
- 同步以 `SyncEnvelope` 作为边界对象，记录版本、时间戳和待同步状态。

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

## 饮品与建议能力
- 饮品目录以品牌化定义为主，支持 `brandCollection`、风味标签、冲泡方法和默认配方摘要。
- 记录模型已预留 `brand` 与 `preparationMethod` 字段，便于后续接入更细的分析和个性化阈值。
- 冲泡计算首版提供 hand brew / espresso-machine 风格的参数计算，便于记录页直接给出克数、出液量和预估咖啡因。
- LLM 能力当前定位为 support 平台的开发者联调入口，严格走 OpenAI 兼容接口，不直接进入用户开放聊天路径。

## iOS 体验边界
- 首页、记录、分析、我的四个顶级区块。
- Liquid Glass 仅应用于导航条、关键卡片、主 CTA、状态 chips 和弹出层。
- iOS 26+ 使用系统玻璃 API；iOS 17-25 使用 `ultraThinMaterial` fallback。
- 首页强调「结论先行」和更轻的信息密度；记录页扩展为品牌筛选、冲泡实验区和更强的快捷录入体验。

## 后续演进
- 将当前 SQLAlchemy 持久化从 SQLite 开发库切换到 PostgreSQL 实例，并补 Alembic 迁移。
- 将导出任务和同步任务迁移到后台队列。
- 在不改变 API 契约的前提下扩展 Android/Web 客户端。
