# FossilHub 生产运维手册

部署复验日期：2026-08-29

## 当前生产

- 站点：`http://192.168.1.162:6080/`
- 健康检查：`http://192.168.1.162:6080/healthz`
- 容器：`fossilhub`
- 镜像：`fossilhub:2026.08.29-beta.1`
- 镜像 ID：`sha256:24cbe0cf7c50dd6fda05d30d6134c98b53bdf66b8af1ae394ec0eff1528934e8`
- 源码修订标签：`3b88c20`
- 端口：`6080:8080`
- 持久化数据：`/vol1/1000/fossilhub:/data`
- 重启策略：`unless-stopped`

容器以 UID/GID `10001:10001` 运行，根文件系统只读；`/tmp` 为 16 MB 且带 `nosuid,nodev,noexec` 的 tmpfs；全部 Linux capability 已丢弃；启用 `no-new-privileges`；PID 上限 128。容器不使用主机网络、Docker socket 或 fnOS 系统路径。

## 主要路由

| 路由 | 预期结果 |
| --- | --- |
| `/` | FossilHub 首页 |
| `/explore` | 仓库目录与搜索 |
| `/repo/bedrock.fossil` | 仓库概览和时间线 |
| `/repo/bedrock.fossil/files` | 版本化源码树 |
| `/repo/bedrock.fossil/docs` | 文档索引 |
| `/repo/bedrock.fossil/wiki` | 第一方 Wiki |
| `/repo/bedrock.fossil/tickets` | 第一方 Tickets |
| `/repo/bedrock.fossil/forum` | 第一方 Forum |
| `/fossil/bedrock` | 仅供 Fossil clone/sync |
| `/dashboard` | 已登录用户后台 |
| `/admin` | 管理员后台 |
| `/fh.css` | 公共样式 |
| `/healthz` | HTTP 200 和 `ok` |

兼容路径 `/explore.html` 和 `/repo.html` 仍然有效。

## 平台数据

公开目录数据库为 `/data/catalog/fossilhub.sqlite`。平台注册、身份、授权、会话、设置和审计数据库为 `/data/platform/fossilhub.sqlite`。两者都属于应用，可以使用 `sqlite3`；Fossil 仓库文件不得用原始 SQLite 读写。

生产包含 10 个干净仓库：Bedrock、Ammonite、Trilobite、Basalt、Cambrian、Granite、Shale、Quartz、Obsidian 和 Tectonic。每个仓库只有 Fossil 必需的初始空 check-in，未导入演示历史。

Wapp 请求带 CGI 环境变量，因此应用启动的每个 Fossil CLI 查询都必须带 `--nocgi`。浏览器页面不得链接 Fossil 内置 Web UI。`/fossil/<slug>` 只允许活跃公开平台注册仓库进行 clone/sync；`/fossil/` 不列出仓库，私有和未知 slug 在接触文件前统一返回 404。

## 身份与管理员引导

账号密码使用 Argon2id，参数为 `m=32768,t=2,p=1`。密码只通过标准输入传入 Argon2。会话和表单挑战使用随机值，数据库只保存 SHA-256 哈希。密码修改会撤销已有会话并签发新 Cookie。

首次启动会创建中央管理员 `warden`，一次性凭据只写入：

```text
/vol1/1000/fossilhub/platform/fossilhub-bootstrap-admin.txt
```

该文件必须保持 UID/GID 10001:10001、权限 0600。只能在可信交互 SSH 终端读取，禁止通过自动化捕获、日志、工单、提交或回复传播。首次登录后必须立即在 `/account/security` 修改密码：

```sh
sudo cat /vol1/1000/fossilhub/platform/fossilhub-bootstrap-admin.txt
```

HTTPS 请求通过 `HTTPS` 或 `X-Forwarded-Proto` 自动为会话 Cookie 添加 `Secure`。公共 fnOS 反向代理必须保留协议头。`FOSSILHUB_COOKIE_SECURE=always` 用于仅 HTTPS 部署；`never` 只允许隔离 HTTP 烟测。

## 仓库协作与写入

仓库工作区位于 `/account/repositories`。用户可创建公开或私有仓库，并按 Owner、Maintainer、Writer、Triage、Reader 管理元数据和协作者。仓库创建使用每名称原子锁、同目录临时 Fossil 文件、0600 权限、平台注册和目录发布；后续失败会补偿数据库、文件和目录状态。

浏览器写入路径包括：

- `/repo/<name>/files/new` 和 `/file/<artifact>/edit`
- `/wiki/new` 和 `/wiki-page/<artifact>/edit`
- `/tickets/new` 和 `/ticket/<id>`
- `/forum/new` 和 `/forum/<post>/reply`

文件和 Wiki 要求 Writer，Ticket 和 Forum 要求 Triage。每次操作消耗一次性挑战、使用仓库写锁、把中央用户名记录为 artifact 作者并在成功后重建目录。中央密码绝不复制到 Fossil。默认单仓库配额为 512 MiB，可用 `FOSSILHUB_REPOSITORY_QUOTA_BYTES` 在 1 MiB 到 1 TiB 范围内调整，非法值默认拒绝。

