# 2026.08.30-beta.1 验收记录

日期：2026-08-30

## 发布标识

- 源码修订：`fe7824f`
- 镜像：`fossilhub:2026.08.30-beta.1`
- 镜像 ID：`sha256:b8500950d43d8d094d7321d4fa7f9cd47a0efa296a2e18439f4e16411be0e06d`
- 生产容器：`fossilhub`
- 数据挂载：`/vol1/1000/fossilhub:/data`
- 端口：`6080:8080`
- 直接回滚：`fossilhub-rollback-3b88c20-20260830-i18n`（停止）

## 验收结果

- 镜像内 Tcl 9.1b0 全套 14 组测试通过，包括真实 Argon2、认证、平台、仓库生命周期、写入、管理员、国际化和视图测试。
- 两个浏览器脚本通过语法检查，挂载前缀脚本测试通过。
- 隔离数据复用升级后，十个仓库数量、Bedrock project-code、目录数据库和文件权限保持不变。
- 70 条仓库页面路由、`/login`、`/register`、`/healthz`、直接 LAN 路径和模拟子目录路径通过。
- `Accept-Language`、语言 Cookie、POST 切换、站内回跳和危险外部回跳拦截通过。
- 匿名入口显示登录与注册；普通用户和管理员入口由视图测试验证，后端既有角色与 CSRF 边界保持不变。
- 桌面、913 px 和 390 × 844 响应式检查无横向溢出；中文导航换行问题已修复，控制台无警告或错误。最终修订只在通过浏览器矩阵的同版 CSS 上补充服务端固定文案，并再次通过 HTTP 与视图回归。
- 生产切换后 70 条路由、中英文 SSR、clone/sync、project-code、0600 权限、UID/GID 10001:10001 和容器安全参数全部复验通过。

## 生产状态

生产容器健康，重启策略为 `unless-stopped`，根文件系统只读，`/tmp` 为 16 MB 的 `nosuid,nodev,noexec` tmpfs，全部 capability 已丢弃，启用 `no-new-privileges`，PID 上限为 128。隔离烟测容器 `fossilhub-beta-fe7824f` 已停止但未删除。
