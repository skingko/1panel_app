# GProxy — 自托管 LLM API 网关

> 扩展应用,由本仓库(skingko/1panel_app)维护。[上游项目 LeenHawk/gproxy](https://github.com/LeenHawk/gproxy) · AGPL-3.0 · [官方文档](https://gproxy.leenhawk.com/)

Rust 编写的多渠道 LLM 代理:把上游各家(OpenAI / Claude / Gemini 等)统一到一个网关端点,支持 OpenAI / Claude / Gemini 三种风格 API 对外暴露;内置管理台、用户与密钥管理、请求与用量审计、凭据健康检查与故障转移、模型路由。**内嵌 SQLite,无需外部数据库**。

## 使用

- 打开 `http://<主机>:<端口>/console/` 进入管理台;首次启动会在容器日志里打印一次 admin 初始密码与网关 API Key(仅此一次),用 `docker logs <容器名> | grep -A2 user` 查看
- **主密钥必须为 44 位 base64**(即 openssl rand -base64 32 的输出),示例文件已预置一个,生产环境请自行更换
- 管理台里添加上游供应商凭据、创建模型路由,然后用网关 API Key 调用(兼容 OpenAI SDK)
- **主密钥**(面板自动生成)用于加密上游凭据:**设置后保持不变**,与数据目录一起备份;丢失则已存凭据无法解密
- 数据(SQLite 与配置)都在数据目录,升级应用不丢失

## 说明

- 使用官方镜像 `ghcr.io/leenhawk/gproxy`(amd64/arm64)
- 网关端口即面板端口;`/v1/...` 等 API 路径与管理台同端口
- 上游凭据等敏感信息保存在本地数据目录,请勿将端口暴露到公网(或加反代鉴权)
