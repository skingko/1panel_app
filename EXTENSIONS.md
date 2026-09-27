# 扩展说明:上游同步 + 扩展应用

本仓库 = [okxlin/appstore](https://github.com/okxlin/appstore)(上游)`localApps` 分支的**完整镜像** + 本仓库自行维护的**扩展应用**。既有上游 780+ 个应用的持续更新,又能添加自己的应用。

## 目录结构

```
apps/                                # 全部应用(上游 + 扩展,同构存放)
├── alist/                           # ← 上游应用(随同步更新)
├── x-myapp/                         # ← 扩展应用(本仓库自维护,建议 x- 前缀避免撞名)
├── <app>/
│   ├── data.yml                     # 应用元数据:key、名称、i18n 简介、官网、架构
│   ├── logo.png                     # 图标
│   ├── README.md                    # 应用说明
│   └── <version>/                   # 版本目录(如 1.0.0、latest)
│       ├── data.yml                 # 表单字段定义(formFields → .env 变量)
│       ├── docker-compose.yml       # 引用表单变量,如 ${PANEL_APP_PORT_HTTP}
│       └── .env.sample              # 变量默认值(含 CONTAINER_NAME)
scripts/
├── sync-upstream.sh                 # 手动同步上游
└── new-app.sh                       # 生成扩展应用骨架
.github/workflows/sync-upstream.yml  # 每日自动同步(上游 → 本仓库)
EXTENSIONS.md                        # 本文件
```

## 上游同步

两条路径,底层动作相同(`git fetch upstream && git merge upstream/localApps`):

- **自动**:GitHub Actions `Sync Upstream` 每天凌晨 2:30(UTC)运行,有更新即合并推送;可在 Actions 页面手动触发。
- **手动**:
  ```bash
  scripts/sync-upstream.sh           # 同步并推送
  scripts/sync-upstream.sh --no-push # 只同步到本地
  ```

**为什么不会冲突**:扩展应用使用的目录名(`apps/x-*`)、以及 `scripts/`、`EXTENSIONS.md`、`sync-upstream.yml` 这些路径在上游都不存在,git 可全自动合并。唯一会冲突的情况是上游将来引入同名路径或同名应用,届时同步会明确失败,按提示手动解决一次即可。

上游原有的 renovate 定时工作流对本镜像无意义,同步任务会在每次运行后自动禁用它们(也会禁用后续随上游带入的其他工作流)。

## 添加扩展应用

### 方式一:脚手架(推荐)

```bash
scripts/new-app.sh x-myapp 1.0.0 nginx:latest 80 40099
# 参数:应用key  版本  镜像  容器内端口  面板默认端口
```

生成完整骨架后,补全 `apps/x-myapp/data.yml` 的元数据与简介、替换 `logo.png`、按需调整版本目录下的表单与 compose,然后提交推送。

### 方式二:参照现有应用手写

任选一个上游应用(如 `apps/alist/`)复制修改,保持相同结构即可。

### 应用编写要点(1Panel v2 规范)

- **应用级 `data.yml`**:`additionalProperties.key` 必须等于目录名;`type` 取 `website/tool/db/media/...`;`architectures` 填镜像实际支持的架构。
- **版本级 `data.yml`**:`formFields` 中每个 `envKey` 都要出现在 `docker-compose.yml` 或 `.env.sample` 中;端口字段用 `rule: paramPort`、`type: number`;下拉框用 `type: select` + `values: [{label, value}]`。
- **`docker-compose.yml`**:固定使用外部网络 `1panel-network`、`container_name: ${CONTAINER_NAME}`、打上 `labels: { createdBy: "Apps" }`。
- 提交前可用上游推荐的工具 [okxlin/1panel-app-adapter](https://github.com/okxlin/1panel-app-adapter) 校验。

### ⚠️ 踩坑记录:compose 禁用旧式资源键(必读)

**任何服务都不得使用 `mem_limit` / `memswap_limit` / `pids_limit`(及旧式 `cpus`)。**

1Panel v2 安装应用时会向 compose 中的某个服务注入 `deploy.resources.limits`(`cpus: ${CPUS}`、`memory: ${MEMORY_LIMIT}`,对应安装面板「高级设置 → 资源限制」)。关键在于它选取注入目标的代码是对服务 map 的遍历**没有 break**(v2.0.11 `agent/app/service/app.go` create 流程),而 Go map 遍历顺序随机——**多服务应用中每个服务都可能成为注入目标**。注入目标上若存在旧式资源键,docker compose 校验直接失败:

```
services.<name>: can't set distinct values on 'mem_limit' and 'deploy.resources.limits.memory': invalid compose project
```

正确做法:

- 内存/CPU 限制交给安装面板「高级设置 → 资源限制」配置(在应用 README 中给出建议值);
- 与注入不冲突、可放心使用的加固:`read_only`、`tmpfs`、`cap_drop`、`security_opt: [no-new-privileges:true]`、`healthcheck`、`depends_on`;
- 多服务应用的主服务用 `container_name: ${CONTAINER_NAME}`,sidecar 用应用前缀的服务名(如 `crw-searxng`),sidecar 不发布宿主端口。

**发布前验证方法**(穷举注入目标,防止随机性漏测):

```bash
# 对 compose 中每个服务分别注入 deploy.resources.limits + HOST_IP/CPUS/MEMORY_LIMIT,
# 逐一执行 docker compose config,全部通过才算过(参考 x-crw 的修复验证流程)
```

其他已验证的经验:

- crw 类基于 rust `config` crate 的应用:环境变量 `CRW_` 前缀 + `__` 嵌套分隔覆盖 TOML(如 `CRW_SEARCH__SEARXNG_URL` 覆盖 `[search].searxng_url`);`auth.api_keys` 支持逗号分隔字符串。
- SearXNG 官方默认引擎集(Google/DuckDuckGo/Brave 等)在无法直连的网络(如中国大陆)会全部超时;自带的 `settings.yml` 需追加 `engines: [{name: bing, disabled: false}]` 保证有可用引擎。

### 命名约定

扩展应用 key 统一加 `x-` 前缀(如 `x-myapp`),从命名空间上杜绝与上游 780+ 个应用撞名。

## 在 1Panel 中使用本仓库

与上游用法一致,把仓库地址换成 `https://github.com/skingko/1panel_app`(1Panel 计划任务,Shell 脚本):

```bash
set -euo pipefail
PANEL_BASE_DIR="/opt"   # 按实际 1Panel 安装根目录修改

LOCAL_APPS_DIR="$PANEL_BASE_DIR/1panel/resource/apps/local"
IMPORT_DIR="$LOCAL_APPS_DIR/appstore-localApps"

git clone -b localApps https://github.com/skingko/1panel_app "$IMPORT_DIR"
cp -a "$IMPORT_DIR/apps/." "$LOCAL_APPS_DIR/"
find "$IMPORT_DIR" -xdev -mindepth 1 -delete
rmdir "$IMPORT_DIR"
```

执行后在应用商店刷新本地应用,上游应用与扩展应用会一起出现。日常更新只需重复执行该脚本(或做成定时任务)。

## 相关分支

| 分支 | 说明 |
| ---- | ---- |
| `localApps` | 默认分支,1Panel 实际导入的内容 = 上游镜像 + 扩展应用 |
| 上游 `main` / `localApps-1.x` 等 | 未镜像(分别对应官方商店源与 1Panel v1 旧版);如需要:`git fetch upstream <branch> && git push origin <branch>` |
