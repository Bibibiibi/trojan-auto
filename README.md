# trojan一键脚本

运行 wget -O trojan.sh https://raw.githubusercontent.com/Bibibiibi/trojan-auto/refs/heads/main/trojan.sh && chmod +x trojan.sh && ./trojan.sh

卸载  wget -O remove.sh https://raw.githubusercontent.com/Bibibiibi/trojan-auto/refs/heads/main/remove.sh && chmod +x remove.sh && ./remove.sh

systemctl daemon-reload
systemctl enable trojan-go
systemctl restart trojan-go

日志 journalctl -u trojan-go -f


