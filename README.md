# muse2api-wecom-bot

基于上游接口项目实现的企业微信自建应用机器人，支持在普通微信（通过企业微信插件）中直接对话、生成图片及异步生成视频，内置白名单防滥用与交互式单项参数配置菜单。

本项目基于上游接口项目实现：https://github.com/czg86389-hub/muse2api

## 一键安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zam1238/muse2api-wecom-bot/main/install.sh)
```

```bash
curl -fsSL https://raw.githubusercontent.com/zam1238/muse2api-wecom-bot/main/install.sh -o install.sh && bash install.sh
```

安装完成后，在终端直接输入 musewecom 即可进入管理菜单，逐项单独填写以下配置变量：

MUSE_BASE：上游 Muse 接口地址

MUSE_KEY：Muse API Key

CORP_ID：企业微信企业 ID

AGENT_ID：企业微信自建应用 AgentId

SECRET：企业微信自建应用 Secret

TOKEN：API 接收消息回调 Token

ENCODING_AES_KEY：API 接收消息回调 EncodingAESKey

ALLOWED_USERS：允许访问的用户 ID 白名单（英文逗号分隔，留空不限）

MAX_HISTORY：上下文记忆条数（默认 60 条，发送 /clear 清空当前上下文）

LISTEN_PORT：回调监听端口（默认 8099）

---

### 三、你现在只需要做两步

1. 在你的 GitHub（`zadf`）新建一个仓库 **`muse2api-wecom-bot`**，把上面这 4 个文件创建并提交进去。
2. 在你的 VPS 终端执行一键安装命令，然后直接敲 **`musewecom`**，按菜单编号 `1` 到 `10` 把你刚拿到的 5 个企业微信参数逐项填进去（选项 `11` 还能一键把 TG 机器人那边的 `MUSE_BASE` 和 `MUSE_KEY` 导过来），最后按 `12` 启动服务，回企业微信网页点【保存】就全部搞定了。
