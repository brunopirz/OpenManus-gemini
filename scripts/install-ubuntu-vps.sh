#!/bin/bash

# Script de Instalação Automática do OpenManus para Ubuntu Server 24.x
# Autor: Análise do Projeto OpenManus
# Data: $(date +%Y-%m-%d)

set -e  # Parar execução em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Verificar se está rodando como root
if [[ $EUID -eq 0 ]]; then
   error "Este script não deve ser executado como root. Use um usuário com sudo."
fi

# Verificar versão do Ubuntu
log "Verificando versão do Ubuntu..."
if ! grep -q "Ubuntu 24" /etc/os-release; then
    warn "Este script foi testado apenas no Ubuntu 24.x. Continuando mesmo assim..."
fi

# Configurações
OPENMANUS_USER="openmanus"
OPENMANUS_HOME="/opt/openmanus"
SERVICE_NAME="openmanus"
PORT="8000"

# Função para instalar dependências do sistema
install_system_dependencies() {
    log "Atualizando sistema e instalando dependências..."
    
    sudo apt update
    sudo apt upgrade -y
    
    # Instalar dependências básicas
    sudo apt install -y \
        curl \
        wget \
        git \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        build-essential \
        python3 \
        python3-dev \
        python3-venv \
        python3-pip \
        python3-full \
        python-is-python3 \
        nginx \
        ufw \
        htop \
        tree
    
    # Verificar se Python 3 foi instalado corretamente
    if ! command -v python3 &> /dev/null; then
        error "Python 3 não foi instalado corretamente"
    fi
    
    log "Python $(python3 --version) instalado com sucesso"
    
    log "Dependências do sistema instaladas com sucesso!"
}

# Função para instalar Docker
install_docker() {
    log "Instalando Docker..."
    
    # Remover versões antigas
    sudo apt remove -y docker docker-engine docker.io containerd runc || true
    
    # Adicionar repositório oficial do Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Adicionar usuário ao grupo docker
    sudo usermod -aG docker $USER
    
    # Habilitar Docker para iniciar automaticamente
    sudo systemctl enable docker
    sudo systemctl start docker
    
    log "Docker instalado com sucesso!"
}

# Função para instalar uv (gerenciador de pacotes Python) - OPCIONAL
install_uv() {
    log "Instalando uv (gerenciador de pacotes Python)..."
    
    # Tentar instalar uv, mas não falhar se não conseguir
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        # Adicionar uv ao PATH
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/.cargo/bin:$PATH"
        log "uv instalado com sucesso!"
        return 0
    else
        warn "Falha ao instalar uv. Continuando com pip padrão..."
        return 1
    fi
}

# Função para criar usuário do sistema
create_system_user() {
    log "Criando usuário do sistema para OpenManus..."
    
    # Criar usuário do sistema se não existir
    if ! id "$OPENMANUS_USER" &>/dev/null; then
        sudo useradd -r -s /bin/bash -d $OPENMANUS_HOME -m $OPENMANUS_USER
        log "Usuário $OPENMANUS_USER criado com sucesso!"
    else
        log "Usuário $OPENMANUS_USER já existe."
    fi
    
    # Adicionar usuário ao grupo docker
    sudo usermod -aG docker $OPENMANUS_USER
}

