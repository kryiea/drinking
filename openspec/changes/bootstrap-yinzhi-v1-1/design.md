# Design: Bootstrap Yinzhi v1.1

## Backend
- FastAPI app with route groups for auth, profile, goals, drink definitions, drink logs, daily insights, recommendations, exports, and admin.
- Repository boundary stays stable at the domain layer while the concrete adapter is now SQLAlchemy-based persistence.
- Development boots with SQLite + startup seed data so API work is not blocked by local middleware readiness.
- The same repository seam is intended to switch to PostgreSQL by environment configuration rather than route rewrites.
- Recommendation engine produces deterministic explanation objects from aggregated intake metrics.

## iOS
- SwiftUI app shell with four tabs and a small design system.
- Typed clients defined in protocols and concrete live/preview implementations.
- `AppConfig` reads backend base URL and preview fallback policy from `Info.plist`.
- `SessionStore` persists app session locally, while `OfflineCacheStore` keeps SwiftData-backed drink logs and a pending replay queue.
- Onboarding now supports Apple 登录入口、开发期直连后端入口与离线体验入口 three-path boot.
- Home / Log / Insights / Profile screens read sync state from the shared environment instead of preview-only fixtures.
- Shared pure Swift target for recommendation presentation and progress calculations.

## Docs
- Root rules in `AGENTS.md`
- project map in `agent.md`
- architecture/product/decision/quality docs under `docs/`
