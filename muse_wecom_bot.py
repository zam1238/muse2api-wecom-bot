import base64
import hashlib
import os
import re
import struct
import threading
import time
import xml.etree.ElementTree as ET
from Crypto.Cipher import AES
from flask import Flask, request
import requests

CONF_PATH = "/etc/muse_wecom.conf"


def load_kv(path):
    d = {}
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    d[k.strip()] = v.strip().strip('"').strip("'")
    return d


CFG = load_kv(CONF_PATH)

MUSE_BASE = CFG.get("MUSE_BASE", "").rstrip("/")
MUSE_KEY = CFG.get("MUSE_KEY", "")
MAX_HISTORY = int(CFG.get("MAX_HISTORY", "60") or 60)

CORP_ID = CFG.get("CORP_ID", "")
AGENT_ID = int(CFG.get("AGENT_ID", "0") or 0)
SECRET = CFG.get("SECRET", "")
TOKEN = CFG.get("TOKEN", "")
RAW_AES_KEY = CFG.get("ENCODING_AES_KEY", "")
AES_KEY = base64.b64decode(RAW_AES_KEY + "=") if RAW_AES_KEY else b""
ALLOWED_USERS = {u.strip() for u in CFG.get("ALLOWED_USERS", "").split(",") if u.strip()}
LISTEN_PORT = int(CFG.get("LISTEN_PORT", "8099") or 8099)

app = Flask(__name__)
HISTORY = {}
TOKEN_CACHE = {"token": "", "exp": 0}


def get_access_token():
    now = time.time()
    if TOKEN_CACHE["token"] and now < TOKEN_CACHE["exp"] - 60:
        return TOKEN_CACHE["token"]
    r = requests.get(
        "https://qyapi.weixin.qq.com/cgi-bin/gettoken",
        params={"corpid": CORP_ID, "corpsecret": SECRET},
        timeout=15,
    ).json()
    if "access_token" not in r:
        raise RuntimeError(f"gettoken失败: {r}")
    TOKEN_CACHE["token"] = r["access_token"]
    TOKEN_CACHE["exp"] = now + int(r.get("expires_in", 7200))
    return TOKEN_CACHE["token"]


def verify_sig(msg_sig, timestamp, nonce, encrypt):
    items = sorted([TOKEN, timestamp, nonce, encrypt])
    sha = hashlib.sha1("".join(items).encode("utf-8")).hexdigest()
    return sha == msg_sig


def decrypt_msg(encrypt_b64):
    cipher = AES.new(AES_KEY, AES.MODE_CBC, AES_KEY[:16])
    plain = cipher.decrypt(base64.b64decode(encrypt_b64))
    pad = plain[-1]
    content = plain[16:-pad]
    xml_len = struct.unpack("!I", content[:4])[0]
    xml_bytes = content[4 : 4 + xml_len]
    return xml_bytes.decode("utf-8")


def wecom_send_text(user_id, text):
    tk = get_access_token()
    requests.post(
        f"https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token={tk}",
        json={
            "touser": user_id,
            "msgtype": "text",
            "agentid": AGENT_ID,
            "text": {"content": text[:2000]},
        },
        timeout=20,
    )


def wecom_upload_and_send_media(user_id, media_type, filename, file_bytes):
    tk = get_access_token()
    up = requests.post(
        f"https://qyapi.weixin.qq.com/cgi-bin/media/upload?access_token={tk}&type={media_type}",
        files={"media": (filename, file_bytes)},
        timeout=120,
    ).json()
    media_id = up.get("media_id")
    if not media_id:
        wecom_send_text(user_id, f"媒体上传失败: {up}")
        return
    requests.post(
        f"https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token={tk}",
        json={
            "touser": user_id,
            "msgtype": media_type,
            "agentid": AGENT_ID,
            media_type: {"media_id": media_id},
        },
        timeout=30,
    )


def normalize_url(u):
    if not u:
        return ""
    root = MUSE_BASE[:-3] if MUSE_BASE.endswith("/v1") else MUSE_BASE
    return f"{root}{u}" if u.startswith("/") else u


