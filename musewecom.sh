#!/usr/bin/env bash
set -e

CONF_FILE="/etc/muse_wecom.conf"
BACKUP_FILE="/root/muse_wecom_backup.conf"
REPO_DIR="/opt/muse2api-wecom-bot"
VENV_PIP="/opt/muse_wecom_venv/bin/pip"
SERVICE_NAME="muse-wecom.service"
API_MAIN="https://api.github.com/repos/zam1238/muse2api-wecom-bot/commits/main"

get_val() {
    local key="$1"
    [ -f "$CONF_FILE" ] || { echo ""; return; }
    local line
    line=$(grep -E "^${key}=" "$CONF_FILE" | tail -n 1 || true)
    val="${line#*=}"
    val="${val#\"}"
    val="${val%\"}"
    val="${val#\'}"
    val="${val%\'}"
    echo "$val"
}

mask_val() {
    local s="$1"
    local n=${#s}
    if [ "$n" -eq 0 ]; then
        echo ""
    elif [ "$n" -le 8 ]; then
        echo "${s:0:2}****${s: -2}"
    else
        echo "${s:0:4}****${s: -4}"
    fi
}

set_kv() {
    local key="$1"
    local val="$2"
    touch "$CONF_FILE"
    if grep -qE "^${key}=" "$CONF_FILE"; then
        sed -i "s|^${key}=.*|${key}=\"${val}\"|" "$CONF_FILE"
    else
        echo "${key}=\"${val}\"" >> "$CONF_FILE"
    fi
}

backup_conf() {
    if [ -f "$CONF_FILE" ]; then
        cp -f "$CONF_FILE" "$BACKUP_FILE"
        echo "已备份配置与白名单到 $BACKUP_FILE"
        grep -E "^ALLOWED_USERS=" "$BACKUP_FILE" || true
    else
        echo "未找到 $CONF_FILE，无需备份。"
    fi
}

restore_conf() {
    if [ -f "$BACKUP_FILE" ]; then
        cp -f "$BACKUP_FILE" "$CONF_FILE"
        systemctl restart "$SERVICE_NAME"
        echo "已从 $BACKUP_FILE 恢复配置与白名单，并重启 $SERVICE_NAME"
    else
        echo "未找到备份文件 $BACKUP_FILE"
    fi
}

update_repo() {
    echo "1/4 备份当前配置与白名单..."
    backup_conf
    echo "2/4 从 GitHub 拉取最新代码..."
    mkdir -p "$REPO_DIR"
    if [ -d "$REPO_DIR/.git" ]; then
        git -C "$REPO_DIR" fetch --all
        git -C "$REPO_DIR" reset --hard origin/main
    else
        SHA=$(curl -fsSL "$API_MAIN" | sed -n 's/.*"sha": *"\([0-9a-f]\{40\}\)\".*/\1/p' | head -n 1 || true)
        BASE_URL="https://raw.githubusercontent.com/zam1238/muse2api-wecom-bot/${SHA:-main}"
        curl -fsSL "$BASE_URL/muse_wecom_bot.py" -o "$REPO_DIR/muse_wecom_bot.py"
        curl -fsSL "$BASE_URL/musewecom.sh" -o "$REPO_DIR/musewecom.sh"
        curl -fsSL "$BASE_URL/requirements.txt" -o "$REPO_DIR/requirements.txt"
        curl -fsSL "$BASE_URL/install.sh" -o "$REPO_DIR/install.sh" || true
    fi
    echo "3/4 安装/更新 Python 依赖..."
    if [ -f "$REPO_DIR/requirements.txt" ] && [ -x "$VENV_PIP" ]; then
        "$VENV_PIP" install -q -r "$REPO_DIR/requirements.txt"
    fi
    if [ -f "$REPO_DIR/musewecom.sh" ]; then
        cp -f "$REPO_DIR/musewecom.sh" /usr/local/bin/musewecom
        chmod +x /usr/local/bin/musewecom "$REPO_DIR/musewecom.sh"
    fi
    echo "4/4 还原配置与白名单并重启服务..."
    [ -f "$BACKUP_FILE" ] && cp -f "$BACKUP_FILE" "$CONF_FILE"
    systemctl restart "$SERVICE_NAME"
    echo "更新完成，当前服务状态: $(systemctl is-active "$SERVICE_NAME")"
}

while true; do
    status=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null || true)
    clear
    echo "=================================================="
    echo " 服务状态: ${status}   配置文件: ${CONF_FILE}"
    echo "=================================================="
    echo "【单独配置各项变量】"
    echo " 1. 设置 MUSE_BASE          [$(get_val MUSE_BASE)]"
    echo " 2. 设置 MUSE_KEY           [$(mask_val "$(get_val MUSE_KEY)")]"
    echo " 3. 设置 CORP_ID (企业ID)   [$(get_val CORP_ID)]"
    echo " 4. 设置 AGENT_ID           [$(get_val AGENT_ID)]"
    echo " 5. 设置 SECRET             [$(mask_val "$(get_val SECRET)")]"
    echo " 6. 设置 TOKEN              [$(mask_val "$(get_val TOKEN)")]"
    echo " 7. 设置 ENCODING_AES_KEY   [$(mask_val "$(get_val ENCODING_AES_KEY)")]"
    echo " 8. 设置 ALLOWED_USERS      [$(get_val ALLOWED_USERS)]"
    echo " 9. 设置 MAX_HISTORY        [$(get_val MAX_HISTORY)]"
    echo "10. 设置 LISTEN_PORT        [$(get_val LISTEN_PORT)]"
    echo "--------------------------------------------------"
    echo "【快捷与服务管理】"
    echo "11. 从 TG 机器人配置一键导入 MUSE_BASE / MUSE_KEY"
    echo "12. 启动 / 重启服务 (修改配置后点此生效)"
    echo "13. 停止服务"
    echo "14. 查看实时日志 (按 Ctrl+C 退出日志)"
    echo "15. 备份 / 恢复白名单与配置"
    echo "16. 一键更新代码 (自动备份白名单并重启)"
    echo " 0. 退出菜单"
    echo "=================================================="
    read -rp "请输入选项编号 [0-16]: " opt
    case "$opt" in
        1) read -rp "请输入新的 MUSE_BASE: " v; [ -n "$v" ] && set_kv MUSE_BASE "$v" ;;
        2) read -rp "请输入新的 MUSE_KEY: " v; [ -n "$v" ] && set_kv MUSE_KEY "$v" ;;
        3) read -rp "请输入新的 CORP_ID: " v; [ -n "$v" ] && set_kv CORP_ID "$v" ;;
        4) read -rp "请输入新的 AGENT_ID: " v; [ -n "$v" ] && set_kv AGENT_ID "$v" ;;
        5) read -rp "请输入新的 SECRET: " v; [ -n "$v" ] && set_kv SECRET "$v" ;;
        6) read -rp "请输入新的 TOKEN: " v; [ -n "$v" ] && set_kv TOKEN "$v" ;;
        7) read -rp "请输入新的 ENCODING_AES_KEY: " v; [ -n "$v" ] && set_kv ENCODING_AES_KEY "$v" ;;
        8)
            cur=$(get_val ALLOWED_USERS)
            echo "当前白名单: ${cur:-空}"
            read -rp "请输入新的白名单(英文逗号分隔，输入 - 清空): " v
            if [ "$v" = "-" ]; then
                set_kv ALLOWED_USERS ""
            elif [ -n "$v" ]; then
                set_kv ALLOWED_USERS "$v"
            fi
            ;;
        9) read -rp "请输入新的 MAX_HISTORY: " v; [ -n "$v" ] && set_kv MAX_HISTORY "$v" ;;
        10) read -rp "请输入新的 LISTEN_PORT: " v; [ -n "$v" ] && set_kv LISTEN_PORT "$v" ;;
        11)
            tg_conf=$(find /opt /root /etc -maxdepth 3 -name "*tg*" -o -name "*muse*" 2>/dev/null | grep -E "\.env|\.conf|config" | head -n 1 || true)
            if [ -n "$tg_conf" ]; then
                tb=$(grep -E "^(MUSE_BASE|BASE_URL)=" "$tg_conf" | head -n 1 | cut -d= -f2- | tr -d "\"'" || true)
                tk=$(grep -E "^(MUSE_KEY|API_KEY)=" "$tg_conf" | head -n 1 | cut -d= -f2- | tr -d "\"'" || true)
                [ -n "$tb" ] && set_kv MUSE_BASE "$tb"
                [ -n "$tk" ] && set_kv MUSE_KEY "$tk"
                echo "已从 $tg_conf 导入配置。"
            else
                echo "未自动找到 TG 机器人配置文件。"
            fi
            read -rp "按回车键继续..."
            ;;
        12) systemctl restart "$SERVICE_NAME"; systemctl status "$SERVICE_NAME" --no-pager -l; read -rp "按回车键继续..." ;;
        13) systemctl stop "$SERVICE_NAME"; echo "已停止 $SERVICE_NAME"; read -rp "按回车键继续..." ;;
        14) journalctl -u "$SERVICE_NAME" -f ;;
        15)
            echo "1) 备份配置与白名单 -> $BACKUP_FILE"
            echo "2) 恢复配置与白名单 <- $BACKUP_FILE"
            read -rp "请选择 [1-2]: " bk
            [ "$bk" = "1" ] && backup_conf
            [ "$bk" = "2" ] && restore_conf
            read -rp "按回车键继续..."
            ;;
        16) update_repo; read -rp "按回车键继续..." ;;
        0) exit 0 ;;
    esac
done
