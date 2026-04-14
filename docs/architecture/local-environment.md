# 本地开发环境

## 已采用的本机工具链
- Homebrew 安装: `xcodegen`、`cocoapods`、`mas`、`xcodes`
- Node 全局安装: `openspec`
- `uv` 用于 Python 环境创建与安装
- `podman` + `podman-compose` 用于本地基础设施
- Podman machine provider 固定为 `applehv`

## 一键命令
- 初始化后端依赖: `./scripts/setup-backend.sh`
- 启动基础设施: `./scripts/start-infra.sh`
- 停止基础设施: `./scripts/stop-infra.sh`
- 安装 Podman macOS helper: `./scripts/install-podman-helper.sh`
- 生成 iOS 工程: `./scripts/generate-ios-project.sh`
- 安装完整 Xcode: `./scripts/install-xcode.sh`

## 本地基础设施
- PostgreSQL: `127.0.0.1:5432`
- Redis: `127.0.0.1:6379`
- MinIO API: `127.0.0.1:9000`
- MinIO Console: `127.0.0.1:9001`

## 当前后端持久化策略
- 默认情况下，后端会使用仓库根目录下的 SQLite 开发库 `sqlite:///./.data/yinzhi-dev.db`，这样即使 Podman 中间件暂时不可用，也能继续推进 API 与 iOS 联调。
- 当本地 PostgreSQL 可用时，只需设置 `YINZHI_DATABASE_URL=postgresql://...` 即可切换到 PostgreSQL，无需改动路由层或领域接口。
- Schema 当前由应用启动时自动创建并播种种子数据；正式环境下一步需要补 Alembic 迁移链路。

## 注意事项
- Podman machine 在 macOS 上可能需要几秒钟才能真正进入可连接状态，因此脚本里包含了等待与 SSH 探活逻辑。
- 如果 Podman machine 显示 `running` 但宿主侧 socket 仍拒绝连接，这台机器通常还需要执行 `sudo /opt/podman/bin/podman-mac-helper install`。
- 完整 Xcode 安装需要 App Store 账号密码确认，这一步无法自动代填。
- 目前仓库已生成 `ios/project.yml`，在完整 Xcode 安装后运行 `./scripts/generate-ios-project.sh` 即可得到正式 `.xcodeproj`。
