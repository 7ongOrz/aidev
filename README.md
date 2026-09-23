# Personal Dev Container (Ubuntu Noble + Zsh)

这是我的个人开发容器配置，仅自用，不保证通用性与兼容性。内容尽量克制，方便我自己发布与拉取使用。

## 特性

- 基础镜像：Ubuntu 24.04 (noble)，默认美国英文环境 `en_US.UTF-8`，时区 `America/New_York`。
- 包管理：APT（`ripgrep`/`bat`/`zoxide`/`zsh-plugins` 等）、NodeSource（Node 24/npm）、官方脚本（bun、nexttrace、fzf、lazygit）。
- 编辑器：内置最新版 Neovim（Tarball），配置 AstroNvim，包含 Mason 所需运行时（Python）。
- 终端复用器：tmux，配置文件来自个人 dotfiles。
- Shell：默认进入 zsh（Oh My Zsh 在 root 下启用，常用插件与别名已配置）。
- 构建发布：支持本地构建，也可用 GitHub Actions 推送到 GHCR 以便拉取。
- 额外 CLI：全局安装 `@openai/codex`、`@anthropic-ai/claude-code`、`zcode-app-cli` 与 Pi（`@earendil-works/pi-coding-agent`）。
- Pi 基础插件：预装 `pi-open-tui`、`@juicesharp/rpiv-ask-user-question`、`pi-web-access`、`pi-background-tasks`。

## 主要文件

- `Dockerfile`：镜像定义（无代理、无字体）。
- `.zshrc`、`.vimrc`：根目录下的个人配置，构建时复制到容器中。
- `.dockerignore`：裁剪构建上下文。
- `.github/workflows/docker.yml`：CI 构建并推送到 `ghcr.io/<owner>/<repo>`。

## 本地构建与运行

- 构建：`docker build -t <repo>:latest .`
- 进入：`docker run -it --rm <repo>:latest`（默认 zsh，工作目录为 `~`）
- 挂载本地目录：`docker run -it --rm -v $(pwd):/workspace <repo>:latest`
- 指定 bash：`docker run -it --rm --entrypoint /bin/bash <repo>:latest`
- 一次性命令：`docker run --rm <repo>:latest -lc 'node -v'`

说明：环境通过 APT/官方脚本/NodeSource 管理与安装。

## Pi agent

构建时安装最新版 Pi 和上述 4 个插件。AI CLI 安装顺序为 Pi 本体 → Codex → zcode → Pi 插件 → Claude Code，各段通过 npm 版本元数据检测更新。只有 Pi 插件更新时，可复用前面的 Pi 本体、Codex 和 zcode 安装缓存，重新构建插件段及后续层；只有 Claude Code 更新时，可复用前面的所有安装层缓存。

进入项目目录后运行 `pi`，首次使用可通过 `/login` 配置模型服务，再用 `/model` 选择模型。

- `pi list`：查看已配置的插件。
- `pi config`：管理加载的插件资源。
- `pi update`：更新 Pi 本体。
- `pi update --extensions`：更新插件。
- `/open-tui`：在 Pi 内调整界面、设置语言和图标；终端图标显示异常时可选择 ASCII。
- `/bg <命令>`：启动后台 shell 任务；用 `/jobs` 查看任务，`/logs <任务 ID>` 查看输出。

插件安装及配置位于 `/root/.pi/agent`，会话和登录信息也保存在该目录。容器使用 `--rm` 时，如需保留这些数据，可添加 `-v pi-agent:/root/.pi/agent` 使用命名卷。首次使用空命名卷会复制镜像中的预装内容；已有卷会保留原有内容，需在容器内运行更新命令。直接绑定宿主机空目录会遮住镜像中的插件和配置，需要重新执行 `pi install`。

`pi-web-access` 使用默认配置：浏览器 Cookie 访问关闭，搜索工作流为 `none`，不额外调用摘要模型。

镜像通过 `ENV PI_BG_FEATURES=process` 将 `pi-background-tasks` 设为仅启用后台进程管理，保留后台命令、日志、状态、终止任务和完成通知，关闭其委派、Fusion、运行证明及 Anthropic attribution 功能。直接运行 `pi` 即生效，zsh 和非交互启动均继承此设置。该开关不限制任务的内存或并发。`pi-subagents`、LSP 及其他可选插件暂不预装。

安装和管理方式见 [Pi 官方快速开始](https://pi.dev/docs/latest/quickstart)及[包管理文档](https://pi.dev/docs/latest/packages)。

## 通过 GHCR 使用

- 推送到 `master` 分支得到 `:latest`，打 tag 得到对应版本。
- 登录：`echo <GITHUB_TOKEN> | docker login ghcr.io -u <USERNAME> --password-stdin`
- 拉取：`docker pull ghcr.io/<owner>/<repo>:latest`

## 常用操作（小抄）

- 覆盖入口为 bash：`docker run -it --rm --entrypoint /bin/bash ghcr.io/<owner>/<repo>:latest`
- 一次性命令（不依赖 `.zshrc`）：`docker run --rm ghcr.io/<owner>/<repo>:latest -lc 'node -v'`
- 一次性命令（需要加载 `.zshrc`）：`docker run --rm ghcr.io/<owner>/<repo>:latest -lic 'your cmd'`
  - 说明：`-l` 登录 shell，读登录文件；`-i` 交互，读 `.zshrc`；`-c` 执行字符串命令。
  - Neovim：配置位于 `~/.config/nvim`（AstroNvim），已安装 Mason 所需的 Python 运行时
  - tmux：配置位于 `~/.config/tmux`
  - 更新配置：`cd ~/dotfiles && git pull && git submodule update --remote`
  - Python：APT 安装 python3/pip/venv（支持 Mason 安装 Python 工具）
  - Node/npm：来自 NodeSource（Node 24.x）
  - yq：APT 安装，YAML 处理工具
  - zoxide：APT 安装，Oh My Zsh 插件启用
  - fzf：官方脚本安装，Oh My Zsh 插件启用
  - lazygit：官方最新版安装，终端 Git UI 工具
  - bun：官方脚本安装并放到 `/usr/local/bin/bun`
  - nexttrace：官方一键脚本安装

## 说明

- 这是私人配置，随时调整，不提供支持与稳定性承诺。
- 未内置字体与代理。如需图标与字体效果，请在宿主机终端自行配置；网络代理请在容器内按需手动设置。
