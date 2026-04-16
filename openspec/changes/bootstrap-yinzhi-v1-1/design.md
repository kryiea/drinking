# Design: Bootstrap Yinzhi v1.1

## Backend
- FastAPI app with route groups for auth, profile, goals, drink definitions, drink logs, daily insights, recommendations, exports, and admin.
- Repository boundary stays stable at the domain layer while the concrete adapter is now SQLAlchemy-based persistence.
- Development boots with SQLite + startup seed data so API work is not blocked by local middleware readiness.
- The same repository seam is intended to switch to PostgreSQL by environment configuration rather than route rewrites.
- Recommendation engine produces deterministic explanation objects from aggregated intake metrics.
- Catalog definitions now carry brand, flavor, preparation methods, and brew recipe summaries so the same contract can power both search and brew-assist UI.
- Admin surface includes a lightweight support console plus an OpenAI-compatible LLM adapter that can operate in fallback mode before secrets are configured.

## iOS
- SwiftUI app shell with four tabs and a small design system.
- Typed clients defined in protocols and concrete live/preview implementations.
- `AppConfig` reads backend base URL and preview fallback policy from `Info.plist`.
- `SessionStore` persists app session locally, while `OfflineCacheStore` keeps SwiftData-backed drink logs and a pending replay queue.
- Onboarding now supports Apple 登录入口、开发期直连后端入口与离线体验入口 three-path boot.
- Home / Log / Insights / Profile screens read sync state from the shared environment instead of preview-only fixtures.
- Shared pure Swift target for recommendation presentation and progress calculations.
- Home emphasizes a compact "结论先行" layout instead of heavy explanatory copy.
- Log expands into brand-aware quick entry plus a Brew Lab for hand brew and machine-style parameter estimation.
- The shared app environment now carries caffeine-metabolism forecast data, AI brief data, and a global add-drink feedback state so Home, Log, Insights, and Profile stay in sync.
- Add-drink UX uses a root-level celebration overlay above the tab shell, including caffeine delta, sleep-window impact, and sync status instead of a silent write-only interaction.
- Horizontal AI suggestion cards are intentionally compacted so the primary CTA remains fully visible above the tab bar on iPhone-class screens.
- Scroll-heavy tabs reserve extra bottom spacing to keep Liquid Glass tab chrome from clipping important CTAs or analysis rows.

## Docs
- Root rules in `AGENTS.md`
- project map in `agent.md`
- architecture/product/decision/quality docs under `docs/`
- local environment docs describe Podman-only proxy bridging so VPN users can keep host networking untouched
