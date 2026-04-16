# Yinzhi AI Collaboration Rules

## Mission
- Build and maintain `饮知` as an AI-native product with clear ownership boundaries, durable documentation, and verifiable delivery quality.
- Keep the user-facing product focused on the current v1 loop: beverage logging, caffeine/sleep understanding, and low-friction Apple-ecosystem use.

## Delivery Workflow
1. Start every meaningful change with an OpenSpec change folder under `openspec/changes/<slug>/`.
2. Update `proposal.md`, `design.md`, `tasks.md`, and the relevant spec before implementation.
3. Implement code and tests together.
4. Update `agent.md` and any impacted architecture, product, quality, or decision documents.
5. Run the available validation commands before closing the change.

## Documentation Precedence
- Prefer `docs/decisions/ADR-0003-local-first-architecture.md` for current architecture direction.
- Prefer `docs/README.md` and `openspec/README.md` to determine which documents and changes are current versus historical.
- When an early historical change conflicts with a later accepted ADR or a newer active change, follow the newer ADR / change and update the navigation docs if needed.

## Repository Map
- `backend/`: FastAPI modular monolith for beverage catalog, support/admin, optional exports, LLM adapters, and future cross-platform seams.
- `ios/`: SwiftUI app shell, design system, typed network clients, offline cache models, and feature UI.
- `Sources/YinzhiCore`: shared pure Swift domain logic that can be tested without an iOS build.
- `docs/`: long-lived product, architecture, decision, and quality records.
- `openspec/`: per-change proposal, design, tasks, and specs.
- `scripts/`: reproducible local environment, Podman, backend boot, and Xcode helper scripts.

## Quality Gates
- Backend: lint-compatible code style, `pytest`, route smoke coverage, and recommendation logic tests.
- iOS shared logic: `swift test`.
- iOS app shell: keep compile-ready source structure, use typed clients only, keep offline-first cache boundaries explicit.
- Documentation: `agent.md` and affected ADR/spec pages must be updated when interfaces or behavior change.

## Engineering Constraints
- Keep frontend and backend separated by explicit typed contracts even when the current product route is local-first.
- Never let SwiftUI views call `URLSession` directly; all networking flows through typed clients.
- Core user data must remain local-first and available without backend connectivity.
- Caffeine and sleep calculations must remain deterministic and testable.
- LLM integration must stay behind a backend adapter and support OpenAI-compatible providers by configuration.
- Liquid Glass is opt-in for high-value surfaces only; provide material fallback for iOS 17-25.
- Local infrastructure fixes must not mutate the host macOS VPN/proxy configuration; prefer Podman-only bridge scripts.
- Prefer production-shaped seams even when local dev uses seed data or in-memory adapters.

## Validation Commands
- Backend install: `./scripts/setup-backend.sh`
- Backend tests: `source .venv/bin/activate && pytest backend/tests`
- Swift shared logic tests: `swift test`
- Infra up: `./scripts/start-infra.sh`
- Podman proxy bridge: `zsh ./scripts/configure-podman-proxy.sh`
- iOS project generation: `./scripts/generate-ios-project.sh`

## Handoff Rules
- If a task cannot be fully verified because the environment lacks Xcode or runtime services, document the gap explicitly in `agent.md` and the final handoff.
- Preserve user-facing Chinese copy unless a change explicitly targets localization or editorial tone.
