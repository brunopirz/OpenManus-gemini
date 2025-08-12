#!/bin/bash

# Script de Monitoramento e Manutenção do OpenManus em Produção
# Para uso em VPS Ubuntu Server 24.x

set -e

# Configurações
OPENMANUS_HOME="/opt/openmanus"
SERVICE_NAME="openmanus"
LOG_DIR="/var/log/openmanus"
BACKUP_DIR="/backup/openmanus"
MAX_LOG_SIZE="100M"
MAX_BACKUP_DAYS=30
ALERT_EMAIL="admin@seudominio.com"  # Configure seu email

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DIR/monitor.log"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_DIR/monitor.log"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_DIR/monitor.log"
}

# Função para enviar alertas (requer configuração de email)
send_alert() {
    local subject="$1"
    local message="$2"
    
    # Usando mail (instale com: sudo apt install mailutils)
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "[OpenManus Alert] $subject" "$ALERT_EMAIL"
    fi
    
    # Log do alerta
    error "ALERT: $subject - $message"
}

# Função para verificar status do serviço
check_service_status() {
    log "Verificando status do serviço OpenManus..."
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        log "✓ Serviço OpenManus está rodando"
        return 0
    else
        error "✗ Serviço OpenManus não está rodando"
        send_alert "Serviço Parado" "O serviço OpenManus parou de funcionar em $(hostname)"
        return 1
    fi
}

# Função para verificar uso de recursos
check_system_resources() {
    log "Verificando uso de recursos do sistema..."
    
    # Verificar uso de CPU
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    cpu_usage_int=${cpu_usage%.*}
    
    if [ "$cpu_usage_int" -gt 80 ]; then
        warn "Alto uso de CPU: ${cpu_usage}%"
        send_alert "Alto Uso de CPU" "CPU em ${cpu_usage}% em $(hostname)"
    else
        log "✓ Uso de CPU: ${cpu_usage}%"
    fi
    
    # Verificar uso de memória
    memory_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    memory_usage_int=${memory_usage%.*}
    
    if [ "$memory_usage_int" -gt 85 ]; then
        warn "Alto uso de memória: ${memory_usage}%"
        send_alert "Alto Uso de Memória" "Memória em ${memory_usage}% em $(hostname)"
    else
        log "✓ Uso de memória: ${memory_usage}%"
    fi
    
    # Verificar espaço em disco
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
    
    if [ "$disk_usage" -gt 85 ]; then
        warn "Alto uso de disco: ${disk_usage}%"
        send_alert "Alto Uso de Disco" "Disco em ${disk_usage}% em $(hostname)"
    else
        log "✓ Uso de disco: ${disk_usage}%"
    fi
}

# Função para verificar logs de erro
check_error_logs() {
    log "Verificando logs de erro..."
    
    # Verificar erros recentes no systemd
    error_count=$(journalctl -u $SERVICE_NAME --since "1 hour ago" --no-pager | grep -i "error\|exception\|failed" | wc -l)
    
    if [ "$error_count" -gt 10 ]; then
        warn "Muitos erros detectados: $error_count erros na última hora"
        send_alert "Muitos Erros" "$error_count erros detectados na última hora em $(hostname)"
    else
        log "✓ Logs de erro: $error_count erros na última hora"
    fi
}

# Função para verificar conectividade da API
check_api_connectivity() {
    log "Verificando conectividade com APIs..."
    
    # Verificar Google Gemini API
    if curl -s --max-time 10 "https://generativelanguage.googleapis.com" >/dev/null; then
        log "✓ Conectividade com Google Gemini API"
    else
        warn "✗ Problemas de conectividade com Google Gemini API"
        send_alert "API Inacessível" "Google Gemini API inacessível de $(hostname)"
    fi
    
    # Verificar conectividade geral
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log "✓ Conectividade de rede"
    else
        error "✗ Problemas de conectividade de rede"
        send_alert "Rede Inacessível" "Problemas de rede em $(hostname)"
    fi
}

