# fnOS 部署审计

审计日期：2026-08-26

本次审计为只读操作，没有修改任何既有容器或 fnOS 系统文件。

## 主机

- 主机名：`MEminiFnOS`
- 架构：`x86_64`
- 主机系统基础：Debian 12
- Docker Engine：28.5.2
- `/vol1`：审计时总容量 474 GB，可用 400 GB

## 部署分配

- 容器：`fossilhub`
- 主机端口：`6080`（审计时确认未占用）
- 容器端口：`8080`
- 持久化路径：`/vol1/1000/fossilhub`（审计时确认不存在）
- 持久化路径属主：UID/GID `10001:10001`，权限 `0750`

## 受保护容器

以下既有容器仅通过 `docker ps -a` 进行检查，本项目不得修改：

- `llonebot`
- `napcat-docker`
- `astrbot`
- `chromium`
- `Ayu`
- `db2`
- `redis`

## 安全说明

- 每次部署前必须重新确认端口 `6080` 的占用情况。
- 只能创建 FossilHub 专用容器和存储路径。
- 不得使用主机网络。
- 不得挂载 Docker socket 或任何 fnOS 系统路径。
- 不得调用 fnOS 应用中心内部机制来管理此容器。