def process_user_text(user_id, text):
    headers = {"Authorization": f"Bearer {MUSE_KEY}", "Content-Type": "application/json"}
    if text == "/clear":
        HISTORY[user_id] = []
        wecom_send_text(user_id, "对话上下文已清空。")
        return

    img_size = (
        "9:16"
        if any(k in text for k in ["竖屏", "手机壁纸", "9:16"])
        else ("16:9" if any(k in text for k in ["横屏", "16:9"]) else "1:1")
    )
    vid_size = "9:16" if any(k in text for k in ["竖屏", "9:16"]) else "16:9"
    m_sec = re.search(r"(\d+)\s*秒", text)
    duration = max(3, min(15, int(m_sec.group(1)))) if m_sec else 5

    if text.startswith("/img") or any(k in text for k in ["画一张", "生成图片", "生成一张", "手机壁纸", "画个"]):
        prompt = text[4:].strip() if text.startswith("/img") else text
        wecom_send_text(user_id, f"正在生成图片（{img_size}），请稍候...")
        try:
            r = requests.post(
                f"{MUSE_BASE}/images/generations",
                headers=headers,
                json={"model": "muse-image", "prompt": prompt, "size": img_size, "response_format": "url"},
                timeout=240,
            ).json()
            img_url = normalize_url(r["data"][0]["url"])
            img_bytes = requests.get(img_url, timeout=60).content
            wecom_upload_and_send_media(user_id, "image", "image.png", img_bytes)
        except Exception as e:
            wecom_send_text(user_id, f"生图失败: {e}")
        return

    if text.startswith("/vid") or any(k in text for k in ["生成视频", "做个视频", "拍个视频", "生成一段视频"]):
        prompt = text[4:].strip() if text.startswith("/vid") else text
        wecom_send_text(user_id, f"已提交生视频任务（{duration}秒/{vid_size}），完成后自动发给你...")
        try:
            task = requests.post(
                f"{MUSE_BASE}/videos",
                headers=headers,
                json={"model": "muse-video", "prompt": prompt, "duration": duration, "size": vid_size},
                timeout=60,
            ).json()
            tid = task.get("id")
            for _ in range(140):
                time.sleep(5)
                st = requests.get(f"{MUSE_BASE}/videos/{tid}", headers=headers, timeout=30).json()
                status = str(st.get("status") or "").lower()
                if status in ("succeeded", "completed"):
                    vurl = normalize_url((st.get("result") or {}).get("url") or st.get("url") or st.get("video_url"))
                    vbytes = requests.get(vurl, timeout=180).content
                    wecom_upload_and_send_media(user_id, "video", "video.mp4", vbytes)
                    return
                elif status in ("failed", "error"):
                    wecom_send_text(user_id, f"视频生成失败: {st}")
                    return
        except Exception as e:
            wecom_send_text(user_id, f"生视频异常: {e}")
        return

    msgs = HISTORY.setdefault(user_id, [])
    msgs.append({"role": "user", "content": text})
    if len(msgs) > MAX_HISTORY:
        msgs[:] = msgs[-MAX_HISTORY:]
    try:
        r = requests.post(
            f"{MUSE_BASE}/chat/completions",
            headers=headers,
            json={"model": "muse-spark", "messages": msgs},
            timeout=120,
        ).json()
        reply = r["choices"][0]["message"]["content"]
        msgs.append({"role": "assistant", "content": reply})
        wecom_send_text(user_id, reply)
    except Exception as e:
        wecom_send_text(user_id, f"对话失败: {e}")


@app.route("/wecom", methods=["GET", "POST"])
def wecom_callback():
    msg_sig = request.args.get("msg_signature", "")
    ts = request.args.get("timestamp", "")
    nonce = request.args.get("nonce", "")
    if request.method == "GET":
        echostr = request.args.get("echostr", "")
        if verify_sig(msg_sig, ts, nonce, echostr):
            return decrypt_msg(echostr)
        return "invalid signature", 403

    root = ET.fromstring(request.data)
    encrypt = root.findtext("Encrypt") or ""
    if not verify_sig(msg_sig, ts, nonce, encrypt):
        return "invalid signature", 403
    xml_str = decrypt_msg(encrypt)
    msg_root = ET.fromstring(xml_str)
    from_user = msg_root.findtext("FromUserName") or ""
    msg_type = msg_root.findtext("MsgType") or ""
    content = (msg_root.findtext("Content") or "").strip()

    print(f"WeCom msg from={from_user} type={msg_type} content={content[:50]}", flush=True)
    if ALLOWED_USERS and from_user not in ALLOWED_USERS:
        wecom_send_text(from_user, f"无访问权限。如需开通，请把你的 ID 发给管理员：{from_user}")
        return "success"

    if msg_type == "text" and content:
        threading.Thread(target=process_user_text, args=(from_user, content), daemon=True).start()
    return "success"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=LISTEN_PORT)
