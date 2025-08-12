# Deploy do OpenManus em VPS Ubuntu Server 24.x

Este guia fornece instruções detalhadas para fazer o deploy do OpenManus em uma VPS com Ubuntu Server 24.x.

## Pré-requisitos

### Requisitos do Servidor
- **Sistema Operacional**: Ubuntu Server 24.04 LTS ou superior
- **RAM**: Mínimo 2GB, recomendado 4GB+
- **Storage**: Mínimo 20GB de espaço livre
- **CPU**: 2 cores ou mais
- **Rede**: Conexão estável com a internet

### Requisitos de Acesso
- Acesso SSH ao servidor
- Usuário com privilégios sudo
- Chave da API do Google Gemini ([obter aqui](https://makersuite.google.com/app/apikey))

## Instalação Automática

### Método 1: Script de Instalação (Recomendado)

1. **Conecte-se ao servidor via SSH**:
   ```bash
   ssh usuario@seu-servidor-ip
   ```

2. **Baixe e execute o script de instalação**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/brunopirz/OpenManus/main/scripts/install-ubuntu-vps.sh | bash
   ```

3. **Durante a instalação, você será solicitado a fornecer**:
   - Chave da API do Google Gemini
   - Confirmação para instalação de dependências

4. **Aguarde a conclusão da instalação** (aproximadamente 10-15 minutos)

### Método 2: Instalação Manual

Se preferir instalar manualmente, siga os passos abaixo:

#### 1. Atualizar Sistema
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Instalar Dependências
```bash
sudo apt install -y curl wget git unzip python3.12 python3.12-dev python3.12-venv python3-pip nginx ufw
```

#### 3. Instalar Docker
```bash
# Remover versões antigas
sudo apt remove -y docker docker-engine docker.io containerd runc

# Adicionar repositório oficial
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
```

#### 4. Instalar uv (Gerenciador de Pacotes Python)
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### 5. Clonar e Configurar OpenManus
```bash
# Criar usuário do sistema
sudo useradd -r -s /bin/bash -d /opt/openmanus -m openmanus
sudo usermod -aG docker openmanus

# Clonar repositório
sudo git clone https://github.com/brunopirz/OpenManus.git /opt/openmanus/OpenManus
sudo chown -R openmanus:openmanus /opt/openmanus

# Configurar ambiente Python
sudo -u openmanus bash -c "
    cd /opt/openmanus/OpenManus
    python3.12 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
"
```

#### 6. Configurar OpenManus
```bash
# Copiar arquivo de configuração (já vem com Google Gemini como padrão)
sudo -u openmanus cp /opt/openmanus/OpenManus/config/config.example.toml /opt/openmanus/OpenManus/config/config.toml
```

**Opção 1: Configurar API Key diretamente no config.toml**
```bash
# Editar configuração (substitua YOUR_GOOGLE_API_KEY pela sua chave)
sudo -u openmanus nano /opt/openmanus/OpenManus/config/config.toml
```

**Opção 2: Configurar API Key via arquivo .env (Recomendado)**
```bash
# Criar arquivo .env (mais seguro)
sudo -u openmanus tee /opt/openmanus/OpenManus/.env > /dev/null <<EOF
# Configurações de ambiente para OpenManus
GOOGLE_API_KEY=sua_chave_api_aqui
EOF

# Atualizar config.toml para usar variável de ambiente
sudo -u openmanus sed -i 's/api_key = "YOUR_GOOGLE_API_KEY"/api_key = "\${GOOGLE_API_KEY}"/g' /opt/openmanus/OpenManus/config/config.toml
```

#### 7. Criar Serviço Systemd
```bash
sudo tee /etc/systemd/system/openmanus.service > /dev/null <<EOF
[Unit]
Description=OpenManus AI Agent
After=network.target
Wants=network.target

[Service]
Type=simple
User=openmanus
Group=openmanus
WorkingDirectory=/opt/openmanus/OpenManus
Environment=PATH=/opt/openmanus/OpenManus/venv/bin
ExecStart=/opt/openmanus/OpenManus/venv/bin/python main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=openmanus

[Install]
WantedBy=multi-user.target
EOF

# Habilitar e iniciar serviço
sudo systemctl daemon-reload
sudo systemctl enable openmanus
sudo systemctl start openmanus
```

#### 8. Configurar Nginx (Opcional)
```bash
# Criar configuração do Nginx
sudo tee /etc/nginx/sites-available/openmanus > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Habilitar site
sudo ln -sf /etc/nginx/sites-available/openmanus /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```

#### 9. Configurar Firewall
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

## Configuração

### Arquivo de Configuração Principal

O arquivo de configuração está localizado em `/opt/openmanus/OpenManus/config/config.toml`.

#### Configuração Básica do Google Gemini
```toml
[llm]
model = "gemini-2.5-pro"
base_url = "https://generativelanguage.googleapis.com/v1beta/openai/"
api_key = "SUA_CHAVE_DA_API_GOOGLE"
max_tokens = 8192
temperature = 0.0

[llm.vision]
model = "gemini-2.5-pro"
base_url = "https://generativelanguage.googleapis.com/v1beta/openai/"
api_key = "SUA_CHAVE_DA_API_GOOGLE"
max_tokens = 8192
temperature = 0.0
```

#### Configurações Opcionais

**Sandbox (para execução segura de código)**:
```toml
[sandbox]
use_sandbox = true
image = "python:3.12-slim"
work_dir = "/workspace"
memory_limit = "1g"
cpu_limit = 2.0
timeout = 300
network_enabled = true
```

**Browser (para automação web)**:
```toml
[browser]
headless = true
disable_security = true
```

**Busca na Web**:
```toml
[search]
engine = "Google"
fallback_engines = ["DuckDuckGo", "Baidu", "Bing"]
lang = "pt"
country = "br"
```

## Gerenciamento do Serviço

### Comandos Básicos

```bash
# Ver status do serviço
sudo systemctl status openmanus

# Iniciar serviço
sudo systemctl start openmanus

# Parar serviço
sudo systemctl stop openmanus

# Reiniciar serviço
sudo systemctl restart openmanus

# Ver logs
sudo journalctl -u openmanus -f

# Ver logs das últimas 100 linhas
sudo journalctl -u openmanus -n 100
```

### Scripts de Gerenciamento (se instalado via script automático)

```bash
# Ver status completo
openmanus-status

# Reiniciar todos os serviços
openmanus-restart

# Ver logs em tempo real
openmanus-logs

# Atualizar OpenManus
openmanus-update
```

## Monitoramento

### Verificar se está funcionando

1. **Verificar status do serviço**:
   ```bash
   sudo systemctl status openmanus
   ```

2. **Verificar logs**:
   ```bash
   sudo journalctl -u openmanus --no-pager -n 20
   ```

3. **Testar conexão** (se Nginx estiver configurado):
   ```bash
   curl -I http://localhost
   ```

### Logs Importantes

- **Logs do OpenManus**: `sudo journalctl -u openmanus`
- **Logs do Nginx**: `/var/log/nginx/access.log` e `/var/log/nginx/error.log`
- **Logs do sistema**: `/var/log/syslog`

## Solução de Problemas

### Problemas Comuns

#### 1. Serviço não inicia
```bash
# Verificar logs de erro
sudo journalctl -u openmanus --no-pager -n 50

# Verificar configuração
sudo -u openmanus /opt/openmanus/OpenManus/venv/bin/python -c "from app.config import config; print('Config OK')"
```

#### 2. Erro de API Key
```bash
# Verificar se a chave está configurada corretamente
sudo -u openmanus grep -r "YOUR_GOOGLE_API_KEY" /opt/openmanus/OpenManus/config/
```

#### 3. Problemas de permissão
```bash
# Corrigir permissões
sudo chown -R openmanus:openmanus /opt/openmanus
sudo chmod +x /opt/openmanus/OpenManus/main.py
```

#### 4. Problemas de rede
```bash
# Verificar se as portas estão abertas
sudo netstat -tuln | grep -E ':(80|443|8000)'

# Verificar firewall
sudo ufw status
```

### Logs de Debug

Para ativar logs mais detalhados, edite o arquivo de configuração:

```toml
# Adicionar ao config.toml
[logging]
level = "DEBUG"
```

## Segurança

### Recomendações de Segurança

1. **Usar HTTPS em produção**:
   ```bash
   # Instalar Certbot para SSL gratuito
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d seu-dominio.com
   ```

2. **Configurar backup automático**:
   ```bash
   # Criar script de backup
   sudo tee /usr/local/bin/backup-openmanus > /dev/null <<'EOF'
   #!/bin/bash
   tar -czf /backup/openmanus-$(date +%Y%m%d).tar.gz /opt/openmanus/OpenManus/config/
   EOF
   
   sudo chmod +x /usr/local/bin/backup-openmanus
   
   # Adicionar ao crontab
   echo "0 2 * * * /usr/local/bin/backup-openmanus" | sudo crontab -
   ```

3. **Limitar acesso SSH**:
   ```bash
   # Editar configuração SSH
   sudo nano /etc/ssh/sshd_config
   
   # Adicionar:
   # PermitRootLogin no
   # PasswordAuthentication no
   # AllowUsers seu-usuario
   
   sudo systemctl restart ssh
   ```

4. **Configurar fail2ban**:
   ```bash
   sudo apt install fail2ban
   sudo systemctl enable fail2ban
   sudo systemctl start fail2ban
   ```

## Atualizações

### Atualizar OpenManus

```bash
# Parar serviço
sudo systemctl stop openmanus

# Atualizar código
cd /opt/openmanus/OpenManus
sudo -u openmanus git pull

# Atualizar dependências
sudo -u openmanus bash -c "source venv/bin/activate && pip install -r requirements.txt"

# Reiniciar serviço
sudo systemctl start openmanus
```

### Atualizar Sistema

```bash
# Atualizar pacotes do sistema
sudo apt update && sudo apt upgrade -y

# Reiniciar se necessário
sudo reboot
```

## Performance

### Otimizações

1. **Configurar swap** (se RAM < 4GB):
   ```bash
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

2. **Configurar limites de recursos**:
   ```bash
   # Editar /etc/systemd/system/openmanus.service
   # Adicionar na seção [Service]:
   # LimitNOFILE=65536
   # LimitNPROC=4096
   ```

3. **Configurar cache do Nginx**:
   ```nginx
   # Adicionar ao bloco server do Nginx
   location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
       expires 1y;
       add_header Cache-Control "public, immutable";
   }
   ```

## Suporte

Para suporte adicional:

- **Documentação oficial**: [GitHub OpenManus](https://github.com/brunopirz/OpenManus)
- **Issues**: [GitHub Issues](https://github.com/brunopirz/OpenManus/issues)
- **Discord**: [Comunidade OpenManus](https://discord.gg/DYn29wFk9z)

## Conclusão

Após seguir este guia, você terá o OpenManus rodando em sua VPS Ubuntu com:

- ✅ Google Gemini configurado como LLM padrão
- ✅ Serviço systemd para gerenciamento automático
- ✅ Nginx como proxy reverso (opcional)
- ✅ Firewall configurado
- ✅ Scripts de gerenciamento
- ✅ Logs estruturados
- ✅ Configurações de segurança básicas

O OpenManus estará acessível via HTTP na porta 80 (se Nginx estiver configurado) ou diretamente na porta 8000.