# Função para clonar e configurar OpenManus
setup_openmanus() {
    log "Configurando OpenManus..."
    
    # Criar diretório se não existir
    sudo mkdir -p $OPENMANUS_HOME
    
    # Clonar repositório
    if [ ! -d "$OPENMANUS_HOME/OpenManus" ]; then
        sudo git clone https://github.com/brunopirz/OpenManus-gemini.git $OPENMANUS_HOME/OpenManus
    else
        log "Repositório já existe. Atualizando..."
        cd $OPENMANUS_HOME/OpenManus
        sudo git pull
    fi
    
    # Alterar proprietário
    sudo chown -R $OPENMANUS_USER:$OPENMANUS_USER $OPENMANUS_HOME
    
    # Configurar ambiente Python
    log "Configurando ambiente virtual Python..."
    sudo -u $OPENMANUS_USER bash -c "
        cd $OPENMANUS_HOME/OpenManus
        
        # Remover ambiente virtual existente se houver
        if [ -d 'venv' ]; then
            rm -rf venv
        fi
        
        # Criar novo ambiente virtual
        python3 -m venv venv
        
        # Verificar se o ambiente virtual foi criado
        if [ ! -f 'venv/bin/activate' ]; then
            echo 'Erro: Falha ao criar ambiente virtual'
            exit 1
        fi
        
        # Ativar ambiente virtual
        source venv/bin/activate
        
        # Verificar se a ativação funcionou
        if [ -z \"\$VIRTUAL_ENV\" ]; then
            echo 'Erro: Falha ao ativar ambiente virtual'
            exit 1
        fi
        
        echo 'Ambiente virtual ativado: '\$VIRTUAL_ENV
        
        # Atualizar pip
        python -m pip install --upgrade pip
        
        # Instalar dependências
        pip install -r requirements.txt
        
        echo 'Dependências instaladas com sucesso!'
    "
    
    log "OpenManus configurado com sucesso!"
}

# Função para configurar arquivo de configuração
setup_config() {
    log "Configurando arquivo de configuração..."
    
    CONFIG_FILE="$OPENMANUS_HOME/OpenManus/config/config.toml"
    ENV_FILE="$OPENMANUS_HOME/OpenManus/.env"
    
    # Copiar arquivo de exemplo se não existir (usando config.example.toml que já tem Gemini como padrão)
    if [ ! -f "$CONFIG_FILE" ]; then
        sudo -u $OPENMANUS_USER cp "$OPENMANUS_HOME/OpenManus/config/config.example.toml" "$CONFIG_FILE"
        log "Arquivo de configuração criado com base no exemplo (Gemini como padrão)!"
    else
        log "Arquivo de configuração já existe."
    fi
    
    # Configurar API Key
    echo -e "${BLUE}Configuração da API Key do Google Gemini:${NC}"
    echo "Você pode configurar a API key de duas formas:"
    echo "1. Diretamente no arquivo de configuração (config.toml)"
    echo "2. Via arquivo .env (recomendado para segurança)"
    echo ""
    read -p "Escolha a opção (1 ou 2) [2]: " CONFIG_OPTION
    CONFIG_OPTION=${CONFIG_OPTION:-2}
    
    read -p "Digite sua API Key do Google Gemini: " GOOGLE_API_KEY
    
    if [ ! -z "$GOOGLE_API_KEY" ]; then
        if [ "$CONFIG_OPTION" = "1" ]; then
            # Configurar diretamente no config.toml
            sudo -u $OPENMANUS_USER sed -i "s/YOUR_GOOGLE_API_KEY/$GOOGLE_API_KEY/g" "$CONFIG_FILE"
            log "Chave da API configurada no arquivo config.toml!"
        else
            # Configurar via .env
            sudo -u $OPENMANUS_USER tee "$ENV_FILE" > /dev/null <<EOF
# Configurações de ambiente para OpenManus
GOOGLE_API_KEY=$GOOGLE_API_KEY
EOF
            # Atualizar config.toml para usar variável de ambiente
            sudo -u $OPENMANUS_USER sed -i 's/api_key = "YOUR_GOOGLE_API_KEY"/api_key = "\${GOOGLE_API_KEY}"/g' "$CONFIG_FILE"
            log "Chave da API configurada no arquivo .env (mais seguro)!"
        fi
    else
        warn "Chave da API não fornecida. Você precisará configurar manualmente."
        echo "Para configurar depois:"
        echo "- Edite $CONFIG_FILE e substitua YOUR_GOOGLE_API_KEY pela sua chave"
        echo "- Ou crie $ENV_FILE com GOOGLE_API_KEY=sua_chave_aqui"
    fi
}

# Função para criar serviço systemd
create_systemd_service() {
    log "Criando serviço systemd..."
    
    sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=OpenManus AI Agent
After=network.target
Wants=network.target

[Service]
Type=simple
User=$OPENMANUS_USER
Group=$OPENMANUS_USER
WorkingDirectory=$OPENMANUS_HOME/OpenManus
Environment=PATH=$OPENMANUS_HOME/OpenManus/venv/bin
ExecStart=$OPENMANUS_HOME/OpenManus/venv/bin/python main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

# Limites de recursos
LimitNOFILE=65536
LimitNPROC=4096

# Variáveis de ambiente
Environment=PYTHONPATH=$OPENMANUS_HOME/OpenManus
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF
    
    # Recarregar systemd e habilitar serviço
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
    
    log "Serviço systemd criado e habilitado!"
}

# Função para configurar Nginx
setup_nginx() {
    log "Configurando Nginx..."
    
    # Criar configuração do site
    sudo tee /etc/nginx/sites-available/openmanus > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    
    # Logs
    access_log /var/log/nginx/openmanus_access.log;
    error_log /var/log/nginx/openmanus_error.log;
    
    # Proxy para OpenManus
    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF
    
    # Habilitar site
    sudo ln -sf /etc/nginx/sites-available/openmanus /etc/nginx/sites-enabled/
    
    # Remover site padrão
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Testar configuração
    sudo nginx -t
    
    # Reiniciar Nginx
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    
    log "Nginx configurado com sucesso!"
}

# Função para configurar firewall
setup_firewall() {
    log "Configurando firewall..."
    
    # Resetar UFW
    sudo ufw --force reset
    
    # Configurações básicas
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Permitir SSH
    sudo ufw allow ssh
    
    # Permitir HTTP e HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Habilitar firewall
    sudo ufw --force enable
    
    log "Firewall configurado com sucesso!"
}

# Função para criar scripts de gerenciamento
create_management_scripts() {
    log "Criando scripts de gerenciamento..."
    
    # Script de status
    sudo tee /usr/local/bin/openmanus-status > /dev/null <<'EOF'
#!/bin/bash
echo "=== Status do OpenManus ==="
sudo systemctl status openmanus --no-pager
echo ""
echo "=== Status do Nginx ==="
sudo systemctl status nginx --no-pager
echo ""
echo "=== Logs recentes ==="
sudo journalctl -u openmanus --no-pager -n 10
EOF
    
    # Script de restart
    sudo tee /usr/local/bin/openmanus-restart > /dev/null <<'EOF'
#!/bin/bash
echo "Reiniciando OpenManus..."
sudo systemctl restart openmanus
echo "Reiniciando Nginx..."
sudo systemctl restart nginx
echo "Serviços reiniciados!"
EOF
    
    # Script de logs
    sudo tee /usr/local/bin/openmanus-logs > /dev/null <<'EOF'
#!/bin/bash
sudo journalctl -u openmanus -f
EOF
    
    # Script de update
    sudo tee /usr/local/bin/openmanus-update > /dev/null <<'EOF'
#!/bin/bash
echo "Atualizando OpenManus..."
sudo systemctl stop openmanus
cd /opt/openmanus/OpenManus
sudo -u openmanus git pull
sudo -u openmanus bash -c "source venv/bin/activate && pip install -r requirements.txt"
sudo systemctl start openmanus
echo "OpenManus atualizado!"
EOF
    
    # Tornar scripts executáveis
    sudo chmod +x /usr/local/bin/openmanus-*
    
    log "Scripts de gerenciamento criados!"
}

# Função para verificar instalação
verify_installation() {
    log "Verificando instalação..."
    
    # Verificar se serviços estão rodando
    if sudo systemctl is-active --quiet openmanus; then
        log "✓ Serviço OpenManus está rodando"
    else
        warn "✗ Serviço OpenManus não está rodando"
    fi
    
    if sudo systemctl is-active --quiet nginx; then
        log "✓ Nginx está rodando"
    else
        warn "✗ Nginx não está rodando"
    fi
    
    # Verificar se porta está aberta
    if netstat -tuln | grep -q ":80 "; then
        log "✓ Porta 80 está aberta"
    else
        warn "✗ Porta 80 não está aberta"
    fi
    
    log "Verificação concluída!"
}

# Função principal
main() {
    log "Iniciando instalação do OpenManus no Ubuntu Server 24.x"
    log "================================================="
    
    # Verificar se tem acesso sudo
    if ! sudo -n true 2>/dev/null; then
        error "Este script requer acesso sudo. Execute: sudo -v"
    fi
    
    # Executar instalação
    install_system_dependencies
    install_docker
    
    # Tentar instalar uv, mas continuar se falhar
    if ! install_uv; then
        warn "uv não foi instalado, mas continuando com pip padrão..."
    fi
    
    create_system_user
    setup_openmanus
    setup_config
    create_systemd_service
    setup_nginx
    setup_firewall
    create_management_scripts
    
    # Iniciar serviços
    log "Iniciando serviços..."
    sudo systemctl start $SERVICE_NAME
    
    # Verificar instalação
    sleep 5
    verify_installation
    
    log "================================================="
    log "Instalação concluída com sucesso!"
    log ""
    log "Comandos úteis:"
    log "  openmanus-status   - Ver status dos serviços"
    log "  openmanus-restart  - Reiniciar serviços"
    log "  openmanus-logs     - Ver logs em tempo real"
    log "  openmanus-update   - Atualizar OpenManus"
    log ""
    log "Configuração:"
    log "  Arquivo de config: $OPENMANUS_HOME/OpenManus/config/config.toml"
    log "  Logs do sistema: sudo journalctl -u openmanus"
    log "  Logs do Nginx: /var/log/nginx/openmanus_*.log"
    log ""
    log "Acesso:"
    log "  HTTP: http://$(curl -s ifconfig.me || echo 'SEU_IP')"
    log ""
    warn "IMPORTANTE: Configure sua chave da API do Google em $CONFIG_FILE"
    warn "IMPORTANTE: Reinicie a sessão ou execute 'newgrp docker' para usar Docker"
}

# Executar função principal
main "$@"