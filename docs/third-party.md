# 第三方源码记录

项目将所需上游源码纳入仓库，确保 NAS 构建不依赖持续变化的分支，也不依赖构建时能否连接外部源码站点。

## Wapp

- 项目：Wapp，Tcl Web 应用框架
- 上游：`https://www.sqlite.org/wapp/`
- 版本：1.0
- Fossil check-in：`5be58cf34374ea230303ce2af9127496aa4117bc79b74f554b97d9ead3d5be88`
- 快照 SHA-256：`4741f31927c0b1ee2fbc959179b806bafcec4e0ef7d4d36c7ea0eaf13ebb5f9c`
- 许可证：Simplified BSD / 2-Clause BSD
- 本地运行文件：`vendor/wapp/wapp.tcl`

下游兼容补丁：`wapp-safety-check` 使用 `info procs` 枚举 Tcl 过程，而不是使用 `info command` 枚举全部命令。上游写法在 Tcl 8.6 下也会返回内置命令，导致安全扫描执行前 `info body` 失败。

## Althttpd

- 项目：Althttpd
- 上游：`https://sqlite.org/althttpd/`
- 版本：2.0
- Fossil check-in：`641e31f18cff72151b1eee742abc3f067026e1d5c789f49de37b0b5adfd6922a`
- 快照 SHA-256：`7f4e26404b44513fabaf1505b8eec573075766e5b32ef634fddd57ce7486d2ba`
- 许可证：`althttpd.c` 中的公有领域声明
- 本地构建输入：`vendor/althttpd/`

快照哈希用于标识下载的官方归档。仓库只保留 FossilHub 构建和运行所需的源码与许可证文件。

## Tcl

- 项目：Tcl 核心语言运行时
- 上游：`https://www.tcl-lang.org/software/tcltk/9.1.html`
- 版本：9.1b0（2026-06-30 发布的官方 beta 源码）
- 本地归档：`vendor/tcl/tcl9.1b0-src.tar.gz`
- 归档 SHA-256：`7a5cba88694512b12bd052e5ddc1c80a1eeed5247d57a7735306137fc7533d1d`
- 许可证：归档根目录中的 `license.terms`

运行镜像从该源码构建 Tcl，不安装 Ubuntu 自带的 Tcl 8.6 软件包。

## Ubuntu 运行时安全工具

- `argon2`：Ubuntu 24.04 中 Password Hashing Competition 参考命令，用于中央账号的 Argon2id 密码哈希。
- `openssl`：Ubuntu 24.04 命令，仅用于在写入应用数据库前对随机会话值和表单挑战值进行 SHA-256 哈希。

密码只通过标准输入传给 Argon2，绝不作为命令参数。Argon2id 参数为 32 MiB、两次迭代、一个 lane，在 NAS 资源可控的前提下高于 OWASP 最低内存建议。两个工具都不得读取或修改 Fossil 自有仓库结构。

## Fossil SCM

- 项目：Fossil 分布式软件配置管理系统
- 上游：`https://fossil-scm.org/home/`
- 版本：2.29 development trunk
- Fossil check-in：`b8c7665e121b25c3ccc268edbab86ec27c72f7a3c0cd56fa1ed2762a84fadc38`
- 快照日期：2026-08-24 16:58:24 UTC
- 本地归档：`vendor/fossil/fossil-b8c7665e121b.tar.gz`
- 归档 SHA-256：`0aeb0d3a705de39bd0a7b103e718036b6ad126f12da0cdffe262cdc1f4c3dafd`
- 许可证：归档中的 `COPYRIGHT-BSD2.txt`（2-Clause BSD）

Fossil 目前没有发布 2.29 正式归档，因此项目有意固定使用上述不可变 trunk check-in 作为开发版本。

## 开发通道解释

Wapp 和 Althttpd 没有单独编号的 beta 通道，因此项目使用官方 trunk 的精确叶节点作为开发快照。上述 check-in 已于 2026-08-27 重新验证，当时仍为最新；本地 Wapp 文件只因前述 Tcl 兼容补丁而与上游 blob 不同。

## 参考界面偏差

`reference/` 中的参考快照保持不变。生产 Explore 样式仅在 640 px 以下增加 `.fgroup { flex-wrap: wrap; }`，防止语言筛选器撑宽页面。
