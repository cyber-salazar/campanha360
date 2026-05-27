#!/bin/bash
# ─────────────────────────────────────────────────────────────
# duckdns_update.sh — Atualiza o IP do DuckDNS automaticamente
#
# Configure como cron job:
#   crontab -e
#   */5 * * * * /home/ubuntu/campanha360/duckdns_update.sh > /dev/null 2>&1
#
# Preencha as variáveis abaixo antes de usar
# ─────────────────────────────────────────────────────────────

DUCKDNS_TOKEN="SEU_TOKEN_DUCKDNS"
DUCKDNS_DOMAIN="campanha360-sardelli"   # sem .duckdns.org

# Atualizar IP
curl -s "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=" \
     -o /tmp/duckdns.log

# Log com timestamp
echo "[$(date '+%Y-%m-%d %H:%M:%S')] DuckDNS atualizado: $(cat /tmp/duckdns.log)" \
     >> /home/ubuntu/campanha360/duckdns.log
