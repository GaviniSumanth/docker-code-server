FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config"

RUN \
  echo "**** install runtime dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    git \
    jq \
    libatomic1 \
    nano \
    net-tools \
    netcat \
    sudo && \
  echo "**** install additional packages ****" && \
  apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    openjdk-21-jdk \
    coreutils \
    rename \
    curl \
    wget \
    tree && \
  echo "**** install nvm ****" && \
  nvm_version=$(basename $(curl -fs -o /dev/null -w %{redirect_url} "https://github.com/nvm-sh/nvm/releases/latest")) && \
  export HOME=/opt && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh | bash && \
  echo "**** install code-server ****" && \
  if [ -z ${CODE_RELEASE+x} ]; then \
    CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest \
      | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
  fi && \
  mkdir -p /app/code-server && \
  curl -o \
    /tmp/code-server.tar.gz -L \
    "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-amd64.tar.gz" && \
  tar xf /tmp/code-server.tar.gz -C \
    /app/code-server --strip-components=1 && \
  echo "**** clean up ****" && \
  apt-get clean && \
  rm -rf \
    /config/* \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add nvm to path
RUN echo "export NVM_DIR=\"/opt/.nvm\"" >> /root/.bashrc && \
  echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"" >> /root/.bashrc && \
  echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \. \"\$NVM_DIR/bash_completion\"" >> /root/.bashrc

# install code-server extensions
RUN \
  echo "**** install code-server extensions ****" && \
  /app/code-server/bin/code-server --install-extension ms-python.python && \
  /app/code-server/bin/code-server --install-extension ms-python.black-formatter && \
  /app/code-server/bin/code-server --install-extension ms-toolsai.jupyter && \
  /app/code-server/bin/code-server --install-extension llvm-vs-code-extensions.vscode-clangd && \
  /app/code-server/bin/code-server --install-extension redhat.java && \
  /app/code-server/bin/code-server --install-extension esbenp.prettier-vscode && \
  /app/code-server/bin/code-server --install-extension Gruntfuggly.todo-tree && \
  /app/code-server/bin/code-server --install-extension mhutchie.git-graph && \
  /app/code-server/bin/code-server --install-extension waderyan.gitblame && \
  /app/code-server/bin/code-server --install-extension donjayamanne.githistory

RUN mv ~/.local/share/code-server/extensions /opt/extensions

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443
