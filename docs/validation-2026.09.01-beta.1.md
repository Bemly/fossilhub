# 2026.09.01-beta.1 生产重置与 Git 导入验收

日期：2026-09-01

## 发布标识

- 镜像：`fossilhub:2026.09.01-beta.1`
- 镜像 ID：`sha256:8ddb4fa4356cf814538ceaf7c0aa50de4138c636728af6b912756b674c481f14`
- 镜像源码修订：`2998dde7c04423c2e1c54892c1f914a2b90b5e34`
- 生产容器：`fossilhub`
- 生产容器 ID：`8035cc1ab0ab75f9fdb7efed792d967f00fa3cadafdc79e28515e11f0da162d8`
- 数据挂载：`/vol1/1000/fossilhub:/data`
- 端口：`6080:8080`
- 前序容器：`fossilhub-rollback-df85466-20260901-reset`（停止）

## 执行范围

用户明确要求取消隔离环境和生产备份，并声明旧 FossilHub 生产数据不再需要。执行时永久删除旧 `/vol1/1000/fossilhub` 和本次未使用的烟测复制目录，没有创建任何数据备份。前序容器本体仍保留，但因旧数据已删除，不能作为兼容数据回滚目标。

## Git 到 Fossil

- 导入源为 Git `main`，发布时共有 76 个提交；Codex 内部树引用未进入导出流。
- 目标文件为 `/data/repositories/fossilhub.fossil`，动态仓库 slug 为 `fossilhub`，公开可见，默认分支为 `main`，归中央 `warden` 管理。
- 导入后 Fossil 有 76 个 check-in，开放分支为 `main`；最新 check-in 注释为 `build: prepare 2026.09.01 beta 1`。
- 仓库 project-code 为 `cca7a4aaa9e4ca9f5f42c28a9caecd0f30aca07b`。
- 仓库已关闭 autosync，清空导入管理员能力，并应用公开 clone/sync capability。

## 验收结果

- 使用提交归档在 x86_64 NAS 构建镜像；OCI revision 为完整 Git 提交 ID。
- 镜像内 Tcl 9.1b0 的 14 组测试全部通过，包括真实 Argon2、认证、平台、仓库生命周期、写入、管理员、国际化和视图测试。
- `/`、`/healthz`、`/explore`、`/repo/fossilhub`、Timeline、Files、Docs、Wiki、Tickets、Forum 均返回 HTTP 200。
- 页面可见发布提交和 `README.md`；目录数据库只索引实际存在的 `fossilhub.fossil`。
- `fossil test-integrity --quick` 返回 `ok`；平台和目录数据库 `PRAGMA quick_check` 返回 `ok`。
- 真实 HTTP clone 收到 484 个 artifact，随后 sync 为零差异；克隆 project-code 与生产一致。
- 仓库、平台数据库、目录数据库和管理员引导记录均为 0600、UID/GID 10001:10001。
- 生产容器健康，根文件系统只读，`/tmp` 为 16 MB `nosuid,nodev,noexec` tmpfs，全部 capability 丢弃，启用 `no-new-privileges`，PID 上限 128，重启策略为 `unless-stopped`。

## 保留状态

- 停止的镜像测试容器 `fossilhub-test-2998dde` 保留，测试退出码为 0。
- clone 验证容器和克隆文件在验证后删除，避免保留测试生成的本地管理凭据。
- 历史回滚容器未删除；没有生产数据备份，也没有可恢复的旧生产数据。
