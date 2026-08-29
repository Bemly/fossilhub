# FossilHub 0.2.0-beta.1 验收记录

验收完成日期：2026-08-27

## 候选产物

- 最终源码修订：`0ac4dff`
- 基础候选修订：`188b918`
- 镜像：`fossilhub:0.2.0-beta.1`
- 镜像 ID：`sha256:8b873837f192be367314fbacbb21940aa18071bb887ef39a9ac44235384b95f9`
- OCI 修订标签：`0ac4dff`
- 当时的生产容器：`fossilhub`
- 生产地址：`http://192.168.1.162:6080/`

临时 6082 验收容器已停止。验收结束时，生产 6080 在最终镜像上保持健康，修订 `188b918` 和 `8c9726d` 作为当时的即时回滚容器保留。本文件记录历史验收状态，不代表当前生产版本。

## 运行时版本

- Tcl 9.1b0
- Wapp 1.0，官方 trunk check-in `5be58cf34374ea230303ce2af9127496aa4117bc79b74f554b97d9ead3d5be88`
- Althttpd 2.0，官方 trunk check-in `641e31f18cff72151b1eee742abc3f067026e1d5c789f49de37b0b5adfd6922a`
- Fossil 2.29 development trunk check-in `b8c7665e121b25c3ccc268edbab86ec27c72f7a3c0cd56fa1ed2762a84fadc38`

## 自动化与 HTTP 检查

- Wapp 安全 lint 和 Tcl 路由测试在 Tcl 9.1b0 下通过。
- 容器在路由测试开始前进入 `healthy`。
- Hub 路由 `/`、`/explore`、`/repo/dig.fossil`、`/healthz`、`/fossilhub-live.js` 和嵌套脚本路由均返回 HTTP 200。
- 原生 Fossil Timeline、Files、Wiki、Tickets、Forum 和 trunk ZIP 路由返回 HTTP 200。
- 真实 HTTP `fossil clone` 得到与服务端一致的 project code，随后 `fossil sync` 单轮完成且无缺失 artifact。

## 持久化与权限

- 种子仓库包含两个真实 check-in，以及 Wiki 和 Ticket artifact。
- 镜像替换和容器重启前后，仓库身份、check-in 数量、仓库字节数和管理员引导记录保持不变。
- 仓库和管理员引导记录权限为 0600，属主为 UID/GID 10001:10001。
- 引导密码没有写入容器日志或源码仓库。
- 容器使用只读根文件系统、专用 `/tmp` tmpfs、全部 capability 丢弃、`no-new-privileges` 和 128 进程限制。

## 浏览器验收

- 桌面 1280 x 720、手机 390 x 844、中等宽度 913 x 720 均无水平溢出、控制台警告或错误。
- 修订 `0ac4dff` 在 1100 px 以下隐藏长 clone 命令，同时保留导航。
- 主题切换可以正确改变活动主题。
- 参考界面的 Timeline 能进入原生 Fossil Timeline，并显示两个 check-in。
- 模拟 `/bemly-moe/app/fossilhub/` 路径时，clone、Timeline 和 ZIP URL 均保留完整 fnOS 挂载前缀。

## 当时的生产部署

在获得明确授权后完成生产部署。当时的 0.1.2 容器保留为 `fossilhub-rollback-8c9726d`，第一版 beta 镜像保留为 `fossilhub-rollback-188b918`。最终容器进入健康状态，保持仓库身份与 check-in 数量，并通过全部 HTTP、clone 和 sync 检查。
