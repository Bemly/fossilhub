# FossilHub 2026.08.29-beta.1 生产验收记录

日期：2026-08-29

结论：正式 FossilHub 横向 Logo 已部署到 fnOS 生产环境。最终生产容器健康，Logo、仓库读取、公开传输、持久化权限和响应式浏览器验收均通过。

## 已验证产物

| 项目 | 值 |
| --- | --- |
| OCI Git 修订 | `3b88c20e39604b5f3c2161738c7d677c65abbb93` |
| 镜像 | `fossilhub:2026.08.29-beta.1` |
| 镜像 ID | `sha256:24cbe0cf7c50dd6fda05d30d6134c98b53bdf66b8af1ae394ec0eff1528934e8` |
| 生产容器 | `fossilhub` |
| 数据挂载 | `/vol1/1000/fossilhub:/data` |
| 端口 | `6080:8080` |

构建输入来自已提交修订的 `git archive`，本地与 NAS 传输归档 SHA-256 一致。镜像确认使用 Tcl 9.1b0、Fossil 2.29，并通过 Wapp lint。用户明确要求跳过隔离烟测容器，直接在生产数据上验证；该例外未放宽事务式替换、自动恢复或其他安全检查。

## 自动化与生产验证

- 镜像内 13 项 Tcl 测试全部通过，包括路由、模型、目录、平台、认证、仓库数据、历史、仓库服务、写入服务、Fossil 传输、工作区、管理员和视图测试。
- `git diff --check`、两项 JavaScript 语法检查和直接/挂载前缀脚本测试通过。
- 生产 HTTP 矩阵 70/70 通过，覆盖首页、健康、Explore SSR/片段、CSS、两项脚本、Logo 的直接与嵌套路径，以及十个仓库的 Timeline、Files、Docs、Wiki、Tickets、Forum。
- Logo 响应为 `image/png`、327543 字节、缓存一小时；生产响应 SHA-256 与源码文件 `9f8f4c892462c678313f6a8302224665a2cd62953a39b63b2b957fe25e7c256a` 一致。
- 真实 HTTP clone 和 sync 成功，克隆仓库 project code 与生产 `bedrock.fossil` 一致。
- 十个仓库身份和初始 check-in 均可读；仓库、目录数据库和平台数据库保持 0600、10001:10001。

## 浏览器验收

- 1440×900、913×900 和 390×844 下 Logo 均完整加载，无水平溢出。
- 深色主题下 Logo 可见，桌面导航、1100 px 以下 clone 命令隐藏和 900 px 以下移动导航符合设计。
- Explore 实时搜索 `bedrock` 返回一个匹配仓库。
- Bedrock 的 Timeline、Files、Docs、Wiki、Tickets、Forum 六个首方页签全部加载，未出现控制台警告或错误。

## 事务式切换与回滚

首次候选修订 `02682c9` 健康启动后，生产路由检查发现 PNG 被按 UTF-8 文本读取而返回 500。修复在 `3b88c20` 中提交并重新完成镜像测试，第二次事务式切换后全部检查通过。两次自动回滚均未触发。

以下即时回滚容器已停止并保留：

- `fossilhub-rollback-02682c9-20260829-logo`
- `fossilhub-rollback-578fcff-20260829-logo`

不得在未重新核对生产状态和数据兼容性的情况下删除或启动它们。
