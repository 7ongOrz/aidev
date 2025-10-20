# Personal Dev Container (Ubuntu Noble + Zsh)

这是我的个人开发容器配置，仅自用，不保证通用性与兼容性。内容尽量克制，方便我自己发布与拉取使用。

## 特性
- 基础镜像：Ubuntu 24.04 (noble)，默认中文环境 `zh_CN.UTF-8`。
- 包管理：APT（`ripgrep`/`bat`/`zoxide`/`zsh-plugins` 等）、NodeSource（Node 24/npm）、官方脚本（bun、nexttrace、fzf）。
- 编辑器：内置最新版 Neovim（AppImage），配置 AstroNvim。
- Shell：默认进入 zsh（Oh My Zsh 在 root 下启用，常用插件与别名已配置）。
- 构建发布：支持本地构建，也可用 GitHub Actions 推送到 GHCR 以便拉取。
- 额外 CLI：全局安装 `@openai/codex` 与 `@anthropic-ai/claude-code`。

## 主要文件
- `Dockerfile`：镜像定义（无代理、无字体）。
- `.zshrc`、`.vimrc`：根目录下的个人配置，构建时复制到容器中。
- `.dockerignore`：裁剪构建上下文。
- `.github/workflows/docker.yml`：CI 构建并推送到 `ghcr.io/<owner>/<repo>`。

## 本地构建与运行
- 构建：`docker build -t <repo>:latest .`
- 进入：`docker run -it --rm -v $(pwd):/workspace <repo>:latest`（默认 zsh）
- 指定 bash：`docker run -it --rm --entrypoint /bin/bash <repo>:latest`
- 一次性命令：`docker run --rm <repo>:latest -lc 'node -v'`

说明：环境通过 APT/官方脚本/NodeSource 管理与安装。

## 通过 GHCR 使用
- 推送到 `master` 分支得到 `:latest`，打 tag 得到对应版本。
- 登录：`echo <GITHUB_TOKEN> | docker login ghcr.io -u <USERNAME> --password-stdin`
- 拉取：`docker pull ghcr.io/<owner>/<repo>:latest`

## 常用操作（小抄）
- 覆盖入口为 bash：`docker run -it --rm --entrypoint /bin/bash ghcr.io/<owner>/<repo>:latest`
- 一次性命令（不依赖 `.zshrc`）：`docker run --rm ghcr.io/<owner>/<repo>:latest -lc 'node -v'`
- 一次性命令（需要加载 `.zshrc`）：`docker run --rm ghcr.io/<owner>/<repo>:latest -lic 'your cmd'`
  - 说明：`-l` 登录 shell，读登录文件；`-i` 交互，读 `.zshrc`；`-c` 执行字符串命令。
  - Neovim：AppImage 方式安装最新版，配置位于 `~/.config/nvim`（AstroNvim）
  - Node/npm：来自 NodeSource（Node 24.x）
  - zoxide：APT 安装，Oh My Zsh 插件启用
  - fzf：官方脚本安装，Oh My Zsh 插件启用
  - bun：官方脚本安装并放到 `/usr/local/bin/bun`
  - nexttrace：官方一键脚本安装

## 说明
- 这是私人配置，随时调整，不提供支持与稳定性承诺。
- 未内置字体与代理。如需图标与字体效果，请在宿主机终端自行配置；网络代理请在容器内按需手动设置。
