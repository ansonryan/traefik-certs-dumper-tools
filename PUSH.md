# 推到 GitHub 并启用 GHCR

## 0. 先换 PAT（重要）

旧的 `ghp_RHVr…` 之前标记过泄露，**先轮换**，只改这两处：

- `~/.github_token`
- `~/.git-credentials`

## 1. 建仓并推

```bash
cd gh-traefik-certs-dumper
git init -b main
git add .
git commit -m "traefik-certs-dumper + curl/openssl/jq"
gh repo create traefik-certs-dumper-tools --private --source=. --push
```

不装 `gh` 也行：网页建空仓，然后

```bash
git remote add origin git@github.com:<OWNER>/traefik-certs-dumper-tools.git
git push -u origin main
```

## 2. 首次构建

推上去后 `.github/workflows/build.yml` 自动跑，产出：

```
ghcr.io/<owner>/traefik-certs-dumper-tools:2.11.4-tools
ghcr.io/<owner>/traefik-certs-dumper-tools:latest
```

私有包要登录才能拉：

```bash
echo <PAT> | docker login ghcr.io -u <user> --password-stdin
```

## 3. 让 Unraid 用上它

```bash
docker pull ghcr.io/<owner>/traefik-certs-dumper-tools:2.11.4-tools
docker tag  ghcr.io/<owner>/traefik-certs-dumper-tools:2.11.4-tools \
            local/traefik-certs-dumper:2.11.4-compat
```

或者直接把 compose 里的 image 改成 GHCR 全名（Unraid 需要在
`/root/.docker/config.json` 里有 ghcr 的登录态，否则 compose 拉不到私有包）。
