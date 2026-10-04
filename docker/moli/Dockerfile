# moli 官方未发布 Docker 镜像,本 Dockerfile 用其 GitHub Release 二进制打包。
# 依赖来源:ldd 实测(libstdc++/libfontconfig/libz/libgcc/libm/libc);
# fonts-noto-cjk 供 --layout 截图/渲染中文页面使用。
# 构建参数:MOLI_VERSION(如 1.1.12),多架构经 TARGETARCH 映射 release 三元组。
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl libstdc++6 libfontconfig1 fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
ARG MOLI_VERSION
RUN case "${TARGETARCH}" in \
      amd64) TRIPLE=x86_64-unknown-linux-gnu ;; \
      arm64) TRIPLE=aarch64-unknown-linux-gnu ;; \
      *) echo "unsupported arch: ${TARGETARCH}" >&2; exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/lexmount/moli/releases/download/v${MOLI_VERSION}/moli-${TRIPLE}.tar.gz" \
      | tar xz -C /tmp && \
    install -m 0755 "/tmp/moli-v${MOLI_VERSION}-${TRIPLE}/moli" /usr/local/bin/moli && \
    rm -rf /tmp/moli-v* && \
    moli --version

ENV HOME=/tmp
USER 65534
EXPOSE 9222
CMD ["moli", "serve", "--host", "0.0.0.0", "--port", "9222", "--layout", "--resource"]
