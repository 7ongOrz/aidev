FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Shanghai \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    TERM=xterm-256color

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# 基础依赖 + 常用工具（APT）
RUN set -eux; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        tzdata \
        locales \
        sudo \
        curl \
        wget \
        rsync \
        git \
        openssh-client \
        vim \
        zsh \
        tmux \
        file \
        entr \
        unzip \
        zip \
        pigz \
        less \
        gnupg \
        traceroute \
        iputils-ping \
        bind9-dnsutils \
        mtr-tiny \
        htop \
        jq \
        yq \
        git-lfs \
        p7zip-full \
        tree \
        net-tools \
        build-essential \
        python3 \
        python3-pip \
        python3-venv \
        procps \
        ripgrep \
        bat \
        zsh-autosuggestions \
        zsh-syntax-highlighting \
        zoxide; \
    sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen; \
    locale-gen zh_CN.UTF-8; \
    update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8; \
    apt-get clean; \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# 安装 Oh My Zsh
RUN set -eux; \
    export ZSH="/root/.oh-my-zsh"; \
    git clone --depth=1 --single-branch https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"

# 安装 fzf（官方脚本，安装后清理缓存）
RUN set -eux; \
    git clone --depth 1 --single-branch https://github.com/junegunn/fzf.git ~/.fzf; \
    ~/.fzf/install --bin --no-update-rc; \
    install -m 0755 ~/.fzf/bin/fzf /usr/local/bin/fzf; \
    rm -rf ~/.fzf

# 安装 lazygit（最新版）
RUN set -eux; \
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*'); \
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz"; \
    tar xf lazygit.tar.gz lazygit; \
    install lazygit /usr/local/bin; \
    rm lazygit lazygit.tar.gz; \
    lazygit --version

# 安装 .NET 8 SDK
RUN set -eux; \
    wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb; \
    dpkg -i packages-microsoft-prod.deb; \
    rm packages-microsoft-prod.deb; \
    apt-get update; \
    apt-get install -y --no-install-recommends dotnet-sdk-8.0; \
    apt-get clean; \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*; \
    dotnet --version

# 安装 Node.js（NodeSource 24.x）
RUN set -eux; \
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -; \
    apt-get install -y --no-install-recommends nodejs; \
    rm -rf /var/lib/apt/lists/*

# 安装 bun（官方脚本，系统路径）
ENV BUN_INSTALL=/usr/local/bun
RUN set -eux; \
    bash -lc 'curl -fsSL https://bun.sh/install | bash'; \
    ln -sf /usr/local/bun/bin/bun /usr/local/bin/bun; \
    bun --version

# 安装 nexttrace（官方一键脚本）
RUN set -eux; \
    curl -sL nxtrace.org/nt | bash; \
    nexttrace --version

# 安装 Neovim 最新版（Tarball）
RUN set -eux; \
    curl -L https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz \
        | tar -C /opt -xz; \
    ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim; \
    nvim --version

# 当 dotfiles 有更新时自动破坏缓存
ADD https://api.github.com/repos/7ongOrz/dotfiles/commits?sha=main&per_page=1 /tmp/dotfiles-version.json
# 克隆 dotfiles 配置（nvim 和 tmux，包含子模块）
RUN set -eux; \
    rm -f /tmp/dotfiles-version.json; \
    git clone --depth=1 --recurse-submodules --shallow-submodules \
        https://github.com/7ongOrz/dotfiles.git /root/dotfiles; \
    mkdir -p /root/.config; \
    ln -s /root/dotfiles/nvim /root/.config/nvim; \
    ln -s /root/dotfiles/tmux /root/.config/tmux

# 预装 tmux 插件
RUN set -eux; \
    "${HOME}/.config/tmux/plugins/tpm/bin/install_plugins"

# 预装 Neovim 插件、Mason 工具和 TreeSitter parsers
RUN set -eux; \
    DOCKER_BUILD=1 nvim --headless "+Lazy! sync" +qa >/dev/null && \
    nvim --headless "+Lazy! load mason-tool-installer.nvim" "+MasonInstallAll" +qa >/dev/null; \
    rm -rf "${HOME}/.cache/nvim" "${HOME}/.local/state/nvim"

# 当 npm 包有更新时自动破坏缓存（放在最后以减少缓存失效影响）
ADD https://registry.npmjs.org/@openai/codex/latest /tmp/codex.json
ADD https://registry.npmjs.org/@anthropic-ai/claude-code/latest /tmp/claude.json
RUN set -eux; \
    rm -f /tmp/*.json; \
    npm install -g @openai/codex @anthropic-ai/claude-code; \
    npm cache clean --force

COPY .vimrc /root/.vimrc
COPY .zshrc /root/.zshrc

WORKDIR /root

# 切换默认 shell 为 zsh
RUN chsh -s /usr/bin/zsh root

# 默认进入交互式 zsh；如需运行命令，可 docker run ... zsh -lc "cmd"
ENTRYPOINT ["/usr/bin/zsh"]
CMD ["-l"]
