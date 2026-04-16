# 本地开发环境

## 已采用的本机工具链
- Homebrew 安装: `xcodegen`、`cocoapods`、`mas`、`xcodes`
- Node 全局安装: `openspec`
- `uv` 用于 Python 环境创建与安装
- `podman` + `podman-compose` 用于本地基础设施
- Podman machine 复用当前本机已存在的 provider，不在项目脚本里强制切换

## 一键命令
- 初始化后端依赖: `./scripts/setup-backend.sh`
- 启动基础设施: `./scripts/start-infra.sh`
- 停止基础设施: `./scripts/stop-infra.sh`
- 安装 Podman macOS helper: `./scripts/install-podman-helper.sh`
- 将当前 macOS 代理桥接到 Podman machine: `zsh ./scripts/configure-podman-proxy.sh`
- 生成 iOS 工程: `./scripts/generate-ios-project.sh`
- 安装完整 Xcode: `./scripts/install-xcode.sh`

## 当前开发优先级
- 当前产品主链路是本地优先，因此即使后端或中间件暂时不可用，也可以继续推进：
  - iOS 页面
  - 本地记录与设置
  - 领域模型与确定性计算
  - iCloud / `SyncProvider` 边界
- Podman、后端与中间件当前主要用于目录、support/admin、导出和未来扩展能力联调。

## 本地基础设施
- PostgreSQL: `127.0.0.1:5432`
- Redis: `127.0.0.1:6379`
- MinIO API: `127.0.0.1:9000`
- MinIO Console: `127.0.0.1:9001`

## 当前后端持久化策略
- 默认情况下，后端会使用仓库根目录下的 SQLite 开发库 `sqlite:///./.data/yinzhi-dev.db`，这样即使 Podman 中间件暂时不可用，也能继续推进 API 与 iOS 联调。
- 当本地 PostgreSQL 可用时，只需设置 `YINZHI_DATABASE_URL=postgresql://...` 即可切换到 PostgreSQL，无需改动路由层或领域接口。
- Schema 当前由应用启动时自动创建并播种种子数据；正式环境下一步需要补 Alembic 迁移链路。

## 本地联调入口
- API 健康检查: `http://127.0.0.1:8000/healthz`
- Support 平台: `http://127.0.0.1:8000/support`
- 管理端 JSON 快照: `http://127.0.0.1:8000/v1/admin/support`
- 一键开发启动: `./scripts/start-local-dev.sh`

说明：
- 这些入口当前属于“辅助远程能力”联调入口，不是主记录链路的必备条件。

## Podman 与 VPN
- 仓库脚本不会修改 macOS 全局 VPN 或系统代理。
- 当宿主机走本地代理，例如 `127.0.0.1:6454` 时，Podman VM 内无法直接访问宿主机回环地址，需要把代理改写为 `host.containers.internal:<port>`。
- `zsh ./scripts/configure-podman-proxy.sh` 会只在 Podman machine 内为 `podman.service` 写入 `HTTP_PROXY`、`HTTPS_PROXY` 与 `NO_PROXY`，从而解决 `docker.io` 拉镜像超时问题，同时不影响宿主机网络。
- 如果当前不需要代理，可执行 `zsh ./scripts/configure-podman-proxy.sh --clear` 清除 Podman VM 的代理覆盖。

## LLM 接入准备
- 后端已预留 OpenAI 兼容配置：
  - `YINZHI_LLM_PROVIDER`
  - `YINZHI_LLM_BASE_URL`
  - `YINZHI_LLM_API_KEY`
  - `YINZHI_LLM_MODEL`
  - `YINZHI_LLM_TIMEOUT_SECONDS`
- 在未提供密钥和地址前，support 平台会返回本地 fallback 结果，方便先联调交互与错误处理。

## 注意事项
- Podman machine 在 macOS 上可能需要几秒钟才能真正进入可连接状态，因此脚本里包含了等待与 SSH 探活逻辑。
- 如果 Podman machine 显示 `running` 但宿主侧 socket 仍拒绝连接，这台机器通常还需要执行 `sudo /opt/podman/bin/podman-mac-helper install`。
- 当前 compose 默认镜像均可通过 `infra/.env` 覆盖，便于在国内网络环境下切换到更稳定的镜像源。
- 完整 Xcode 安装需要 App Store 账号密码确认，这一步无法自动代填。
- 目前仓库已生成 `ios/project.yml`，在完整 Xcode 安装后运行 `./scripts/generate-ios-project.sh` 即可得到正式 `.xcodeproj`。
