# Moli — 面向 AI Agent 的无头浏览器

> 扩展应用,由本仓库(skingko/1panel_app)维护。[上游项目 lexmount/moli](https://github.com/lexmount/moli) · Rust 编写

生产级无头浏览器:结构优先、按需排版渲染(纯 DOM 操作不触发排版与绘制),单二进制、内存占用低。同一端点(9222)提供 **CDP、WebDriver Classic、WebDriver BiDi** 三种自动化协议。

上游未发布 Docker 镜像,本应用使用的镜像由本仓库的 `Build Upstream Images` 工作流用上游官方 release 二进制构建并推送至 `ghcr.io/skingko/moli`。

## 使用

启动后即是一个自动化服务器(已启用 `--layout --resource`,均为按需生效,不影响纯 DOM 操作的速度):

```bash
# 探活 / 版本
curl http://<主机>:<端口>/json/version

# Playwright 经 CDP 直连
# const browser = await chromium.connectOverCDP("http://<主机>:<端口>");
```

命令行抓取(容器内):

```bash
docker exec <容器名> moli fetch --dump markdown --wait-until done https://example.com
```

## 说明

- 服务无状态、无持久化数据,升级只需换镜像 tag(由仓库工作流构建新版本后在应用目录同步更新)
- 无内置鉴权:端口只绑定你信任的网络,公网暴露请自行加反代鉴权
- 截图/渲染中文页面已内置 Noto CJK 字体
- 镜像 tag 与上游 release 版本号一致(当前 1.1.12)
