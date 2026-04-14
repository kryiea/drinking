SHELL := /bin/zsh

.PHONY: setup backend-test swift-build infra-up infra-down podman-helper ios-project

setup:
	./scripts/setup-backend.sh

backend-test:
	source .venv/bin/activate && pytest backend/tests

swift-build:
	swift build

infra-up:
	./scripts/start-infra.sh

infra-down:
	./scripts/stop-infra.sh

podman-helper:
	./scripts/install-podman-helper.sh

ios-project:
	./scripts/generate-ios-project.sh
