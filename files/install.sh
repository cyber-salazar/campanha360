#!/bin/bash
# ─────────────────────────────────────────────────────────────
# install.sh — Campanha360
# Script de instalação para Oracle Cloud Free Tier
# Ubuntu 22.04 LTS (ARM ou x86)
#
# Como usar:
#   chmod +x install.sh
#   ./install.sh
# ─────────────────────────────────────────────────────────────

set -e  # Para em qualquer erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════╗"
echo "║     Campanha360 — Setup do Servidor   ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# ── 1. ATUALIZAR SISTEMA ──────────────────────────────────────
echo -e "${YELLOW}[1/7] Atualizando sistema...${NC}"
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
echo -e "${GREEN}✓ Sistema atualizado${NC}"

# ── 2. INSTALAR DEPENDÊNCIAS ──────────────────────────────────
echo -e "${YELLOW}[2/7] Instalando dependências...${NC}"
sudo apt-get install -y -qq \
    curl \
    wget \
    git \
    unzip \
    htop \
    ufw \
    fail2ban
echo -e "${GREEN}✓ Dependências instaladas${NC}"

# ── 3. INSTALAR DOCKER ────────────────────────────────────────
echo -e "${YELLOW}[3/7] Instalando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✓ Docker instalado${NC}"
else
    echo -e "${GREEN}✓ Docker já instalado${NC}"
fi

# Docker Compose (plugin)
if ! docker compose version &> /dev/null; then
    sudo apt-get install -y -qq docker-compose-plugin
fi
echo -e "${GREEN}✓ Docker Compose disponível: $(docker compose version --short)${NC}"

# ── 4. CONFIGURAR FIREWALL ────────────────────────────────────
echo -e "${YELLOW}[4/7] Configurando firewall...${NC}"
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh        # porta 22
sudo ufw allow 80/tcp     # HTTP (redireciona para HTTPS via Caddy)
sudo ufw allow 443/tcp    # HTTPS
sudo ufw --force enable
echo -e "${GREEN}✓ Firewall configurado (SSH + 80 + 443)${NC}"

# ATENÇÃO: Na Oracle Cloud também é necessário abrir as portas
# no Security List da VCN (não só no UFW do sistema)
echo -e "${YELLOW}⚠  LEMBRE-SE: Abra as portas 80 e 443 no Security List${NC}"
echo -e "${YELLOW}   da Oracle Cloud (VCN → Security Lists → Ingress Rules)${NC}"

# ── 5. CONFIGURAR FAIL2BAN ────────────────────────────────────
echo -e "${YELLOW}[5/7] Configurando Fail2ban...${NC}"
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
echo -e "${GREEN}✓ Fail2ban ativo (proteção contra brute force)${NC}"

# ── 6. CRIAR ESTRUTURA DE PASTAS ─────────────────────────────
echo -e "${YELLOW}[6/7] Criando estrutura do projeto...${NC}"
mkdir -p ~/campanha360
cd ~/campanha360

# Criar .gitignore
cat > .gitignore << 'EOF'
.env
*.log
caddy_data/
caddy_config/
postgres_data/
n8n_data/
EOF

echo -e "${GREEN}✓ Estrutura criada em ~/campanha360${NC}"

# ── 7. VERIFICAR PRÉ-REQUISITOS ───────────────────────────────
echo -e "${YELLOW}[7/7] Verificando pré-requisitos...${NC}"
echo ""
echo -e "${BLUE}Checklist final antes de subir os containers:${NC}"
echo ""
echo "  1. Copie os arquivos para ~/campanha360:"
echo "     • docker-compose.yml"
echo "     • Caddyfile"
echo "     • .env (criado a partir do .env.example)"
echo ""
echo "  2. No arquivo Caddyfile, substitua:"
echo "     SEU_DOMINIO.duckdns.org → seu domínio real"
echo "     seu@email.com.br → seu e-mail real"
echo ""
echo "  3. No arquivo .env, preencha TODAS as variáveis"
echo ""
echo "  4. Configure o DuckDNS:"
echo "     • Acesse: duckdns.org"
echo "     • Crie um subdomínio apontando para o IP desta VM"
echo "     • IP desta VM: $(curl -s ifconfig.me)"
echo ""
echo "  5. Na Oracle Cloud, abra as portas no Security List:"
echo "     • Destination Port Range: 80, Protocol: TCP"
echo "     • Destination Port Range: 443, Protocol: TCP"
echo "     • Source CIDR: 0.0.0.0/0"
echo ""
echo -e "${YELLOW}Quando tudo estiver pronto, execute:${NC}"
echo ""
echo "  cd ~/campanha360"
echo "  docker compose up -d"
echo "  docker compose logs -f    # acompanhar logs"
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Instalação base concluída com sucesso!   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠  IMPORTANTE: Faça logout e login novamente${NC}"
echo -e "${YELLOW}   para que as permissões do Docker sejam aplicadas.${NC}"
