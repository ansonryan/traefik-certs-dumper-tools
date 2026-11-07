# syntax=docker/dockerfile:1
#
# traefik-certs-dumper + curl / openssl / jq
#
# 上游 ldez/traefik-certs-dumper 基于 Alpine 精简镜像，只带二进制（jq 已内置），
# 但很多人的 entrypoint 还会 shell out 去调用：
#   - curl    → 通过 docker.sock 调 API（例如把 traefik 接入 bridge 网络）
#   - openssl → 由 pem 生成 pfx（Windows / IIS / Emby 等）
# 本镜像只做一件事：把这两个命令补齐，二进制与上游完全一致。
#
# 升级上游：只改下面这一行的 tag（Renovate 也会提 PR），workflow 会自动读出 tag 当镜像标签。

FROM ldez/traefik-certs-dumper:v2.11.4

RUN apk add --no-cache curl openssl jq

LABEL org.opencontainers.image.title="traefik-certs-dumper-tools" \
      org.opencontainers.image.description="Upstream traefik-certs-dumper with curl/openssl/jq preinstalled for entrypoints that shell out" \
      org.opencontainers.image.licenses="Apache-2.0"

# 构建期冒烟测试：命令都在，且 v3 解析器可用
RUN set -eux; \
    for b in curl openssl jq traefik-certs-dumper; do command -v "$b"; done; \
    traefik-certs-dumper file --help | grep -q "'v3'"
