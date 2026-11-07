# traefik-certs-dumper-tools

`ldez/traefik-certs-dumper` 的极小派生镜像：**只补 `curl`、`openssl`、`jq` 三个命令，二进制与上游完全一致。**

## 为什么会有这个仓库

上游镜像基于 Alpine 精简版，只带 `traefik-certs-dumper` 二进制（`jq` 已内置）。但不少人的 entrypoint 还会调用宿主机的东西：

| 命令 | 典型用途 |
|---|---|
| `curl` | 通过 `docker.sock` 调 Docker API，例如把 `traefik` 接入 `bridge` 网络（`POST /networks/bridge/connect`） |
| `openssl` | 由 `fullchain.cer` + `privkey.key` 生成 `privkey.pfx`（Windows / IIS / Emby 用） |
| `jq` | 等待循环里判断 `acme.json` 是否已有证书 |

缺这些命令时容器不会报「镜像有问题」，而是在 entrypoint 里抛 `curl: not found` 继续跑，表面正常、实际少了一半功能——所以单独做个镜像把坑补上。

## 与上游的差异

只有两行：

```dockerfile
FROM ldez/traefik-certs-dumper:v2.11.4
RUN apk add --no-cache curl openssl jq
```

外加构建期冒烟测试（确认三个命令存在、且 `--version v3` 可用）。**没有改动任何二进制、没有打补丁。**

## 用法

```yaml
services:
  traefik-certs-dumper:
    image: ghcr.io/<OWNER>/traefik-certs-dumper-tools:2.11.4-tools
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik:/data:ro
      - ./certs:/certs
    entrypoint: sh -c '
      /data/connect-docker-network.sh
      ; while ! [ -e /data/acme.json ]
      || ! [ `jq ".[] | .Certificates | length" /data/acme.json` != 0 ]; do
      sleep 1
      ; done
      && traefik-certs-dumper file --version v3 --watch
      --source /data/acme.json --dest /certs --clean=false
      --domain-subdir --key-name=privkey --key-ext=.key
      --crt-name=fullchain --crt-ext=.cer
      --post-hook "sh /data/traefik-certs-dumper-hook.sh"'
```

> `--version` 必须与你的 Traefik 大版本一致。Traefik v3 的 `acme.json` 带 `KeyType`，用 `v2` 解析会 `panic: unsupported key type: 'RSA4096'`。

## 升级上游

改 `Dockerfile` 的 `ARG UPSTREAM` 与 workflow 的 `env.UPSTREAM`，或者让 Renovate 提 PR（仓库已带 `renovate.json`）。

本地构建：

```bash
docker build -t traefik-certs-dumper-tools:dev --build-arg UPSTREAM=v2.11.4 .
docker run --rm --entrypoint sh traefik-certs-dumper-tools:dev -c \
  'command -v curl openssl jq traefik-certs-dumper'
```

## 许可

上游 [ldez/traefik-certs-dumper](https://github.com/ldez/traefik-certs-dumper) 为 **Apache-2.0**（`Copyright 2019-2024 Fernandez Ludovic`）。
本仓库仅在其镜像基础上增装软件包，遵循同一许可；分发时请保留上游的 LICENSE 与版权声明，并注明上述改动。
