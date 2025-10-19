FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Shanghai \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# 基础依赖 + 常用工具
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
        procps; \
    # locale: zh_CN.UTF-8
    sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen; \
    locale-gen zh_CN.UTF-8; \
    update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8; \
    rm -rf /var/lib/apt/lists/*

# 安装 Oh My Zsh
RUN set -eux; \
    export ZSH="/root/.oh-my-zsh"; \
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"; \
    true

# 安装 Homebrew（Linuxbrew）：创建用户（root 阶段）
RUN set -eux; \
    useradd -m -s /bin/bash linuxbrew; \
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/linuxbrew

# 以 linuxbrew 身份执行安装脚本并初始化其 shell（不污染全局）
USER linuxbrew
RUN set -eux; \
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o /home/linuxbrew/install.sh; \
    NONINTERACTIVE=1 /bin/bash /home/linuxbrew/install.sh; \
    rm -f /home/linuxbrew/install.sh; \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/linuxbrew/.zprofile; \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/linuxbrew/.zshrc; \
    echo 'source <(fzf --zsh)' >> /home/linuxbrew/.zshrc; \
    echo 'source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /home/linuxbrew/.zshrc; \
    echo 'source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /home/linuxbrew/.zshrc
USER root

# 将 brew 放入 PATH（对所有后续层生效）
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# 使用 brew 安装常用工具与前端运行时（与 mac 一致）
USER linuxbrew
RUN set -eux; \
    export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1; \
    brew --version; \
    brew install \
      zsh-autosuggestions \
      zsh-syntax-highlighting \
      autojump \
      fzf \
      bat \
      ripgrep \
      nexttrace \
      node \
      bun; \
    npm --version; \
    npm install -g @openai/codex @anthropic-ai/claude-code; \
    brew cleanup -s || true
USER root

# 拷贝项目中的配置（若存在）
WORKDIR /workspace
COPY .vimrc /root/.vimrc
COPY --chown=linuxbrew:linuxbrew .vimrc /home/linuxbrew/.vimrc

# 拷贝并使用仓库内 .zshrc（包含 brew 路径的插件加载方式）
COPY .zshrc /root/.zshrc

# 切换默认 shell 为 zsh
RUN chsh -s /usr/bin/zsh root

# 默认进入交互式 zsh；如需运行命令，可 docker run ... zsh -lc "cmd"
ENTRYPOINT ["/usr/bin/zsh"]
CMD ["-l"]
