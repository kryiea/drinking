# 饮知项目地图

## 当前阶段
- 阶段: 后端持久化底座完成，准备进入鉴权与功能细化
- 目标: 在前后端联调继续推进的同时，把服务端真源从内存实现升级到可持续演进的 SQLAlchemy 持久化
- 状态: FastAPI 合同、SwiftUI App Shell、实时 typed clients、会话持久化、SwiftData 离线缓存和补同步路径已落地；后端已切到 SQLAlchemy 仓储，开发默认 SQLite、生产目标 PostgreSQL；完整 Xcode 安装与 `xcodebuild` 级验证仍待完成

## 产品焦点
- 核心闭环: 饮品记录 -> 健康解释 -> 行为建议
- V1 范围: 首页、记录、分析、我的四个一级入口；Apple 登录；可解释建议；离线缓存；服务端真源
- 暂缓项: 社区、专家咨询、订阅付费、开放 API、聊天式 AI、条码/语音/图像识别

## 模块地图
- 后端入口: `backend/app/main.py`
- API 路由: `backend/app/api/routes/`
- 领域模型与仓储: `backend/app/domain/`
- 建议引擎: `backend/app/services/recommendations.py`
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
- 本地基础设施统一走 Podman + podman-compose，provider 固定为 applehv
- 当前机器的 Podman machine 宿主侧 socket 仍未稳定打通，基础设施环境先暂缓，不阻塞主链路开发
- iOS 端登录分为正式 Apple 登录入口和开发期直连后端入口，便于 AI 在无真机账号态下持续联调
- 客户端联网边界固定为 `AppConfig + APIContainer + SessionStore + OfflineCacheStore`，页面层不直连 `URLSession`
- 后端仓储边界固定为 `AppRepository Protocol + SQLAlchemyRepository + session factory`，路由层不感知具体数据库实现
- 开发环境默认落 SQLite 以避免中间件阻塞，PostgreSQL 通过 `YINZHI_DATABASE_URL` 切换

## 未决问题
- Apple 身份令牌的正式验签、公钥轮换和生产环境 secrets 管理
- PostgreSQL、Redis、对象存储和管理后台的生产部署方案
- iOS 端完整 Xcode 安装与设备级编译验证
- HealthKit 读写字段的最终清单与审核用隐私文案

## 下一步任务
1. 补上 Apple 登录验签、JWT 刷新链路和 iOS entitlements
2. 将记录页扩展为“最近/收藏/自定义模板”三入口，并补 UI 测试
3. 接入 HealthKit 最小读取集与截图回归基线
4. 为 SQLAlchemy 层补 Alembic 迁移和 PostgreSQL 联调说明