## 初始化器

镜像提供幂等 `/usr/local/bin/fossilhub-init`。它在唯一临时文件中初始化缺失仓库，设置 0600，并在全部 10 个仓库成功后重建目录。只能挂载精确 FossilHub 数据目录并以 UID/GID 10001:10001 运行。

初始化输出会抑制 Fossil 自动生成的本地管理员密码，并立即清空该本地用户 capability。入口脚本本身不会创建仓库，只负责目录、平台迁移、一次性中央管理员引导和目录重建。

## 只读检查

以下命令通过受控 fnOS SSH 连接执行，文档中不得嵌入 SSH/sudo 密码：

```sh
sudo docker ps --filter name='^fossilhub$'
sudo docker inspect --format '{{.State.Status}} {{.State.Health.Status}} {{.Config.Image}}' fossilhub
curl --fail --silent --show-error http://127.0.0.1:6080/healthz
sudo docker logs --tail 100 fossilhub
```

日志路径为 `/vol1/1000/fossilhub/althttpd-YYYYMMDD.csv`。日志可能包含敏感查询字符串，只能做定向检查，不得写入 Git 或完整返回。

参考仓库为 `/vol1/1000/fossilhub/repositories/bedrock.fossil`：

```sh
fossil clone http://192.168.1.162:6080/fossil/bedrock bedrock.fossil
```

## 生命周期

```sh
sudo docker stop fossilhub
sudo docker start fossilhub
sudo docker restart fossilhub
```

入口脚本会把 `SIGTERM` 转发给 Althttpd 并等待退出。正常 `docker stop` 应在超时前完成，退出码为 143；137 表示被强制停止，生产继续使用前必须调查。

这些命令只允许作用于 FossilHub 专用容器，不得改用 fnOS 应用中心命令，也不得触碰其他容器。

## 恢复与历史回滚

用户已于 2026-08-29 明确授权永久删除刚切换前的容器 `fossilhub-rollback-0ac4dff-20260829` 和数据 `/vol1/1000/fossilhub-rollback-0ac4dff-data`。这两个目标不可恢复，因此目前不存在带匹配旧数据的即时 Phase 5 前回滚点。

以下停止容器仍保留：

- `fossilhub-rollback-02682c9-20260829-logo` — 首次 Logo 上线候选，PNG 二进制响应修复前
- `fossilhub-rollback-578fcff-20260829-logo` — Logo 上线前的 `2026.08.28-beta.1` 生产容器

- `fossilhub-rollback-188b918` — 早期 0.2.0-beta.1
- `fossilhub-rollback-8c9726d` — 0.1.2
- `fossilhub-rollback-94f8097` — 0.1.1
- `fossilhub-rollback-348f399` — 0.1.0

这些历史容器没有与当前平台数据匹配的即时回滚保证。不得直接把它们改名并挂载当前 `/vol1/1000/fossilhub`；旧版本可能不理解 Phase 5 数据。任何版本回退必须单独制定数据兼容、备份和恢复方案，并重新获得明确授权。

如果只是当前容器损坏而镜像和数据完好，应先精确检查名称、镜像 ID、6080 和挂载，再保留故障容器并用同一已验证镜像重建。禁止在未确认状态时重复 stop/rename/run。

## 部署后保留项

用户于 2026-08-29 明确授权后，已删除所有非生产 FossilHub init/test/beta 容器，包括最终烟测容器 `fossilhub-beta-578fcff`、生产 initializer、数据库检查、完整性检查和旧 6082 beta 容器。容器绑定的数据、Docker 卷和镜像均未删除；最终烟测数据 `/vol1/1000/fossilhub-smoke-e0cb8dc` 仍保留。未经明确列名授权，不得删除烟测数据、卷、镜像或历史回滚容器。

本地 HTTP clone 测试产物已移入桌面废纸篓，可恢复。用户自有 Logo、trilobite、ammonite、bone-triad 等视觉实验文件不得修改、删除或提交。

## 升级流程

1. 从完整已提交修订工作；NAS 构建输入必须来自 `git archive`。
2. 重新确认 6080 只由当前 FossilHub 占用，并记录容器、镜像、挂载和回滚目标。
3. 在 NAS 的新 `/tmp/fossilhub-build-*` 目录构建唯一版本 x86_64 镜像。
4. 用 `fossilhub-init` 填充隔离数据，在已确认空闲的临时端口启动唯一命名烟测容器。
5. 完整验证测试、HTTP、clone/sync、权限、安全配置、重启、桌面/中屏/手机和公共挂载前缀。
6. 再次确认生产状态后，停止并改名旧容器，同时保留与其匹配的数据；使用相同安全限制启动新容器。
7. 等待健康并复验。失败时必须自动恢复旧容器和匹配数据，不得盲目重试。
8. 更新 `AGENTS.md`、`README.md`、`PLAN.md`、本文件和验收记录。

## fnOS 边界

FossilHub 部署不得修改 fnOS 系统文件、systemd unit、PostgreSQL schema 或应用中心状态。`docs/nas-audit.md` 列出的受保护容器始终不在本项目操作范围内。
