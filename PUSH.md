# 发布与升级

本仓库已发布：`ghcr.io/ansonryan/traefik-certs-dumper-tools`（public）。

## 升级上游版本

只改一处 —— `Dockerfile` 的 `FROM` 行：

```dockerfile
FROM ldez/traefik-certs-dumper:v2.11.4      # ← 改成新 tag
```

提交推送后 workflow 自动构建，产出 `:<去掉 v 的版本>-tools` 与 `:latest`。
Renovate 也会盯上游提 PR，通常不用手动改。

## 本地构建 / 验证

```bash
docker build -t traefik-certs-dumper-tools:dev .
docker run --rm --entrypoint sh traefik-certs-dumper-tools:dev -c \
  'command -v curl openssl jq traefik-certs-dumper; traefik-certs-dumper file --help | grep -c v3'
```

## 消费端（Unraid 实测 9 秒拉完）

```bash
docker pull ghcr.io/ansonryan/traefik-certs-dumper-tools:2.11.4-tools
```

compose 里直接写全名即可，public 包不需要 `docker login`。

## 推送注意事项

- 推 `.github/workflows/*` 需要 token 带 **Workflows: Read and write**（细粒度）或 classic 的 `workflow` scope。
- 本机若设了 `HTTPS_PROXY`，git 会被代理卡住，用 `git -c http.proxy= -c https.proxy= push ...` 绕过。
