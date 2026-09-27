#!/usr/bin/env bash
#
# 从上游 okxlin/appstore 同步 localApps 分支的全部更新,并保留本仓库的扩展应用。
#
# 用法:
#   scripts/sync-upstream.sh          # 拉取 + 合并 + 推送到 origin
#   scripts/sync-upstream.sh --no-push # 只拉取 + 合并,不推送
#
# 原理:扩展应用位于 apps/ 下与上游不同的目录名,扩展基础设施位于
# scripts/、.github/workflows/sync-upstream.yml、EXTENSIONS.md,
# 这些路径上游均不存在,因此 git merge 可自动完成,无需人工干预。
# 若上游将来引入同名路径导致冲突,脚本会中止并保留现场,手动解决后
# 执行 git merge --continue 即可。
#
set -euo pipefail

BRANCH="localApps"
UPSTREAM_REMOTE="upstream"
UPSTREAM_REPO="okxlin/appstore"
PUSH=1
[ "${1:-}" = "--no-push" ] && PUSH=0

if ! git remote get-url "${UPSTREAM_REMOTE}" >/dev/null 2>&1; then
  git remote add "${UPSTREAM_REMOTE}" "https://github.com/${UPSTREAM_REPO}.git"
fi

CURRENT="$(git rev-parse --abbrev-ref HEAD)"
if [ "${CURRENT}" != "${BRANCH}" ]; then
  echo "切换到 ${BRANCH} 分支(当前:${CURRENT})"
  git checkout "${BRANCH}"
fi

echo "拉取上游 ${UPSTREAM_REPO}:${BRANCH} ..."
git fetch "${UPSTREAM_REMOTE}" "${BRANCH}"

BASE="$(git merge-base HEAD "${UPSTREAM_REMOTE}/${BRANCH}")"
if [ "$(git rev-parse HEAD)" = "${BASE}" ]; then
  echo "无上游更新。"
  exit 0
fi

echo "合并 upstream/${BRANCH} ..."
if ! git merge --no-edit "${UPSTREAM_REMOTE}/${BRANCH}"; then
  echo
  echo "==> 出现冲突。上游引入了与扩展文件相同的路径。" >&2
  echo "    解决冲突后执行: git add -A && git commit && git push origin ${BRANCH}" >&2
  exit 1
fi

echo "同步完成:$(git log --oneline "${BASE}..HEAD" | wc -l | tr -d ' ') 个新提交。"

if [ "${PUSH}" = "1" ]; then
  git push origin "${BRANCH}"
  echo "已推送到 origin/${BRANCH}。"
else
  echo "已跳过推送(--no-push)。"
fi
