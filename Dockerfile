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
        git \
        vim \
        zsh \
        file \
        unzip \
        zip \
        less \
        gnupg \
        traceroute \
        iputils-ping \
        bind9-dnsutils \
        mtr-tiny \
        htop \
        jq \
        git-lfs \
        p7zip-full \
        tree \
        net-tools \
        build-essential \
        python3 \
        python3-pip \
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
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"; \
    true

# 安装 fzf（官方脚本，安装后清理缓存）
RUN set -eux; \
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf; \
    ~/.fzf/install --bin --no-update-rc; \
    install -m 0755 ~/.fzf/bin/fzf /usr/local/bin/fzf; \
    rm -rf ~/.fzf

# 安装 Node.js（NodeSource 24.x）
RUN set -eux; \
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -; \
    apt-get install -y --no-install-recommends nodejs; \
    npm --version; \
    npm install -g @openai/codex @anthropic-ai/claude-code; \
    npm cache clean --force || true; \
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
    command -v nexttrace >/dev/null 2>&1 || true

WORKDIR /workspace
COPY .vimrc /root/.vimrc
COPY .zshrc /root/.zshrc

# 切换默认 shell 为 zsh
RUN chsh -s /usr/bin/zsh root

# 默认进入交互式 zsh；如需运行命令，可 docker run ... zsh -lc "cmd"
ENTRYPOINT ["/usr/bin/zsh"]
CMD ["-l"]
