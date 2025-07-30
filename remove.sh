#!/bin/bash

set -e

echo -e "\n🧹 开始卸载 Trojan / Trojan-Go..."

# 停止服务
systemctl stop trojan 2>/dev/null || true
systemctl disable trojan 2>/dev/null || true
systemctl stop trojan-go 2>/dev/null || true
systemctl disable trojan-go 2>/dev/null || true

# 删除 systemd 配置
rm -f /etc/systemd/system/trojan.service
rm -f /etc/systemd/system/trojan-go.service
systemctl daemon-reload

# 删除二进制
rm -f /usr/local/bin/trojan
rm -f /usr/local/bin/trojan-go

# 删除配置文件
rm -rf /usr/local/etc/trojan
rm -rf /usr/local/etc/trojan-go

# 删除证书
rm -rf /etc/trojan
rm -rf /etc/trojan-go

# 删除临时文件
rm -rf ~/trojan*
rm -rf ~/.acme.sh

echo -e "\n✅ Trojan / Trojan-Go 卸载完成！"
