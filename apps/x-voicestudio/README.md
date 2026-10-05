# VoiceStudio — 完全本地的语音工作室(GPU 模式)

> 扩展应用,由本仓库(skingko/1panel_app)维护。[上游项目 debpalash/VoiceStudio](https://github.com/debpalash/VoiceStudio) · [中文文档](https://github.com/debpalash/VoiceStudio/blob/main/README_CN.md)

开源且完全本地化的 ElevenLabs 替代:语音克隆、语音设计、视频配音、听写、转录、有声书制作,支持 646 种语言。使用官方镜像 `ghcr.io/debpalash/voicestudio`,**NVIDIA GPU 加速模式**(compose 已含 GPU 设备直通,上游 GPU profile 原样写法)。

## 前置要求

- **NVIDIA GPU + 宿主机已装驱动**(`nvidia-smi` 可用),显存建议 8GB+
- **宿主机 Docker 已装 nvidia-container-toolkit**(容器用 GPU 的标准前提):

  ```bash
  # Debian/Ubuntu
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker
  ```

## 使用

- 打开 `http://<主机>:<端口>` 即是 Web 工作台;API 调用以面板里生成的 `OMNIVOICE_API_KEY` 作 `Authorization: Bearer <key>`
- **镜像体积数 GB**(含 CUDA/PyTorch 运行时),国内网络首次拉取可能缓慢,中断后重试会续传已完成的层
- **首次启动下载约 4GB 模型**(进度看容器日志),健康检查通过后(最长约 3 分钟)界面才可用
- 模型与音频库都在数据目录(约 10GB,注意磁盘空间)
- 国内网络下载模型慢/失败时,安装面板的「模型下载镜像」填 `https://hf-mirror.com`
- 下载 HuggingFace 门控模型需在面板填 `HF_TOKEN`

## 说明

- 仅 amd64(上游未发布 arm64 镜像)
- **不可见水印默认关闭**:水印模型经 urllib 直连 huggingface.co 下载(不走 HF_ENDPOINT 镜像),国内网络下每次合成会空耗约 160 秒重试,故首次启动预置 `prefs.json` 关闭它。需要水印时在应用「设置」中打开,并手动下载一次模型(网络可达即可)
- 7443 worker 控制端口默认不发布(仅分布式 worker 场景需要,见[上游 compose](https://github.com/debpalash/VoiceStudio/blob/main/deploy/docker-compose.yml))
- 公网暴露建议再套反向代理;局域网内已有 API key 鉴权
- AMD 显卡(ROCm)需改用 `:stable-rocm` 镜像并替换设备直通写法(`/dev/kfd`、`/dev/dri`),参考上游 compose 的 rocm 服务
