# 🚀 Campanha360 — Guia de Instalação Completo
## n8n + Caddy + PostgreSQL na Oracle Cloud Free Tier

> **Custo total: R$ 0/mês** · Tempo estimado: 2–3 horas

---

## 📋 O que você vai ter no final

- n8n rodando 24/7 em `https://seu-dominio.duckdns.org`
- HTTPS automático e gratuito via Let's Encrypt
- Banco de dados PostgreSQL persistente
- Pronto para receber webhooks da Meta e acionar Claude Haiku

---

## PRÉ-REQUISITOS

- Conta Oracle Cloud (gratuita): [cloud.oracle.com](https://cloud.oracle.com)
- Conta DuckDNS (gratuita): [duckdns.org](https://duckdns.org)
- Os arquivos desta pasta:
  - `docker-compose.yml`
  - `Caddyfile`
  - `.env.example` → você vai renomear para `.env`
  - `install.sh`

---

## ETAPA 1 — Criar a VM na Oracle Cloud

### 1.1 Criar instância

1. Acesse [cloud.oracle.com](https://cloud.oracle.com) e faça login
2. No menu: **Compute → Instances → Create Instance**
3. Configure:

| Campo | Valor |
|-------|-------|
| Name | `campanha360-server` |
| Image | `Ubuntu 22.04 (aarch64)` |
| Shape | `VM.Standard.A1.Flex` (Always Free) |
| OCPUs | `4` |
| Memory | `24 GB` |
| Boot Volume | `50 GB` |

4. Em **Add SSH Keys**: cole sua chave pública SSH
   - Se não tiver, gere uma: `ssh-keygen -t ed25519 -C "campanha360"`
   - Cole o conteúdo de `~/.ssh/id_ed25519.pub`

5. Clique **Create** e aguarde ~2 minutos

### 1.2 Abrir portas no Security List

Sem isso, o HTTPS não funciona.

1. No menu da instância: **Subnet → Security List → Ingress Rules**
2. Adicione duas regras:

| Source CIDR | IP Protocol | Dest. Port |
|-------------|-------------|------------|
| 0.0.0.0/0 | TCP | 80 |
| 0.0.0.0/0 | TCP | 443 |

3. Salve. **Anote o IP público da VM.**

---

## ETAPA 2 — Configurar domínio gratuito (DuckDNS)

1. Acesse [duckdns.org](https://duckdns.org) e faça login com Google/GitHub
2. Crie um subdomínio (ex: `campanha360-sardelli`)
3. No campo **current ip**, cole o IP público da sua VM Oracle
4. Clique **update ip**
5. Seu domínio será: `campanha360-sardelli.duckdns.org`

> Guarde este domínio — você vai usar em todos os próximos passos.

---

## ETAPA 3 — Acessar a VM e instalar

```bash
# Conectar via SSH (substitua pelo IP da sua VM)
ssh ubuntu@SEU_IP_ORACLE

# Baixar e executar o script de instalação
curl -O https://raw.githubusercontent.com/seu-usuario/campanha360/main/install.sh
chmod +x install.sh
./install.sh

# Fazer logout e login novamente (para aplicar permissões Docker)
exit
ssh ubuntu@SEU_IP_ORACLE
```

---

## ETAPA 4 — Configurar os arquivos

```bash
# Entrar na pasta do projeto
cd ~/campanha360

# Copiar os arquivos (via scp ou colar o conteúdo manualmente)
# Exemplo com scp (rodar no seu computador local):
# scp docker-compose.yml Caddyfile .env.example ubuntu@SEU_IP:/home/ubuntu/campanha360/
```

### 4.1 Editar o Caddyfile

```bash
nano Caddyfile
```

Substitua:
- `SEU_DOMINIO.duckdns.org` → `campanha360-sardelli.duckdns.org` (seu subdomínio real)
- `seu@email.com.br` → seu e-mail real (para alertas do Let's Encrypt)

Salve: `Ctrl+X → Y → Enter`

### 4.2 Criar e preencher o .env

```bash
# Copiar o exemplo
cp .env.example .env

# Editar
nano .env
```

Preencha **todas** as variáveis:

```bash
# Gerar senhas fortes (rode cada linha e copie o resultado)
openssl rand -base64 32   # → use como POSTGRES_PASSWORD
openssl rand -base64 24   # → use como N8N_BASIC_AUTH_PASSWORD
```

Salve o arquivo.

---

## ETAPA 5 — Subir os containers

```bash
cd ~/campanha360

# Subir tudo em background
docker compose up -d

# Acompanhar os logs (aguarde ~60 segundos na primeira vez)
docker compose logs -f

# Quando aparecer "Editor is now accessible", pressione Ctrl+C
```

### Verificar se está rodando

```bash
docker compose ps
```

Esperado:
```
NAME                    STATUS
campanha360_caddy       Up
campanha360_n8n         Up
campanha360_postgres    Up (healthy)
```

---

## ETAPA 6 — Acessar o n8n

Abra no navegador:
```
https://campanha360-sardelli.duckdns.org
```

Login:
- **Usuário**: o valor de `N8N_BASIC_AUTH_USER` do seu `.env`
- **Senha**: o valor de `N8N_BASIC_AUTH_PASSWORD`

> Na primeira vez, o Caddy vai solicitar o certificado HTTPS ao Let's Encrypt.
> Aguarde ~30 segundos até o cadeado aparecer no navegador.

---

## ETAPA 7 — Configurar credenciais no n8n

No painel do n8n, vá em **Settings → Credentials** e adicione:

### 7.1 Meta (WhatsApp Cloud API)

1. **New Credential → WhatsApp Business Cloud**
2. Preencha:
   - **Phone Number ID**: valor de `META_PHONE_NUMBER_ID` do `.env`
   - **Access Token**: valor de `META_ACCESS_TOKEN` do `.env`

### 7.2 Anthropic (Claude Haiku)

1. **New Credential → Anthropic**
2. Preencha:
   - **API Key**: valor de `ANTHROPIC_API_KEY` do `.env`

### 7.3 Google Sheets (CRM)

1. **New Credential → Google Sheets OAuth2**
2. Siga o fluxo de autenticação Google

---

## ETAPA 8 — Configurar o Webhook da Meta

Agora o n8n precisa receber mensagens do WhatsApp.

### 8.1 URL do webhook

No n8n, crie um nó **WhatsApp Trigger**. A URL gerada será:
```
https://campanha360-sardelli.duckdns.org/webhook/whatsapp
```

### 8.2 Registrar no Meta

Em [developers.facebook.com](https://developers.facebook.com):
1. Seu App → **WhatsApp → Configuration**
2. Em **Webhook**, clique **Edit**
3. Preencha:
   - **Callback URL**: `https://campanha360-sardelli.duckdns.org/webhook/whatsapp`
   - **Verify Token**: valor de `META_VERIFY_TOKEN` do seu `.env`
4. Clique **Verify and Save**
5. Em **Webhook Fields**, habilite: `messages`

---

## COMANDOS ÚTEIS DO DIA A DIA

```bash
# Ver status dos containers
docker compose ps

# Ver logs em tempo real
docker compose logs -f n8n

# Reiniciar após mudanças
docker compose restart n8n

# Atualizar n8n para versão mais recente
docker compose pull n8n
docker compose up -d n8n

# Backup do banco de dados
docker exec campanha360_postgres pg_dump -U n8n n8n > backup_$(date +%Y%m%d).sql

# Espaço em disco
df -h
docker system df
```

---

## SOLUÇÃO DE PROBLEMAS

### HTTPS não funciona (sem cadeado)

```bash
# Ver logs do Caddy
docker compose logs caddy

# Causa mais comum: portas 80/443 não abertas no Security List Oracle
# Verifique também se o DuckDNS aponta para o IP correto
curl -s ifconfig.me  # IP da VM
# Compare com o IP no DuckDNS
```

### n8n não inicia

```bash
docker compose logs n8n
# Causa mais comum: .env com variáveis vazias ou incorretas
```

### Webhook da Meta não chega

```bash
# Testar se o webhook responde
curl -X GET "https://SEU_DOMINIO.duckdns.org/webhook/whatsapp?hub.mode=subscribe&hub.verify_token=SEU_VERIFY_TOKEN&hub.challenge=TESTE"
# Deve retornar: TESTE
```

---

## PRÓXIMO PASSO

Com o servidor no ar, o próximo passo é importar o workflow do funil no n8n:

1. No n8n: **Workflows → Import from File**
2. Importe o arquivo `workflow_funil.json` (próximo entregável)
3. Configure as credenciais em cada nó
4. Ative o workflow

---

## ESTRUTURA FINAL DOS ARQUIVOS

```
~/campanha360/
├── docker-compose.yml    ← orquestra os containers
├── Caddyfile             ← configuração do proxy HTTPS
├── .env                  ← variáveis secretas (nunca commitar)
├── .env.example          ← template sem segredos
├── .gitignore
└── install.sh            ← script de instalação
```

---

*Campanha360 · Infraestrutura Módulo 1 · Mai/2026*
