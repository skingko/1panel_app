# AGENTS.md — 本仓库 AI 协作约定

本仓库 = [okxlin/appstore](https://github.com/okxlin/appstore) `localApps` 分支的镜像 + 自维护扩展应用(`apps/x-*`)。完整机制见 [EXTENSIONS.md](EXTENSIONS.md)。

## 同步与扩展的铁律

- **绝不修改上游已有文件**(apps/ 下非 `x-` 前缀的应用、README、.github/ 等);扩展只新增文件,否则每日自动同步(`sync-upstream.yml`)会产生合并冲突。
- 扩展应用 key 一律 `x-` 前缀;新增基础设施只放 `scripts/`、`EXTENSIONS.md`、`AGENTS.md`、`.github/workflows/sync-upstream.yml` 这些上游不存在的路径。
- 同步用 `scripts/sync-upstream.sh`;判断"上游是否有更新"比较的是 upstream tip 与 merge-base(不是 HEAD 与 merge-base,HEAD 含自己的扩展提交)。
- **GITHUB_TOKEN 永远无法推送 `.github/workflows/` 变更**(GitHub 硬限制;`permissions` 也不支持 `workflows` 作用域,加了会让工作流解析失败)。因此同步流程会**丢弃上游的工作流变更**(折叠进合并提交)——镜像仓库本就禁用上游 renovate 工作流,这是预期行为;`sync-upstream.yml` 自身的修改只能由人工用 PAT 从本地推送。

## 1Panel v2 应用包规范(踩过的坑,勿再犯)

1. **compose 任何服务禁止 `mem_limit` / `memswap_limit` / `pids_limit` / 旧式 `cpus`。**
   1Panel v2 安装时向随机服务注入 `deploy.resources.limits`(选取服务时 map 遍历无 break,目标不定),与旧式资源键共存必报
   `can't set distinct values on 'mem_limit' and 'deploy.resources.limits.memory': invalid compose project`。
   资源限制交由安装面板「高级设置 → 资源限制」。可用且不冲突的加固:`read_only`、`tmpfs`、`cap_drop`、`security_opt`、`healthcheck`、`depends_on`。
2. compose 固定:`networks: {1panel-network: {external: true}}`、主服务 `container_name: ${CONTAINER_NAME}`、`labels: {createdBy: "Apps"}`;sidecar 用应用前缀服务名(如 `<app>-db`),不发布宿主端口。
3. 版本级 `data.yml` 的 `formFields[].envKey` 必须与 compose 引用的 `${VAR}`、`.env.sample` 三方闭环;select 字段用 `values: [{label, value}]`。
4. **发布前必须穷举验证**:对每个服务分别模拟 1Panel 注入(deploy.resources.limits + ports 前缀 `${HOST_IP}:` + .env 追加 `CPUS=0/MEMORY_LIMIT=0/HOST_IP=127.0.0.1`),`docker compose config` 全部通过。随机注入意味着只测一个服务不够(x-crw 曾因此返工两次)。
5. 面向大陆环境的应用:涉及 SearXNG 时需在自带 settings.yml 启用 bing 引擎(默认引擎集在大陆全部超时)。

## 测试环境

优先在内网 1Panel 测试机(装有 1Panel v2 与真实 `1panel-network`,地址与凭据见本地 `LOCAL_NOTES.md`,该文件已被 git 排除、勿提交)。本机 Mac 的 Docker Desktop 不稳定,勿依赖。远端测试完必须 `docker compose down --remove-orphans` 并删除临时目录。

生产服务器(见 LOCAL_NOTES.md)更新已装应用时的铁律:
- **绝不修改/覆盖安装目录的 `.env`**——里面有用户配置的鉴权密钥(CRW_AUTH__API_KEYS)等参数,破坏即服务中断;只改需要变更的文件(如 compose 镜像行、searxng-settings.yml)
- 改完安装目录后,必须同步更新 `/opt/1panel/resource/apps/local/<app>/` 源目录,否则面板侧安装源仍是旧版
- 更新后必须回归验证鉴权:无密钥应 401、带密钥应 200

## 提交约定

- 提交信息中文,格式 `feat:/fix:(x-app): 描述`,直接推 `origin localApps`。
- 用户面板上已装应用的修复:同版本目录内改文件即可,提醒用户删除失败安装记录并重新同步本地应用。