# Função para verificar espaço em disco específico
check_disk_space() {
    log "Verificando espaço em disco específico..."
    
    # Verificar diretório do OpenManus
    if [ -d "$OPENMANUS_HOME" ]; then
        openmanus_size=$(du -sh "$OPENMANUS_HOME" | cut -f1)
        log "✓ Tamanho do diretório OpenManus: $openmanus_size"
    fi
    
    # Verificar diretório de logs
    if [ -d "$LOG_DIR" ]; then
        log_size=$(du -sh "$LOG_DIR" | cut -f1)
        log "✓ Tamanho do diretório de logs: $log_size"
    fi
    
    # Verificar diretório de backup
    if [ -d "$BACKUP_DIR" ]; then
        backup_size=$(du -sh "$BACKUP_DIR" | cut -f1)
        log "✓ Tamanho do diretório de backup: $backup_size"
    fi
}

# Função para rotacionar logs
rotate_logs() {
    log "Rotacionando logs..."
    
    # Criar diretório de logs se não existir
    sudo mkdir -p "$LOG_DIR"
    
    # Rotacionar logs do systemd para arquivo
    journalctl -u $SERVICE_NAME --since "24 hours ago" > "$LOG_DIR/openmanus-$(date +%Y%m%d).log"
    
    # Comprimir logs antigos
    find "$LOG_DIR" -name "*.log" -mtime +1 -exec gzip {} \;
    
    # Remover logs muito antigos
    find "$LOG_DIR" -name "*.gz" -mtime +$MAX_BACKUP_DAYS -delete
    
    log "✓ Rotação de logs concluída"
}

# Função para fazer backup das configurações
backup_configs() {
    log "Fazendo backup das configurações..."
    
    # Criar diretório de backup
    sudo mkdir -p "$BACKUP_DIR"
    
    # Backup das configurações
    backup_file="$BACKUP_DIR/config-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    tar -czf "$backup_file" \
        "$OPENMANUS_HOME/OpenManus/config/" \
        "/etc/systemd/system/$SERVICE_NAME.service" \
        "/etc/nginx/sites-available/openmanus" 2>/dev/null || true
    
    if [ -f "$backup_file" ]; then
        log "✓ Backup criado: $backup_file"
    else
        warn "✗ Falha ao criar backup"
    fi
    
    # Remover backups antigos
    find "$BACKUP_DIR" -name "config-backup-*.tar.gz" -mtime +$MAX_BACKUP_DAYS -delete
}

# Função para verificar atualizações
check_updates() {
    log "Verificando atualizações..."
    
    cd "$OPENMANUS_HOME/OpenManus" || return 1
    
    # Verificar se há atualizações no repositório
    git fetch origin >/dev/null 2>&1
    
    local_commit=$(git rev-parse HEAD)
    remote_commit=$(git rev-parse origin/main)
    
    if [ "$local_commit" != "$remote_commit" ]; then
        warn "Atualizações disponíveis no repositório"
        log "Commit local: $local_commit"
        log "Commit remoto: $remote_commit"
    else
        log "✓ OpenManus está atualizado"
    fi
}

# Função para limpeza automática
cleanup_system() {
    log "Executando limpeza do sistema..."
    
    # Limpar cache do apt
    sudo apt autoremove -y >/dev/null 2>&1
    sudo apt autoclean >/dev/null 2>&1
    
    # Limpar logs antigos do journald
    sudo journalctl --vacuum-time=30d >/dev/null 2>&1
    
    # Limpar cache do Docker (se instalado)
    if command -v docker >/dev/null 2>&1; then
        docker system prune -f >/dev/null 2>&1 || true
    fi
    
    log "✓ Limpeza do sistema concluída"
}

