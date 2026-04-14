# 饮知项目地图

## 当前阶段
- 阶段: 本地联调链路与品牌化记录体验完成，进入鉴权、中间件收口与能力扩展阶段
- 目标: 在前后端本地可运行的前提下，继续把服务端真源、支持平台、LLM 接入和更细的饮品场景做实
- 状态: FastAPI 合同、SwiftUI App Shell、实时 typed clients、会话持久化、SwiftData 离线缓存和补同步路径已落地；后端已切到 SQLAlchemy 仓储，开发默认 SQLite、生产目标 PostgreSQL；support 页面、品牌目录、冲泡计算、OpenAI 兼容 LLM 适配和 `xcodebuild` 编译验证已完成，Podman 中间件通过 Podman VM 代理桥接继续收口

## 产品焦点
- 核心闭环: 饮品记录 -> 健康解释 -> 行为建议
- V1 范围: 首页、记录、分析、我的四个一级入口；Apple 登录；可解释建议；离线缓存；服务端真源
- 暂缓项: 社区、专家咨询、订阅付费、开放 API、聊天式 AI、条码/语音/图像识别

## 模块地图
- 后端入口: `backend/app/main.py`
- API 路由: `backend/app/api/routes/`
- 领域模型与仓储: `backend/app/domain/`
- 建议引擎: `backend/app/services/recommendations.py`
- LLM 适配层: `backend/app/services/llm.py`
- iOS App 入口: `ios/Yinzhi/App/YinzhiApp.swift`
- iOS 设计系统: `ios/Yinzhi/Core/Design/`
- iOS Typed Clients: `ios/Yinzhi/Core/Networking/`
- 共享 Swift 领域逻辑: `Sources/YinzhiCore/`

## 文档索引
- 架构总览: `docs/architecture/system-overview.md`
- 本地环境: `docs/architecture/local-environment.md`
- 产品范围: `docs/product/v1-scope.md`
- 决策记录: `docs/decisions/ADR-0001-full-stack-architecture.md`
- 质量策略: `docs/quality/verification-matrix.md`
- 当前 OpenSpec 变更: `openspec/changes/bootstrap-yinzhi-v1-1/`

## 最近决策
- 采用前后端分离，服务端为业务真源，本地 SwiftData 作为缓存和 UI 数据源
- 后端选型为 FastAPI 模块化单体，首版保持私有用户 API
- UI 主设计按 iOS 26+ Liquid Glass 实现，同时对 iOS 17-25 提供材质 fallback
- 推荐系统首版仅做可解释、确定性的规则引擎，不做开放式对话
- 本地基础设施统一走 Podman + podman-compose，项目脚本不强制 machine provider，避免和宿主机现有的 `libkrun` / `applehv` 配置冲突
- 当宿主机使用本地 VPN/代理端口时，通过 `scripts/configure-podman-proxy.sh` 只给 Podman VM 注入代理，不影响 macOS 全局网络
- iOS 端登录分为正式 Apple 登录入口和开发期直连后端入口，便于 AI 在无真机账号态下持续联调
- 客户端联网边界固定为 `AppConfig + APIContainer + SessionStore + OfflineCacheStore`，页面层不直连 `URLSession`
- 后端仓储边界固定为 `AppRepository Protocol + SQLAlchemyRepository + session factory`，路由层不感知具体数据库实现
- 开发环境默认落 SQLite 以避免中间件阻塞，PostgreSQL 通过 `YINZHI_DATABASE_URL` 切换
- 饮品目录首版直接携带品牌、风味、冲泡方法和配方摘要，记录页承担品牌筛选与 Brew Lab 交互
- support 平台作为开发者后台最小集，先覆盖反馈复核、规则状态和 OpenAI 兼容 LLM 联调

## 未决问题
- Apple 身份令牌的正式验签、公钥轮换和生产环境 secrets 管理
- PostgreSQL、Redis、对象存储和管理后台的生产部署方案
- HealthKit 读写字段的最终清单与审核用隐私文案
- LLM provider 的正式选型、限流、审计与 prompt 版本化管理
- Brew Lab 后续是否需要扩展到更多茶饮、奶萃和咖啡机配方体系

## 下一步任务
1. 补上 Apple 登录验签、JWT 刷新链路和 iOS entitlements
2. 为 Podman 中间件补全 PostgreSQL、Redis、MinIO 的稳定启动与本地切库说明
3. 接入 HealthKit 最小读取集与截图回归基线
4. 为 SQLAlchemy 层补 Alembic 迁移和 PostgreSQL 联调说明
5. 为 support 平台增加登录保护、操作审计和规则开关持久化
