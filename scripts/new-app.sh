#!/usr/bin/env bash
#
# 生成一个 1Panel v2 扩展应用骨架(与 apps/ 下上游应用同构)。
#
# 用法:
#   scripts/new-app.sh <app-key> <version> <image> [内网端口] [主机端口]
#
# 示例:
#   scripts/new-app.sh x-demo 1.0.0 ghcr.io/foo/demo:latest 8080 40099
#
# 生成后请编辑:
#   - apps/<app-key>/data.yml        应用元数据(名称、简介、i18n、官网)
#   - apps/<app-key>/logo.png        替换占位图标
#   - apps/<app-key>/<version>/data.yml        按需增删表单字段
#   - apps/<app-key>/<version>/docker-compose.yml  按需调整卷挂载/环境变量
#
set -euo pipefail

if [ $# -lt 3 ]; then
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
fi

APP_KEY="$1"
APP_VERSION="$2"
IMAGE="$3"
INNER_PORT="${4:-8080}"
HOST_PORT="${5:-40099}"

APP_DIR="apps/${APP_KEY}"
VER_DIR="${APP_DIR}/${APP_VERSION}"

if [ -d "${VER_DIR}" ]; then
  echo "错误:${VER_DIR} 已存在" >&2
  exit 1
fi

echo "生成 ${VER_DIR} ..."

# ---------- 应用级 data.yml ----------
if [ ! -f "${APP_DIR}/data.yml" ]; then
  mkdir -p "${APP_DIR}"
  cat > "${APP_DIR}/data.yml" <<EOF
name: ${APP_KEY}
tags:
  - 工具
title: ${APP_KEY}
description: ${APP_KEY}(请在 apps/${APP_KEY}/data.yml 中补充简介)
additionalProperties:
  key: ${APP_KEY}
  name: ${APP_KEY}
  tags:
    - Tool
  shortDescZh: 请补充中文短简介
  shortDescEn: Please fill in the English short description
  description:
    en: Please fill in the English description.
    zh: 请补充中文描述
    zh-Hant: 請補充中文描述
    ja: 説明を記入してください
    ko: 설명을 입력하세요
    ru: Заполните описание
    ms: Sila isi keterangan
    pt-br: Preencha a descrição
  type: tool
  crossVersionUpdate: true
  limit: 0
  recommend: 0
  website: https://example.com/
  github: https://github.com/
  document: https://example.com/docs
  architectures:
    - amd64
    - arm64
EOF

  # 占位 logo(64x64 圆角方块),请替换为正式图标
  printf 'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAJ0lEQVR42u3BAQ0AAADCoPdPbQ43oAAAAAAAAAAAAAAAAAAAAIB3A0BAAAGveg7oAAAAAElFTkSuQmCC' \
    | base64 -d > "${APP_DIR}/logo.png"

  cat > "${APP_DIR}/README.md" <<EOF
# ${APP_KEY}

> 扩展应用,由本仓库(skingko/1panel_app)维护,上游(okxlin/appstore)不包含此应用。

## 介绍

TODO:应用介绍、官方地址、默认账号/密钥说明。

## 使用

在 1Panel 本地应用商店安装,或进入 \`${APP_VERSION}/\` 目录:

\`\`\`bash
cp .env.sample .env
# 编辑 .env 后
docker compose up -d
\`\`\`
EOF
fi

# ---------- 版本目录 ----------
mkdir -p "${VER_DIR}"

cat > "${VER_DIR}/data.yml" <<EOF
additionalProperties:
  formFields:
    - default: ${HOST_PORT}
      edit: true
      envKey: PANEL_APP_PORT_HTTP
      labelEn: Port
      labelZh: 端口
      label:
        en: 'Port'
        zh: '端口'
        zh-Hant: '埠'
        ja: 'ポート'
        ko: '포트'
        ru: 'Порт'
        ms: 'Port'
        pt-br: 'Porta'
      required: true
      rule: paramPort
      type: number
    - default: ./data/${APP_KEY}
      edit: true
      envKey: DATA_PATH
      labelEn: Data folder path
      labelZh: 数据文件夹路径
      label:
        en: 'Data folder path'
        zh: '数据文件夹路径'
        zh-Hant: '資料夾路徑'
        ja: 'データフォルダパス'
        ko: '데이터 폴더 경로'
        ru: 'Путь к папке данных'
        ms: 'Laluan folder data'
        pt-br: 'Caminho da pasta de dados'
      required: true
      type: text
EOF

cat > "${VER_DIR}/docker-compose.yml" <<EOF
services:
  ${APP_KEY}:
    container_name: \${CONTAINER_NAME}
    restart: always
    networks:
      - 1panel-network
    ports:
      - "\${PANEL_APP_PORT_HTTP}:${INNER_PORT}"
    volumes:
      - "\${DATA_PATH}:/data"
    image: ${IMAGE}
    labels:
      createdBy: "Apps"

networks:
  1panel-network:
    external: true
EOF

cat > "${VER_DIR}/.env.sample" <<EOF
CONTAINER_NAME="${APP_KEY}"
PANEL_APP_PORT_HTTP="${HOST_PORT}"
DATA_PATH="./data/${APP_KEY}"
EOF

echo "完成。请编辑上述 TODO 后提交:"
echo "  git add apps/${APP_KEY} && git commit -m \"feat: add extension app ${APP_KEY}\""
