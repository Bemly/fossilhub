# FossilHub 2026.08.27-beta.3 验收记录

验收完成日期：2026-08-27

## 候选产物

- 源码修订：`1d0bcfa`
- 镜像：`fossilhub:2026.08.27-beta.3`
- 镜像 ID：`sha256:8315f667a91871d0e05b6b1f2156f7ba7099fb11e36e955d7e2ecc29cf8c7248`
- OCI 修订标签：`1d0bcfa`
- 烟测容器：`fossilhub-beta-1d0bcfa`
- 烟测地址：`http://192.168.1.162:6082/`
- 隔离数据：`/tmp/fossilhub-smoke-blank-9GJmZB`

本次验收期间，生产 6080 一直运行 `fossilhub:0.2.0-beta.1` 并保持健康。该 CalVer 镜像当时只是候选版本，并未切换生产。

## 运行时与自动化测试

- x86_64 NAS 使用 `git archive 1d0bcfa` 完成构建。
- OCI 标签正确标识修订 `1d0bcfa` 和版本 `2026.08.27-beta.3`。
- 镜像构建期间 Tcl 9.1b0、Fossil 2.29 和 Wapp lint 均通过。
- 路由、模型、目录、视图和仓库数据测试在候选镜像的 Tcl 9.1b0 下通过。
- 仓库数据套件在 `GATEWAY_INTERFACE=CGI/1.1` 环境运行，证明 Tcl 启动 Fossil CLI 子进程时正确携带 `--nocgi`。

## 仓库与 HTTP 验收

- 幂等初始化器创建了恰好 10 个仓库：`bedrock`、`ammonite`、`trilobite`、`basalt`、`cambrian`、`granite`、`shale`、`quartz`、`obsidian` 和 `tectonic`。
- 每个仓库只有 Fossil 必需的初始空 check-in，不包含源码文件、Wiki、Ticket、Forum 或导入历史。
- 应用目录恰好包含清单中的 10 个仓库。
- `/`、`/healthz`、`/explore`、实时目录片段、两个集成脚本、10 个仓库根页面，以及第一方 Timeline、Files、Docs、Wiki、Tickets、Forum 页面均返回 HTTP 200。
- FossilHub 页面不包含指向 `/fossil/*` 的浏览器导航链接；该端点只供 clone/sync 客户端使用。
- 对 `bedrock` 的真实 HTTP clone 成功并保持服务端 project code，随后 sync 成功。

## 持久化与权限

- 再次运行初始化器后，10 个仓库文件的聚合哈希保持不变，并重新生成 10 行目录记录。
- 重启烟测容器后仓库身份保持不变，服务恢复健康。
- 所有仓库和目录数据库权限为 0600，属主为 UID/GID 10001:10001。
- 烟测容器使用只读根文件系统、16 MB `/tmp` tmpfs、全部 capability 丢弃、`no-new-privileges` 和 128 进程限制。

## 浏览器验收

- 桌面 1440 x 900、中等宽度 913 px、手机 390 x 844 均无水平溢出或图片损坏。
- 390 px 仓库页面提供第一方 Timeline、Files、Docs、Wiki、Tickets 和 Forum 标签，不链接原生 Fossil 页面。
- 搜索 `quartz` 时，无需整页跳转即可更新 URL 和结果片段为 1 条匹配。
- 浏览器控制台没有警告或错误。
- 模拟 `/bemly-moe/app/fossilhub/` 路径时，样式正常加载、clone 命令保留完整挂载前缀，390 px 下无水平溢出。

## 当时剩余的发布门槛

该版本没有切换 6080。若当时要替换生产，仍需对 `2026.08.27-beta.3` 进行明确授权和最终事务式预检，并保留原生产作为回滚目标。本节仅记录当时状态。
