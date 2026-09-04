# Base image (OS) - private ECR; update BASE_IMAGE_TAG manually or via CI
ARG BASE_IMAGE_TAG=13.3
ARG ECR_REGISTRY=716533421362.dkr.ecr.us-east-1.amazonaws.com
ARG BASE_IMAGE_NAME=phenompeople/debian-custom
FROM ${ECR_REGISTRY}/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

ARG BASE_IMAGE_TAG
ARG ECR_REGISTRY
ARG BASE_IMAGE_NAME

LABEL com.phenom.sub.base.image="716533421362.dkr.ecr.us-east-1.amazonaws.com/phenompeople/golang-custom:1.25" \
      com.phenom.base.image="${ECR_REGISTRY}/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}" \
      com.phenom.fedramp.compliant=true

ARG APP_HOME=/go
# renovate: datasource=golang-version depName=golang
ARG GOLANG_VERSION=1.27.1

ENV GOLANG_VERSION=${GOLANG_VERSION}
ENV GOTOOLCHAIN="local"
ENV GOPATH="/go"
ENV PATH="$GOPATH/bin:/usr/local/go/bin:$PATH"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    DPKG_ARCH=$(dpkg --print-architecture); \
    case "${DPKG_ARCH}" in \
        amd64) \
            url="https://dl.google.com/go/go${GOLANG_VERSION}.linux-amd64.tar.gz"; \
            sha256="f022b6aad78e362bcba9b0b94d09ad58c5a70c6ba3b7582905fababf5fe0181a"; \
            ;; \
        arm64) \
            url="https://dl.google.com/go/go${GOLANG_VERSION}.linux-arm64.tar.gz"; \
            sha256="738ef87d79c34272424ccdf83302b7b0300b8b096ed443896089306117943dd5"; \
            ;; \
        *) echo "Unsupported architecture: ${DPKG_ARCH}" && exit 1 ;; \
    esac; \
    apt-get update && apt-get install -y --no-install-recommends gnupg curl; \
    curl -fsSL -o go.tgz.asc "$url.asc"; \
    curl -fsSL -o go.tgz "$url"; \
    echo "$sha256 *go.tgz" | sha256sum -c -; \
    GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys \
        'EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796' \
        '2F528D36D67B69EDF998D85778BD65473CB3BD13'; \
    gpg --batch --verify go.tgz.asc go.tgz; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" go.tgz.asc; \
    tar -C /usr/local -xzf go.tgz; \
    rm go.tgz; \
    apt-get purge -y curl gnupg; \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*; \
    > /var/log/dpkg.log 2>/dev/null || true; \
    > /var/log/apt/term.log 2>/dev/null || true; \
    > /var/log/apt/history.log 2>/dev/null || true; \
    > /var/cache/ldconfig/aux-cache 2>/dev/null || true; \
    mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 1777 "$GOPATH"; \
    go version

WORKDIR ${APP_HOME}

HEALTHCHECK NONE

USER phenom

CMD ["go"]
