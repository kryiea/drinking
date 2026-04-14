# Yinzhi AI Collaboration Rules

## Mission
- Build and maintain `饮知` as an AI-native product with clear ownership boundaries, durable documentation, and verifiable delivery quality.
- Keep the user-facing product focused on the v1 health loop: beverage logging, health interpretation, and explainable recommendations.

## Delivery Workflow
1. Start every meaningful change with an OpenSpec change folder under `openspec/changes/<slug>/`.
2. Update `proposal.md`, `design.md`, `tasks.md`, and the relevant spec before implementation.
3. Implement code and tests together.
4. Update `agent.md` and any impacted architecture, product, quality, or decision documents.
5. Run the available validation commands before closing the change.

## Repository Map
- `backend/`: FastAPI modular monolith for auth, beverage catalog, logs, insights, recommendations, exports, and admin APIs.
- `ios/`: SwiftUI app shell, design system, typed network clients, offline cache models, and feature UI.
- `Sources/YinzhiCore`: shared pure Swift domain logic that can be tested without an iOS build.
- `docs/`: long-lived product, architecture, decision, and quality records.
- `openspec/`: per-change proposal, design, tasks, and specs.

## Quality Gates
- Backend: lint-compatible code style, `pytest`, route smoke coverage, and recommendation logic tests.
- iOS shared logic: `swift test`.
- iOS app shell: keep compile-ready source structure, use typed clients only, keep offline-first cache boundaries explicit.
- Documentation: `agent.md` and affected ADR/spec pages must be updated when interfaces or behavior change.

## Engineering Constraints
- Keep frontend and backend separated by explicit typed contracts.
- Never let SwiftUI views call `URLSession` directly; all networking flows through typed clients.
- Recommendation responses must remain explainable and deterministic in v1.
- Liquid Glass is opt-in for high-value surfaces only; provide material fallback for iOS 17-25.
- Prefer production-shaped seams even when local dev uses seed data or in-memory adapters.

## Validation Commands
- Backend install: `./scripts/setup-backend.sh`
- Backend tests: `source .venv/bin/activate && pytest backend/tests`
- Swift shared logic tests: `swift test`
- Infra up: `./scripts/start-infra.sh`
- iOS project generation: `./scripts/generate-ios-project.sh`

## Handoff Rules
- If a task cannot be fully verified because the environment lacks Xcode or runtime services, document the gap explicitly in `agent.md` and the final handoff.
- Preserve user-facing Chinese copy unless a change explicitly targets localization or editorial tone.
