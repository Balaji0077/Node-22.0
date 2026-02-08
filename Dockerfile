# Base image (OS) - private ECR; update BASE_IMAGE_TAG manually or via CI
ARG BASE_IMAGE_TAG=13.3
ARG ECR_REGISTRY=716533421362.dkr.ecr.us-east-1.amazonaws.com
ARG BASE_IMAGE_NAME=phenompeople/debian-custom
FROM ${ECR_REGISTRY}/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

ARG BASE_IMAGE_TAG
ARG ECR_REGISTRY
ARG BASE_IMAGE_NAME

LABEL com.phenom.sub.base.image="716533421362.dkr.ecr.us-east-1.amazonaws.com/phenompeople/nodejs-custom:22" \
      com.phenom.base.image="${ECR_REGISTRY}/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}" \
      com.phenom.fedramp.compliant=true

ARG APP_HOME=/opt/deployment
ENV NODE_PATH=/usr/local/lib/node_modules
ENV PATH="/usr/local/bin:$PATH"

# renovate: datasource=node-version depName=node
ARG NODE_VERSION=24.13.0
# renovate: datasource=npm depName=npm
ARG NPM_VERSION=11.6.4
# renovate: datasource=npm depName=tar
ARG TAR_VERSION=7.5.7
# renovate: datasource=npm depName=diff
ARG DIFF_VERSION=8.0.3

ENV NODE_VERSION=${NODE_VERSION}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN DPKG_ARCH=$(dpkg --print-architecture) && \
    case "${DPKG_ARCH}" in \
        amd64) NODE_ARCH="x64" ;; \
        arm64) NODE_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: ${DPKG_ARCH}" && exit 1 ;; \
    esac && \
    apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    tar \
    xz-utils && \
    curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz -o node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz && \
    curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt -o SHASUMS256.txt && \
    grep "node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" SHASUMS256.txt | sha256sum -c - && \
    tar -xJf node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz -C /usr/local --strip-components=1 && \
    rm -rf node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz SHASUMS256.txt && \
    npm install -g npm@${NPM_VERSION} && \
    cd /usr/local/lib/node_modules/npm && \
    find . -type d -name "tar" -path "*/node_modules/tar" 2>/dev/null | while read -r tar_dir; do \
        parent="$(dirname "$tar_dir")" && \
        (cd "$parent" && \
         curl -sL "https://registry.npmjs.org/tar/-/tar-${TAR_VERSION}.tgz" -o /tmp/tar-${TAR_VERSION}.tgz 2>/dev/null && \
         rm -rf tar && \
         mkdir -p tar && \
         tar -xzf /tmp/tar-${TAR_VERSION}.tgz -C tar --strip-components=1 2>/dev/null && \
         rm -f /tmp/tar-${TAR_VERSION}.tgz 2>/dev/null || true); \
    done && \
    find . -type d -name "diff" -path "*/node_modules/diff" 2>/dev/null | while read -r diff_dir; do \
        parent="$(dirname "$diff_dir")" && \
        (cd "$parent" && \
         curl -sL "https://registry.npmjs.org/diff/-/diff-${DIFF_VERSION}.tgz" -o /tmp/diff-${DIFF_VERSION}.tgz 2>/dev/null && \
         rm -rf diff && \
         mkdir -p diff && \
         tar -xzf /tmp/diff-${DIFF_VERSION}.tgz -C diff --strip-components=1 2>/dev/null && \
         rm -f /tmp/diff-${DIFF_VERSION}.tgz 2>/dev/null || true); \
    done && \
    cd / && \
    npm cache clean --force && \
    rm -rf /root/.npm /tmp/* && \
    apt-get purge -y curl && \
    apt-get autoremove -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    > /var/log/dpkg.log && \
    > /var/log/apt/term.log && \
    > /var/log/apt/history.log && \
    > /var/cache/ldconfig/aux-cache

WORKDIR ${APP_HOME}

HEALTHCHECK NONE

USER phenom

CMD ["node"]
