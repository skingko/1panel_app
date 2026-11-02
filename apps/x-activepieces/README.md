# Activepieces — 开源自动化工作流平台

> 扩展应用,由本仓库(skingko/1panel_app)维护。[上游项目 activepieces/activepieces](https://github.com/activepieces/activepieces) · MIT(社区版) · [官方文档](https://www.activepieces.com/docs/install)

开源无代码自动化平台(Zapier 替代品):可视化拖拽编排流程,内置 400+ 应用连接器(OpenAI、Gmail、Slack、Telegram、飞书、钉钉等),支持代码步骤(TypeScript)、定时/手动/Webhook 触发、执行历史与连接凭据管理。

## 使用

- 打开 `http://<主机>:<端口>` 进入界面;**首个注册的用户即管理员**,无默认账号密码
- **公网访问地址**(`AP_FRONTEND_URL`)是 Webhook 回调的基础地址:反代到域名后,在面板「参数」里把它改成外部地址(如 `https://ap.example.com`),否则第三方触发器回调会指向内网
- 两个预置密钥(凭据加密键/JWT 签名键)安装后**保持不变**:加密键用于加密已保存的第三方连接凭据,更换会导致旧凭据无法解密

## 说明

- **复用 1Panel 已安装的 PostgreSQL**(安装时面板自动创建随机库/用户/密码);官方镜像自带 pgvector 支持知识库向量检索,复用面板 PostgreSQL 时该扩展不可用——核心自动化功能完全不受影响,仅"知识库"功能需自行加装 pgvector
- 作业队列使用内置 Redis sidecar(随机密码,仅容器网络可达),数据在命名卷 `activepieces-redis-data`
- 采用官方镜像入口的 `WORKER_AND_APP` 单容器模式:API/UI 与流程执行器同容器运行,并自动生成 worker token,适合单机部署;代码步骤为非沙箱模式(UNSANDBOXED),请只运行可信流程
- 升级:应用商店「升级」换新镜像,数据库迁移自动执行;流程数据都在 PostgreSQL 中,升级不丢失
- 遥测默认关闭(可在参数或管理界面修改)
