FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERRAFORM_LATEST_VERSION=1.11.2
ENV PACKER_LATEST_VERSION=1.11.2
ENV VAULT_LATEST_VERSION=1.19.0
ENV HELMFILE_VERSION=0.171.0

RUN apt-get update && \
    apt-get install -y curl wget unzip tar python3 python3-pip python3-apt \
        apt-transport-https ca-certificates software-properties-common git gh tree\
        direnv sshpass vim rsync openssh-client jq yq xorriso apache2-utils dos2unix && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu noble stable" && \
    apt-get update && \
    apt-get install -y docker-ce docker-compose-plugin && \
    apt-get clean all

RUN curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_LATEST_VERSION}/terraform_${TERRAFORM_LATEST_VERSION}_linux_amd64.zip" \
    -o "/tmp/terraform_linux_amd64.zip" && \
    unzip -o "/tmp/terraform_linux_amd64.zip" -d /usr/local/bin/ && \
    rm "/tmp/terraform_linux_amd64.zip"

RUN curl -fsSL "https://releases.hashicorp.com/packer/${PACKER_LATEST_VERSION}/packer_${PACKER_LATEST_VERSION}_linux_amd64.zip" \
    -o "/tmp/packer_linux_amd64.zip" && \
    unzip -o "/tmp/packer_linux_amd64.zip" -d /usr/local/bin/ && \
    rm "/tmp/packer_linux_amd64.zip"

RUN curl -fsSL "https://releases.hashicorp.com/vault/${VAULT_LATEST_VERSION}/vault_${VAULT_LATEST_VERSION}_linux_amd64.zip" \
    -o "/tmp/vault_linux_amd64.zip" && \
    unzip -o "/tmp/vault_linux_amd64.zip" -d /usr/local/bin/ && \
    rm "/tmp/vault_linux_amd64.zip"

RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o "/tmp/awscliv2.zip" && \
    unzip -o "/tmp/awscliv2.zip" -d /tmp && \
    /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update && \
    rm -rf /tmp/awscliv2.zip

RUN KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) && \
    curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

RUN curl "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" | bash

RUN helm plugin install https://github.com/databus23/helm-diff

RUN curl -fsSL "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz" \
    -o /tmp/helmfile.tar.gz && \
    tar -xzf /tmp/helmfile.tar.gz -C /tmp && \
    mv /tmp/helmfile /usr/local/bin/ && chmod +x /usr/local/bin/helmfile

RUN curl -fsSL "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64" \
    -o /usr/local/bin/argocd && chmod +x /usr/local/bin/argocd

RUN arch=$(uname -m) && \
    [ "$arch" = "x86_64" ] && arch=amd64 && \
    os=$(uname -s | tr '[:upper:]' '[:lower:]') && \
    curl -L -o kargo "https://github.com/akuity/kargo/releases/latest/download/kargo-${os}-${arch}" && \
    chmod +x kargo && \
    mv kargo /usr/local/bin/kargo
