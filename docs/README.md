# OpenManus - Documentação Completa

## Visão Geral

Este diretório contém toda a documentação do projeto OpenManus, incluindo análises técnicas, guias de deploy e scripts de automação para VPS Ubuntu Server 24.x.

## Arquivos de Documentação

### 📊 Análise do Projeto
- **[relatorio-analise-projeto.md](./relatorio-analise-projeto.md)** - Análise técnica detalhada do projeto OpenManus, incluindo arquitetura, componentes, dependências e recomendações de melhorias.

### 🚀 Deploy e Configuração
- **[deploy-vps-ubuntu.md](./deploy-vps-ubuntu.md)** - Guia completo para deploy do OpenManus em VPS Ubuntu Server 24.x, incluindo instalação automática e manual.
- **[configuracao-api-keys.md](./configuracao-api-keys.md)** - Guia detalhado para configuração segura de chaves de API (Google Gemini, OpenAI, Anthropic, etc.).
- **[changelog-configuracoes.md](./changelog-configuracoes.md)** - Registro detalhado de todas as alterações realizadas no projeto.

### ⚙️ Configurações
- **[config.production-vps.toml](../config.production-vps.toml)** - Arquivo de configuração otimizado para ambiente de produção em VPS, com Google Gemini como LLM padrão.

### 🔧 Scripts de Automação
- **[install-ubuntu-vps.sh](../scripts/install-ubuntu-vps.sh)** - Script de instalação automática para VPS Ubuntu 24.x
- **[monitor-production.sh](../scripts/monitor-production.sh)** - Script de monitoramento e manutenção para ambiente de produção

## Principais Alterações Realizadas

### ✅ Configuração do Google Gemini como Padrão
- Modificado `config.example.toml` para usar Google Gemini como LLM principal
- Configurado `gemini-2.5-pro` como modelo padrão
- Configurado `gemini-2.5-pro` como modelo de visão padrão
- Mantidas opções alternativas (OpenAI, Anthropic) comentadas
- **Suporte a múltiplas formas de configuração de API keys** (arquivo .env, config.toml, variáveis de ambiente)

### ✅ Scripts de Deploy Automático
- **Script de Instalação**: Automatiza todo o processo de setup em VPS Ubuntu
  - Instalação de dependências (Docker, uv, Python 3.12)
  - Configuração de usuário dedicado
  - Setup do repositório e configurações
  - Configuração de serviço systemd
  - Setup de proxy reverso com Nginx
  - Configuração de firewall UFW
  - Scripts de gerenciamento

- **Script de Monitoramento**: Monitora e mantém o sistema em produção
  - Verificação de status do serviço
  - Monitoramento de recursos (CPU, memória, disco)
  - Análise de logs de erro
  - Verificação de conectividade da API
  - Rotação de logs e backup
  - Limpeza automática do sistema

### ✅ Documentação Técnica
- **Relatório de Análise**: Análise completa da arquitetura e componentes
- **Guia de Deploy**: Instruções detalhadas para instalação em VPS
- **Configuração de Produção**: Arquivo otimizado para ambiente de servidor

## Como Usar

### 1. Deploy Rápido em VPS Ubuntu 24.x
```bash
# Baixar e executar o script de instalação
wget https://raw.githubusercontent.com/brunopirz/OpenManus-gemini/main/scripts/install-ubuntu-vps.sh
chmod +x install-ubuntu-vps.sh
sudo ./install-ubuntu-vps.sh
```

#### Configuração de API Keys
O script de instalação oferece duas opções:
1. **Arquivo .env** (recomendado para segurança)
2. **Diretamente no config.toml** (mais simples)

Para mais detalhes, consulte o [guia de configuração de API keys](./configuracao-api-keys.md).

### 2. Configuração Manual
Consulte o arquivo [deploy-vps-ubuntu.md](./deploy-vps-ubuntu.md) para instruções detalhadas de instalação manual.

### 3. Monitoramento
```bash
# Executar script de monitoramento
./scripts/monitor-production.sh --report

# Manutenção automática
./scripts/monitor-production.sh --maintenance
```

## Estrutura de Arquivos

```
docs/
├── README.md                    # Este arquivo
├── relatorio-analise-projeto.md # Análise técnica detalhada
├── deploy-vps-ubuntu.md         # Guia de deploy
├── configuracao-api-keys.md     # Guia de configuração de API keys
└── changelog-configuracoes.md   # Registro de alterações

scripts/
├── install-ubuntu-vps.sh        # Script de instalação automática
└── monitor-production.sh         # Script de monitoramento

config/
└── config.production-vps.toml    # Configuração para produção
```

## Requisitos do Sistema

### VPS Ubuntu Server 24.x
- **RAM**: Mínimo 2GB (recomendado 4GB+)
- **CPU**: 2 vCPUs (recomendado 4+)
- **Armazenamento**: 20GB (recomendado 50GB+)
- **Rede**: Conexão estável com internet

### APIs Necessárias
- **Google Gemini API**: Chave de API válida ([Google AI Studio](https://aistudio.google.com/))
- **Opcional**: OpenAI API, Anthropic API, Ollama (local)
- **Configuração flexível**: Suporte a arquivo .env, config.toml ou variáveis de ambiente

## Segurança

- ✅ Usuário dedicado para execução do serviço
- ✅ Firewall UFW configurado
- ✅ Proxy reverso Nginx
- ✅ Logs estruturados e rotacionados
- ✅ Backup automático de configurações

## Suporte

Para problemas ou dúvidas:
1. Consulte os logs: `sudo journalctl -u openmanus -f`
2. Verifique o status: `./scripts/monitor-production.sh --report`
3. Consulte a documentação técnica em `docs/`

## Próximos Passos

1. **Teste o deploy** em ambiente de desenvolvimento
2. **Configure as chaves de API** necessárias
3. **Execute o script de instalação** na VPS
4. **Configure monitoramento** com o script fornecido
5. **Personalize as configurações** conforme necessário

---

**Projeto OpenManus** - Agente de IA com suporte a múltiplas APIs LLM

*Documentação atualizada em: $(date)*