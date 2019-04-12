FROM ubuntu:18.04

# Packages
RUN apt-get update && apt-get install --no-install-recommends -y \
    gpg \
    curl \    
    lsb-release \
    add-apt-key \
    ca-certificates \    
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

# Kubectl CLI
ENV KUBECTL_VERSION="v1.12.7"
RUN curl -sL "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

# Common SDK
RUN apt-get update && apt-get install --no-install-recommends -y \
    git \
    sudo \
    wget \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Golang SDK
ENV GO_VERSION="1.12.2"
RUN curl -sL https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz | tar -xz -C /usr/local

# Code-Server
RUN apt-get update && apt-get install --no-install-recommends -y \
    bsdtar \
    openssl \
    locales \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

ENV CODE_VERSION="1.696-vsc1.33.0"
RUN curl -sL https://github.com/codercom/code-server/releases/download/${CODE_VERSION}/code-server${CODE_VERSION}-linux-x64.tar.gz | tar --strip-components=1 -zx -C /usr/local/bin code-server${CODE_VERSION}-linux-x64/code-server

# Setup User
RUN groupadd -r coder \
    && useradd -u 1000 -m -r coder -g coder -s /bin/bash \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
USER coder

# Setup User Profile
ENV LC_ALL=en_US.UTF-8

# Setup User Go Environment
RUN mkdir /home/coder/go
ENV GOPATH "/home/coder/go"
ENV PATH "${PATH}:/usr/local/go/bin:/home/coder/go/bin"

# Setup User Visual Studio Code Extentions
ENV VSCODE_EXTENSIONS "/home/coder/.local/share/code-server/extensions"

# Setup Go Extension
RUN mkdir -p ${VSCODE_EXTENSIONS}/go \
    && curl -JLs --retry 5 https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-vscode/vsextensions/Go/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/go extension

RUN go get -u \
    github.com/mdempsky/gocode \
    github.com/uudashr/gopkgs/cmd/gopkgs \
    github.com/ramya-rao-a/go-outline \
    github.com/acroca/go-symbols \
    golang.org/x/tools/cmd/guru \
    golang.org/x/tools/cmd/gorename \
    github.com/go-delve/delve/cmd/dlv \
    github.com/stamblerre/gocode \
    github.com/rogpeppe/godef \
    github.com/sqs/goreturns \
    golang.org/x/lint/golint \
    && rm -rf $GOPATH/src \
    && rm -rf $GOPATH/pkg

RUN go get -u \
    github.com/stamblerre/gocode \
    github.com/uudashr/gopkgs/cmd/gopkgs \
    && rm -rf $GOPATH/src \
    && rm -rf $GOPATH/pkg

# Setup Kubernetes Extension
RUN mkdir -p ${VSCODE_EXTENSIONS}/yaml \
    && curl -JLs --retry 5 https://marketplace.visualstudio.com/_apis/public/gallery/publishers/redhat/vsextensions/vscode-yaml/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/yaml extension

RUN mkdir -p ${VSCODE_EXTENSIONS}/kubernetes \
    && curl -JLs --retry 5 https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-kubernetes-tools/vsextensions/vscode-kubernetes-tools/latest/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/kubernetes extension

# Setup Vim Extension
RUN mkdir -p ${VSCODE_EXTENSIONS}/vim \
    && curl -JLs --retry 5 https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vscodevim/vsextensions/vim/1.4.0/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/vim extension

# Install Bluloco Light Theme
RUN mkdir -p ${VSCODE_EXTENSIONS}/blueloco \
    && curl -JLs --retry 5 https://marketplace.visualstudio.com/_apis/public/gallery/publishers/uloco/vsextensions/theme-bluloco-light/2.7.2/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/blueloco extension

# Setup User Workspace
RUN mkdir -p /home/coder/project
WORKDIR /home/coder/project

ENTRYPOINT ["dumb-init", "code-server"]
