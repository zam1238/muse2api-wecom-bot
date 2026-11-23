![Build](https://img.shields.io/github/actions/workflow/status/zam1238/muse2api-wecom-bot/check.yml?style=for-the-badge&logo=githubactions&logoColor=white&label=Build)

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


🔗 企业微信后台配置清单  企业微信入口 https://work.weixin.qq.com/
[!IMPORTANT]
以下 3 步为必配项，缺一不可，否则机器人无法收发消息或新成员无法看到应用。

配置 API 接收回调：

先在服务器 musewecom 面板选 12 启动服务（确保状态为 active）。

进入管理后台 → 应用管理 → 你的自建应用 → 接收消息 → 设置API接收：

URL：http://你的服务器IP:8099/wecom（如已绑域名可填 https://你的域名/wecom）

Token / EncodingAESKey：填入与服务器菜单 6、7 项完全一致的值后点击 保存。

添加企业可信 IP：

在自建应用页面底部找到 企业可信IP → 配置，填入当前运行机器人的服务器公网 IP。

设置应用可见范围 & 放行白名单：

在自建应用详情页点击 可见范围 → 修改，勾选需要使用的成员或整个部门（应用主页保持为空，切勿填写网页地址）。

让成员在工作台点开应用发送一条消息 → 管理员在服务器运行 musewecom 选 14 查看日志里的 WeCom msg from=... → 选 8 将该 ID 加入 ALLOWED_USERS → 选 12 重启生效。          


企业微信鸡肋 生成视频大于10M 就只出下载链接
            

| 菜单编号 | 参数名 | 说明与示例 | 获取位置 |
| :--- | :--- | :--- | :--- |
| **1** | `MUSE_BASE` | Muse2API 接口地址（以 `/v1` 结尾，如 `https://你的域名/v1`） | 你的 Muse2API 服务端地址 |
| **2** | `MUSE_KEY` | Muse2API 访问密钥（API Key） | Muse2API 后台或菜单第 `11` 项从已有配置导入 |
| **3** | `CORP_ID` | 企业 ID / 团队 ID（形如 `ww...` 开头的字符串） | 企业微信管理后台 -> **我的企业 / 我的团队** 底部查看 |
| **4** | `AGENT_ID` | 自建应用 AgentId（形如 `1000002` 的数字） | 企业微信管理后台 -> **应用管理** -> 点开自建应用，顶部查看 |
| **5** | `SECRET` | 自建应用 Secret | 企业微信管理后台 -> **应用管理** -> 自建应用顶部点击 **查看 / 发送**，在企业微信客户端消息中复制 |
| **6** | `TOKEN` | 接收消息服务器配置的 Token | 自建应用详情页 -> **接收消息** -> **设置API接收** -> 点击 **随机获取** |
| **7** | `ENCODING_AES_KEY` | 接收消息服务器配置的 EncodingAESKey | 同上，在 **设置API接收** 页面点击 **随机获取** |
| **8** | `ALLOWED_USERS` | 允许使用机器人的成员 UserID，多个用英文逗号隔开（如 `UserA,UserB`） | 成员首次发消息后，在菜单第 `14` 项实时日志 `WeCom msg from=...` 中获取，或在后台通讯录成员详情查看 **账号** |
| **9** | `MAX_HISTORY` | 单用户保留的上下文消息条数（默认 `60`） | 按需填写整数 |
| **10** | `LISTEN_PORT` | 本地监听端口（默认 `8099`） | 按需填写未被占用的端口 |


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

 在你的 VPS 终端执行一键安装命令，然后直接敲 **`musewecom`**，按菜单编号 `1` 到 `10` 把你刚拿到的 5 个企业微信参数逐项填进去（选项 `11` 还能一键把 TG 机器人那边的 `MUSE_BASE` 和 `MUSE_KEY` 导过来），最后按 `12` 启动服务，回企业微信网页点【保存】就全部搞定了。
