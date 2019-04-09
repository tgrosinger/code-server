FROM ubuntu:18.04

# Packages
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    locales \
    openssl \
    net-tools \
    lsb-release \
    ca-certificates \
    gpg \
    bsdtar \
    add-apt-key \
    apt-transport-https \    
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

# CF CLI
ENV CF_VERSION="6.43.0"
RUN curl -sL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_VERSION}&source=github-rel" | tar -zx -C /usr/local/bin

# HELM CLI
ENV HELM_VERSION="v2.13.1"
RUN curl -sL "https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz" | tar --strip-components=1 -zx -C /usr/local/bin

# Kubectl CLI
ENV KUBECTL_VERSION="v1.12.7"
RUN curl -sL "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

# Azure CLI
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list
RUN apt-get update && apt-get install -y \
    azure-cli \
    && rm -rf /var/lib/apt/lists/*

# Common SDK
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Node SDK
RUN curl -sL https://deb.nodesource.com/setup_11.x | bash -
RUN apt-get update && apt-get install -y \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# Golang SDK
ENV GO_VERSION="1.12.2"
RUN curl -sL https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz | tar -xz -C /usr/local

# Java SDK
RUN apt-get update && apt-get install --no-install-recommends -y \
    default-jre \
    default-jdk \
    maven \
    && rm -rf /var/lib/apt/lists/*

# .NET Core SDK
# RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
# RUN echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/18.04/prod $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/microsoft-prod.list
# RUN apt-get update && apt-get install -y \
#    libunwind8 \
#    dotnet-sdk-2.2 \
#    && rm -rf /var/lib/apt/lists/*

# Chromium
RUN apt-get update && apt-get install --no-install-recommends -y \
    chromium-browser \
    && rm -rf /var/lib/apt/lists/*

# Code-Server
ENV CODE_VERSION="1.696-vsc1.33.0"
RUN curl -sL https://github.com/codercom/code-server/releases/download/${CODE_VERSION}/code-server${CODE_VERSION}-linux-x64.tar.gz | tar --strip-components=1 -zx -C /usr/local/bin code-server${CODE_VERSION}-linux-x64/code-server

# Setup OS
RUN locale-gen en_US.UTF-8

# Setup User
RUN groupadd -r coder \
    && useradd -m -r coder -g coder -s /bin/bash \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
USER coder

ENV LC_ALL=en_US.UTF-8

# Setup User Go Environment
RUN mkdir /home/coder/go
ENV GOPATH "/home/coder/go"
ENV PATH "${PATH}:/usr/local/go/bin:/home/coder/go/bin"

# Setup Uset .NET Environment
# ENV DOTNET_CLI_TELEMETRY_OPTOUT "true"
# ENV MSBuildSDKsPath "/usr/share/dotnet/sdk/2.2.202/Sdks"
# ENV PATH "${PATH}:${MSBuildSDKsPath}"

# Setup User Visual Studio Code Extentions
RUN mkdir -p /home/coder/.local/share/code-server/extensions/
ENV VSCODE_EXTENSIONS "/home/coder/.local/share/code-server/extensions"

# Setup Go Extension
RUN mkdir -p ${VSCODE_EXTENSIONS}/go \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-vscode/vsextensions/Go/0.9.2/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/go extension

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

# Setup Java Extension

RUN mkdir -p ${VSCODE_EXTENSIONS}/java \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/redhat/vsextensions/java/0.42.1/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/java extension

RUN mkdir -p ${VSCODE_EXTENSIONS}/java-debugger \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vscjava/vsextensions/vscode-java-debug/0.17.0/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/java-debugger extension

RUN mkdir -p ${VSCODE_EXTENSIONS}/java-test \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vscjava/vsextensions/vscode-java-test/0.15.1/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/java-test extension

RUN mkdir -p ${VSCODE_EXTENSIONS}/maven \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vscjava/vsextensions/vscode-maven/0.16.0/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/maven extension

# Setup Kubernetes Extension
RUN mkdir -p ${VSCODE_EXTENSIONS}/yaml \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/redhat/vsextensions/vscode-yaml/0.4.0/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/yaml extension

RUN mkdir -p ${VSCODE_EXTENSIONS}/kubernetes \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-kubernetes-tools/vsextensions/vscode-kubernetes-tools/0.1.18/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/kubernetes extension

# Setup Chrome Preview
RUN mkdir -p ${VSCODE_EXTENSIONS}/chrome-debugger \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/msjsdiag/vsextensions/debugger-for-chrome/4.11.3/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/chrome-debugger extension

RUN mkdir -p ${VSCODE_EXTENSIONS}/chrome-preview \
    && curl -JLs https://marketplace.visualstudio.com/_apis/public/gallery/publishers/auchenberg/vsextensions/vscode-browser-preview/0.4.0/vspackage | bsdtar --strip-components=1 -xf - -C ${VSCODE_EXTENSIONS}/chrome-preview extension

# Setup User Workspace
RUN mkdir -p /home/coder/project
WORKDIR /home/coder/project

ENTRYPOINT ["dumb-init", "code-server"]