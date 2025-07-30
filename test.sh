#!/bin/bash

set -e

echo -e "\n=== Trojan-Go 自动部署脚本（含架构适配）===\n"

# ===== 输入部分 =====
read -rp "请输入你的域名（必须已解析到本机 IP）: " DOMAIN
read -rp "请输入用于申请证书的邮箱: " EMAIL

PASSWORD=$(openssl rand -base64 16)
PORT=$(shuf -i 40000-60000 -n 1)

# ===== 架构识别 =====
ARCH=$(uname -m)

case "$ARCH" in
  x86_64) ARCH_DL="amd64" ;;
  aarch64) ARCH_DL="armv8" ;;       # ARM 64 → armv8
  armv7l) ARCH_DL="armv7" ;;        # ARM 32 → armv7
  armv6l) ARCH_DL="armv6" ;;
  armv5*) ARCH_DL="armv5" ;;
  *) echo "❌ 不支持的架构: $ARCH"; exit 1 ;;
esac


echo -e "\n🧠 检测到架构: $ARCH → 下载版本: $ARCH_DL"
echo -e "🔐 密码: $PASSWORD"
echo -e "📡 端口: $PORT"
echo -e "🌐 域名: $DOMAIN\n"

# ===== 安装依赖 =====
apt update
apt install -y curl wget socat git cron unzip

# ===== 获取 ECC 证书 =====
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
systemctl stop nginx 2>/dev/null || true
~/.acme.sh/acme.sh --issue --standalone -d "$DOMAIN" --force --keylength ec-256 --accountemail "$EMAIL"

mkdir -p /etc/trojan-go
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" --ecc \
  --key-file /etc/trojan-go/private.key \
  --fullchain-file /etc/trojan-go/cert.crt --force

# ===== 下载 Trojan-Go 对应架构版本 =====
cd /usr/local/bin
wget -O trojan-go.zip "https://github.com/p4gefau1t/trojan-go/releases/latest/download/trojan-go-linux-$ARCH_DL.zip"
unzip trojan-go.zip
chmod +x trojan-go
rm -f trojan-go.zip

# ===== 写入配置文件 =====
mkdir -p /usr/local/etc/trojan-go
cat > /usr/local/etc/trojan-go/config.json <<EOF
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": $PORT,
  "remote_addr": "example.com",
  "remote_port": 443,
  "password": ["$PASSWORD"],
  "ssl": {
    "cert": "/etc/trojan-go/cert.crt",
    "key": "/etc/trojan-go/private.key",
    "sni": "$DOMAIN"
  },
  "websocket": {
    "enabled": false
  },
  "transport_plugin": {
    "enabled": false
  },
  "udp": {
    "enabled": true,
    "prefer_ipv4": true
  }
}
EOF

# ===== systemd 服务配置 =====
cat > /etc/systemd/system/trojan-go.service <<EOF
[Unit]
Description=Trojan-Go Service
After=network.target

[Service]
ExecStart=/usr/local/bin/trojan-go -config /usr/local/etc/trojan-go/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# ===== 启动服务 =====
systemctl daemon-reload
systemctl enable trojan-go
systemctl restart trojan-go

# ===== 输出配置信息 =====
echo -e "\n✅ Trojan-Go 部署完成！以下是 Surge/Mihomo 配置：\n"
echo "🇯🇵 TrojanGo = trojan,$DOMAIN,$PORT,password=\"$PASSWORD\",tls=true,sni=$DOMAIN,skip-cert-verify=true,udp-relay=true"