# Função para gerar relatório de status
generate_status_report() {
    local report_file="$LOG_DIR/status-report-$(date +%Y%m%d).txt"
    
    {
        echo "=== RELATÓRIO DE STATUS DO OPENMANUS ==="
        echo "Data: $(date)"
        echo "Servidor: $(hostname)"
        echo ""
        
        echo "=== STATUS DOS SERVIÇOS ==="
        systemctl status $SERVICE_NAME --no-pager || true
        echo ""
        systemctl status nginx --no-pager || true
        echo ""
        
        echo "=== USO DE RECURSOS ==="
        echo "CPU:"
        top -bn1 | head -5
        echo ""
        echo "Memória:"
        free -h
        echo ""
        echo "Disco:"
        df -h
        echo ""
        
        echo "=== PROCESSOS DO OPENMANUS ==="
        ps aux | grep -E "(openmanus|python.*main.py)" | grep -v grep || true
        echo ""
        
        echo "=== LOGS RECENTES ==="
        journalctl -u $SERVICE_NAME --no-pager -n 20 || true
        
    } > "$report_file"
    
    log "✓ Relatório de status gerado: $report_file"
}

# Função para reiniciar serviço se necessário
restart_if_needed() {
    log "Verificando se reinicialização é necessária..."
    
    # Verificar se o serviço está respondendo
    if ! systemctl is-active --quiet $SERVICE_NAME; then
        warn "Serviço não está ativo, tentando reiniciar..."
        
        sudo systemctl restart $SERVICE_NAME
        sleep 10
        
        if systemctl is-active --quiet $SERVICE_NAME; then
            log "✓ Serviço reiniciado com sucesso"
            send_alert "Serviço Reiniciado" "OpenManus foi reiniciado automaticamente em $(hostname)"
        else
            error "✗ Falha ao reiniciar serviço"
            send_alert "Falha na Reinicialização" "Falha ao reiniciar OpenManus em $(hostname)"
        fi
    fi
}

# Função principal de monitoramento
run_monitoring() {
    log "Iniciando monitoramento do OpenManus..."
    log "================================================"
    
    # Criar diretórios necessários
    sudo mkdir -p "$LOG_DIR" "$BACKUP_DIR"
    
    # Executar verificações
    check_service_status
    check_system_resources
    check_error_logs
    check_api_connectivity
    check_disk_space
    
    # Manutenção (apenas se especificado)
    if [ "$1" = "--maintenance" ]; then
        log "Executando tarefas de manutenção..."
        rotate_logs
        backup_configs
        cleanup_system
        check_updates
    fi
    
    # Reiniciar se necessário
    if [ "$1" = "--auto-restart" ]; then
        restart_if_needed
    fi
    
    # Gerar relatório
    if [ "$1" = "--report" ]; then
        generate_status_report
    fi
    
    log "================================================"
    log "Monitoramento concluído"
}

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  --maintenance    Executar tarefas de manutenção (backup, limpeza, etc.)"
    echo "  --auto-restart   Reiniciar serviço automaticamente se necessário"
    echo "  --report         Gerar relatório detalhado de status"
    echo "  --help           Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0                    # Monitoramento básico"
    echo "  $0 --maintenance      # Monitoramento + manutenção"
    echo "  $0 --auto-restart     # Monitoramento + reinicialização automática"
    echo "  $0 --report           # Monitoramento + relatório detalhado"
    echo ""
    echo "Para uso em crontab:"
    echo "  # Monitoramento a cada 5 minutos"
    echo "  */5 * * * * /path/to/monitor-production.sh >/dev/null 2>&1"
    echo ""
    echo "  # Manutenção diária às 2h"
    echo "  0 2 * * * /path/to/monitor-production.sh --maintenance >/dev/null 2>&1"
}

# Verificar argumentos
case "$1" in
    --help)
        show_help
        exit 0
        ;;
    --maintenance|--auto-restart|--report|"")
        run_monitoring "$1"
        ;;
    *)
        echo "Opção inválida: $1"
        show_help
        exit 1
        ;;
esac