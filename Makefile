SHELL := /bin/zsh

.PHONY: setup backend-test backend-run dev-up swift-build infra-up infra-down podman-helper podman-proxy ios-project

setup:
	./scripts/setup-backend.sh

backend-test:
	source .venv/bin/activate && pytest backend/tests

backend-run:
	./scripts/start-backend.sh

dev-up:
	./scripts/start-local-dev.sh

swift-build:
	swift build

infra-up:
	./scripts/start-infra.sh

infra-down:
	./scripts/stop-infra.sh

podman-helper:
	./scripts/install-podman-helper.sh

podman-proxy:
	zsh ./scripts/configure-podman-proxy.sh

ios-project:
	./scripts/generate-ios-project.sh
