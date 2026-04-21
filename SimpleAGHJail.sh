#!/bin/bash

# Стили и цвета
BOLD='\033[1m'
B_CYAN='\033[1;36m'
B_GREEN='\033[1;32m'
B_YELLOW='\033[1;33m'
B_RED='\033[1;31m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${B_RED}Ошибка: Запустите от имени root.${NC}"
    exit 1
fi

echo -e "${B_CYAN}Конфигурация AdGuard Home Protection (fail2ban)${NC}"

# 1. Проверка и установка fail2ban
if ! command -v fail2ban-client >/dev/null; then
    echo -e "${B_YELLOW}Установка fail2ban...${NC}"
    apt-get update -qq && apt-get install -y fail2ban -qq
fi

# 2. Создание фильтра
echo -e "${B_YELLOW}Настройка фильтра agh-tls...${NC}"
cat <<EOF > /etc/fail2ban/filter.d/agh-tls.conf
[Definition]
failregex = ^.*http: TLS handshake error from <HOST>:\d+:.*$
ignoreregex =
EOF

# 3. Создание конфигурации Jail
echo -e "${B_YELLOW}Настройка параметров блокировки...${NC}"
cat <<EOF > /etc/fail2ban/jail.d/agh-tls.local
[agh-tls]
enabled = true
port    = 443,853,53,3000,4000
filter  = agh-tls
backend = systemd
journalmatch = _SYSTEMD_UNIT=AdGuardHome.service
maxretry = 20
findtime = 60
bantime  = 24h
EOF

# 4. Перезапуск службы
echo -e "${B_CYAN}Перезапуск fail2ban...${NC}"
systemctl restart fail2ban

# 5. Проверка статуса
if systemctl is-active --quiet fail2ban; then
    echo -e "${B_GREEN}Защита AdGuard Home успешно настроена!${NC}"
    echo -e "${BOLD}Для проверки статуса используйте:${NC} ${B_CYAN}fail2ban-client status agh-tls${NC}"
else
    echo -e "${B_RED}Ошибка: fail2ban не смог запуститься. Проверьте логи.${NC}"
    exit 1
fi
