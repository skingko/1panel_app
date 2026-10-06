# Toonflow — 开源 AI 创作平台

> 扩展应用,由本仓库(skingko/1panel_app)维护。[上游项目 HBAI-Ltd/Toonflow-app](https://github.com/HBAI-Ltd/Toonflow-app) · MIT 协议

融合无限画布、AI Agent 与可视化工作流的 AI 创作平台:图像生成、视频生成、智能分镜与短剧创作。模型 API 在网页设置里自由接入(OpenAI 兼容及各家厂商),支持 MCP 与插件扩展。

## 说明

- **单容器部署**:端口即网页;数据(项目、配置、插件、内嵌 SQLite 数据库)全部保存在数据目录,**无需外部数据库服务**
- 模型密钥等在网页「设置」里配置,保存在数据目录,升级不丢
- 上游未发布 Docker 镜像,镜像由本仓库 `Build Upstream Images` 工作流用上游官方 Dockerfile 构建(`ghcr.io/skingko/toonflow`,tag 为上游 commit 短 SHA,当前 `72a895c`,2026-10-05)
- 镜像内含 FFmpeg(视频分镜/导出所需);无 GPU 要求(模型调用走外部 API)
- 升级方式:用工作流构建新 commit 镜像后新建版本目录

## 使用

打开 `http://<主机>:<端口>` 即是画布工作台;首次使用在设置中填入你的模型 API。
