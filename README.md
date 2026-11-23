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


企业微信入口 https://work.weixin.qq.com/

注册企业微信 我的团队 获取CORP_ID=团队 ID（形如 ww...开头的字符串）
            应用管理-创建应用 获取 AGENT_ID=形如 `1000002
            同上界面下滑-接收消息启用API  获取TOKEN=随机
                                EncodingAESKey？=随机
                                接收消息查看 / 发送 获取Secret 
    5个数值保存记事本  在VPS一键安装 填好1 2 3 4 5 6 7  监听端口8099  在回到网页企业微信 接收消息API URL填https://IP/wecom   下面数值 在记事本保存填上 保存
    在自创的应该下方有个企业可信IP填入vps IPv4的IP（不支持ipv6）
          回到vps快捷命令musewecom 选8 白名单微信 加入
            

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
