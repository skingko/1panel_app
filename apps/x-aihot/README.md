# AIHOT — 自己找热点、自己写日报的行业热点站

> 扩展应用,由本仓库(skingko/1panel_app)维护。[上游项目 KKKKhazix/AIHOT](https://github.com/KKKKhazix/AIHOT) · [演示站 aihot.news](https://aihot.news)

从一批信源收资料,用大模型预筛、两次独立评分,挑出真正值得看的写成中文标题和摘要;同一件事聚成一个事件、按独立来源数排热度;每天早上自动出日报。把信源和精选标准换成你的,它就是你的行业热点站。

**需要一个 OpenAI 兼容的模型 API Key**(DeepSeek、千问、智谱都可以),安装时在面板填入。

## 应用组成

| 容器 | 说明 |
| ---- | ---- |
| aihot-web | 网站前端(SSR),对外端口;后台在 `/admin` |
| aihot-api | 后端 API(容器网络内部) |
| aihot-worker | 精选/写作/聚簇流水线 |
| aihot-setup | 一次性迁移与演示信源导入,完成即退出 |

**数据库复用 1Panel 已安装的 PostgreSQL 服务**:安装面板会列出已有的 PostgreSQL 服务供选择,并自动创建随机的库名/用户/密码,不再单独起数据库容器(需先在应用商店安装 PostgreSQL;上游按 PostgreSQL 17 开发,建议 15+)。

上游未发布 Docker 镜像,镜像由本仓库的 `Build Upstream Images` 工作流用上游官方 Dockerfile 构建(`ghcr.io/skingko/aihot`,tag 为上游 commit 短 SHA)。

## 安装要点

- **网站对外地址**(SITE_URL)填实际访问地址(如 `http://192.168.1.10:13100`),生成的链接、RSS、分享图、MCP 都用它
- **管理员密码**至少 12 位,登录 `/admin` 用
- 模型三件套:接口地址(DeepSeek 填 `https://api.deepseek.com/v1`)、API Key、模型名
- 经反向代理访问时,「信任反向代理」选开启(TRUST_PROXY)
- 首次安装后一两分钟开始有内容,演示信源的存量资料约半小时处理完;换信源、改精选标准见[上游文档](https://github.com/KKKKhazix/AIHOT/blob/main/docs/customize.md)

## 版本说明

上游无版本发布,本应用版本目录名为镜像对应的**上游 commit 短 SHA**(`9848e93`)。升级方式:用 `Build Upstream Images` 工作流构建新 commit 的镜像,再新建版本目录更新应用。
