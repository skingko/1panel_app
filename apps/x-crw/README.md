# CRW — 网页抓取 / 爬取 / 搜索 API

> 扩展应用,由本仓库(skingko/1panel_app)维护。[上游项目 fastcrw/crw](https://github.com/fastcrw/crw) · [官方文档](https://docs.fastcrw.com/)

Rust 编写的自托管 **Firecrawl / Tavily 替代品**:网页抓取(`/v1/scrape`)、爬取(`/v1/crawl`)、搜索(`/v1/search`)、站点地图(`/v1/map`)、结构化提取(`/v1/extract`),并提供 **MCP 服务器**供 AI Agent 直接调用。内存占用约 6MB,单二进制。

## 应用组成

| 容器 | 镜像 | 说明 |
| ---- | ---- | ---- |
| crw | `ghcr.io/us/crw:0.36.0` | API 主服务,端口 3000 |
| crw-searxng | `searxng/searxng` | `/v1/search` 的元搜索后端,仅容器网络内可达 |
| crw-lightpanda | `lightpanda/browser` | 轻量 JS 渲染器(约 64MB),静态 JS 站点渲染 |

复杂 SPA / 反爬站点建议按[上游文档](https://docs.fastcrw.com/self-hosting/)追加 Chrome 渲染器(`--profile heavy`),本应用包默认未包含以节省资源。

## 安装面板关键变量

| 变量 | 说明 |
| ---- | ---- |
| `CRW_SEARCH__ENABLED` | 是否启用搜索 API `/v1/search` |
| `CRW_SEARCH__SEARXNG_URL` | 搜索后端地址,默认用内置 SearXNG;也可改为外部实例 |
| `SEARXNG_SECRET_KEY` | 内置 SearXNG 的密钥,建议安装时修改 |
| `CRW_AUTH__API_KEYS` | 服务鉴权密钥,逗号分隔多个;留空则调用无需鉴权 |
| `CRW_EXTRACTION__LLM__PROVIDER` | LLM 服务商(留空禁用);openai / anthropic / deepseek / openai-compatible / azure / openai-responses |
| `CRW_EXTRACTION__LLM__API_KEY` | LLM API 密钥,启用 AI 功能后必填 |
| `CRW_EXTRACTION__LLM__MODEL` | 模型名,如 `deepseek-chat`、`gpt-4o-mini` |
| `CRW_EXTRACTION__LLM__BASE_URL` | 自定义接口地址,仅 DeepSeek / OpenAI 兼容模式需要 |

LLM 用于 `formats:["summary"]` 摘要与 `/v1/search` 的 `answer` 答案综合;不配置不影响抓取与搜索本身。

## 搜索引擎说明

默认启用的网页引擎:SearXNG 官方默认集(Google/DuckDuckGo/Brave/Startpage/Wikipedia,可直连的网络自动生效)+ 针对国内网络追加的 **Bing、搜狗(sogou)、夸克(quark)、360 搜索、百度**。被墙/被反爬的引擎会自动挂起,不影响其余引擎出结果。

- **百度**:对服务器 IP 强制弹验证码,经常处于自动停用状态,属该引擎常态,不要指望它稳定出结果
- **Google 等**:网络可直连时自动参与聚合;若有 HTTP/SOCKS 代理,可让它们走代理——编辑安装目录下 `searxng-settings.yml`(挂载进容器的那个),追加:
  ```yaml
  outgoing:
    proxies:
      all://:
        - http://<代理地址>:<端口>
  ```
  然后 `docker restart` 本应用的 searxng 容器生效
- `/v1/search` 支持的请求参数:`query`、`limit`、`lang`、`tbs`(时间范围 h/d/w/m/y)、`sources`、`categories`;**不支持**按请求指定引擎,引擎集由上述服务端配置决定

## 使用示例

```bash
# 抓取页面为 Markdown
curl -s "http://<主机>:<端口>/v1/scrape" \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com"}'

# 搜索(内置 SearXNG)
curl -s "http://<主机>:<端口>/v1/search" \
  -H 'Content-Type: application/json' \
  -d '{"query":"1panel app store","limit":5}'

# 配置了 CRW_AUTH__API_KEYS 时携带鉴权
curl -s "http://<主机>:<端口>/v1/scrape" \
  -H 'Authorization: Bearer <你的key>' \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com"}'
```

MCP 端点:`http://<主机>:<端口>/mcp`(streamable HTTP),可直接填入支持 MCP 的客户端。

## 备注

- 数据无持久化(服务无状态),升级不影响使用;升级镜像 tag 需修改 `docker-compose.yml` 中的版本号。
- 服务已按上游建议部分加固:只读根文件系统、dropped 全部 capabilities、no-new-privileges;内存/CPU 限制请在安装面板「高级设置 → 资源限制」中配置(建议 ≥ 2G)。compose 中不使用 mem_limit 等旧式资源键——1Panel 安装时注入 deploy 资源段的目标服务是随机的,与旧式资源键共存会导致校验失败。
- Firecrawl 兼容性见 [COMPATIBILITY-firecrawl.md](https://github.com/fastcrw/crw/blob/main/COMPATIBILITY-firecrawl.md)。
