#!/usr/bin/env bash
set -e

APP_DIR="/opt/muse2api-wecom-bot"
VENV_DIR="/opt/muse_wecom_venv"
CONF_FILE="/etc/muse_wecom.conf"
SERVICE_FILE="/etc/systemd/system/muse-wecom.service"
REPO_RAW="https://raw.githubusercontent.com/zam1238/muse2api-wecom-bot/main"

echo ">>> 1. 创建运行目录与 Python 虚拟环境..."
mkdir -p "$APP_DIR"
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR" 2>/dev/null || {
    apt-get update -y && apt-get install -y python3-venv python3-pip
    python3 -m venv "$VENV_DIR"
  }
fi

"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install flask pycryptodome requests pillow

echo ">>> 2. 下载或复制程序文件..."
if [ -f "./muse_wecom_bot.py" ] && [ -f "./musewecom.sh" ]; then
  cp -f ./muse_wecom_bot.py "$APP_DIR/muse_wecom_bot.py"
  cp -f ./musewecom.sh "$APP_DIR/musewecom.sh"
  cp -f ./musewecom.sh /usr/local/bin/musewecom
else
  curl -fsSL "$REPO_RAW/muse_wecom_bot.py" -o "$APP_DIR/muse_wecom_bot.py"
  curl -fsSL "$REPO_RAW/musewecom.sh" -o "$APP_DIR/musewecom.sh"
  cp -f "$APP_DIR/musewecom.sh" /usr/local/bin/musewecom
fi
chmod +x /usr/local/bin/musewecom "$APP_DIR/musewecom.sh"

echo ">>> 3. 初始化配置文件..."
if [ ! -f "$CONF_FILE" ]; then
  cat > "$CONF_FILE" << 'EOF'
MUSE_BASE=""
MUSE_KEY=""
CORP_ID=""
AGENT_ID=""
SECRET=""
TOKEN=""
ENCODING_AES_KEY=""
ALLOWED_USERS=""
MAX_HISTORY="60"
LISTEN_PORT="8099"
EOF
fi

echo ">>> 4. 配置 systemd 守护进程..."
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Muse2API WeCom Bot
After=network.target

[Service]
Type=simple
ExecStart=$VENV_DIR/bin/python $APP_DIR/muse_wecom_bot.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable muse-wecom.service

echo ""
echo "=================================================="
echo "安装完成！请直接输入命令打开配置菜单："
echo "  musewecom"
echo "在菜单中依次填写 1~10 项参数后，选 12 重启服务即可。"
echo "=================================================="
