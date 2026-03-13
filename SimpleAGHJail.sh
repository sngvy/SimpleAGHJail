#!/bin/bash

# Стили и цвета
BOLD='\033[1m'
B_CYAN='\033[1;36m'
B_GREEN='\033[1;32m'
B_YELLOW='\033[1;33m'
B_RED='\033[1;31m'
NC='\033[0m'

# Проверка на запуск от root
if [ "$EUID" -ne 0 ]; then
    echo -e "${B_RED}Ошибка: Пожалуйста, запустите скрипт от имени root (sudo).${NC}"
    exit 1
fi

echo -e "${B_CYAN}Настройка защиты AdGuard Home через fail2ban...${NC}"

# В /etc/fail2ban/filter.d/agh-tls.conf помещает
cat <<EOF > /etc/fail2ban/filter.d/agh-tls.conf
[Definition]
# Регулярное выражение для поиска ошибок TLS в выводе journalctl
failregex = ^.*http: TLS handshake error from <HOST>:\d+:.*$
ignoreregex =
EOF

# В /etc/fail2ban/jail.d/agh-tls.local помещает
cat <<EOF > /etc/fail2ban/jail.d/agh-tls.local
[agh-tls]
enabled = true
# Указываем порты, которые защищаем (HTTPS, DNS-over-TLS, Web UI)
port    = 443,853,53,3000,4000
filter  = agh-tls
# Используем journald вместо чтения файла
backend = systemd
journalmatch = _SYSTEMD_UNIT=AdGuardHome.service
# Параметры бана
maxretry = 20
findtime = 60
bantime  = 24h
EOF

# Перезапускает fail2ban
echo -e "${B_YELLOW}Перезапуск fail2ban...${NC}"
systemctl restart fail2ban

echo -e "${B_GREEN}Установка успешно завершена!${NC}"
echo -e "${BOLD}Статус активного бана:${NC} ${B_RED}fail2ban-client status agh-tls${NC}"
