# Configuração de API Keys - OpenManus

## Visão Geral

O OpenManus suporta múltiplas formas de configurar as chaves de API para garantir flexibilidade e segurança. Este guia explica todas as opções disponíveis.

## Google Gemini (Padrão)

O OpenManus está configurado por padrão para usar o Google Gemini como LLM principal. Você precisa de uma chave de API do Google AI Studio.

### Como Obter a API Key

1. Acesse [Google AI Studio](https://aistudio.google.com/)
2. Faça login com sua conta Google
3. Clique em "Get API Key" ou "Obter chave de API"
4. Crie uma nova chave de API
5. Copie a chave gerada

## Métodos de Configuração

### 1. Arquivo .env (Recomendado) 🔒

**Vantagens:**
- Mais seguro (não expõe chaves no código)
- Fácil de gerenciar em diferentes ambientes
- Não é commitado no Git por padrão

**Como configurar:**

1. Crie o arquivo `.env` na raiz do projeto:
```bash
# Configurações de ambiente para OpenManus
GOOGLE_API_KEY=sua_chave_api_aqui
```

2. Atualize o `config.toml` para usar a variável:
```toml
[llm]
api_key = "${GOOGLE_API_KEY}"

[llm.vision]
api_key = "${GOOGLE_API_KEY}"
```

### 2. Diretamente no config.toml

**Vantagens:**
- Configuração simples e direta
- Tudo em um arquivo

**Desvantagens:**
- Menos seguro (chave visível no arquivo)
- Risco de commit acidental da chave

**Como configurar:**

Edite o arquivo `config/config.toml`:
```toml
[llm]
api_key = "sua_chave_api_real_aqui"

[llm.vision]
api_key = "sua_chave_api_real_aqui"
```

### 3. Variáveis de Ambiente do Sistema

**Para desenvolvimento local:**
```bash
# Linux/macOS
export GOOGLE_API_KEY="sua_chave_api_aqui"

# Windows
set GOOGLE_API_KEY=sua_chave_api_aqui
```

**Para produção (systemd service):**
```ini
[Service]
Environment=GOOGLE_API_KEY=sua_chave_api_aqui
```

## Configuração Automática via Script

O script de instalação `install-ubuntu-vps.sh` oferece configuração interativa:

```bash
# Durante a instalação, você será perguntado:
# Configuração da API Key do Google Gemini:
# Você pode configurar a API key de duas formas:
# 1. Diretamente no arquivo de configuração (config.toml)
# 2. Via arquivo .env (recomendado para segurança)
# 
# Escolha a opção (1 ou 2) [2]: 2
# Digite sua API Key do Google Gemini: sua_chave_aqui
```

## APIs Alternativas

O OpenManus também suporta outras APIs LLM. Para configurá-las, descomente as seções correspondentes no `config.toml`:

### OpenAI
```toml
[llm]
model = "gpt-4o"
base_url = "https://api.openai.com/v1/"
api_key = "${OPENAI_API_KEY}"  # ou sua chave direta
```

### Anthropic Claude
```toml
[llm]
model = "claude-3-7-sonnet-20250219"
base_url = "https://api.anthropic.com/v1/"
api_key = "${ANTHROPIC_API_KEY}"  # ou sua chave direta
```

### Ollama (Local)
```toml
[llm]
api_type = "ollama"
model = "llama3.2"
base_url = "http://localhost:11434/v1"
api_key = "ollama"
```

## Segurança e Boas Práticas

### ✅ Recomendações

1. **Use arquivo .env** para chaves de API
2. **Adicione .env ao .gitignore** para evitar commits acidentais
3. **Use variáveis de ambiente** em produção
4. **Rotacione chaves regularmente**
5. **Monitore uso da API** para detectar uso não autorizado

### ❌ Evite

1. **Não commite chaves** no repositório
2. **Não compartilhe chaves** em mensagens ou logs
3. **Não use chaves em URLs** ou parâmetros GET
4. **Não deixe chaves** em arquivos temporários

## Verificação da Configuração

### Teste Rápido
```bash
# Verificar se a configuração está correta
cd /opt/openmanus/OpenManus
source venv/bin/activate
python -c "from app.config import Config; print('Configuração OK!' if Config().llm.api_key != 'YOUR_GOOGLE_API_KEY' else 'Configure a API key!')"
```

### Logs de Erro Comuns

**Chave inválida:**
```
ERROR: Invalid API key provided
```
**Solução:** Verifique se a chave está correta e ativa

**Chave não configurada:**
```
ERROR: API key not found
```
**Solução:** Configure a chave usando um dos métodos acima

**Cota excedida:**
```
ERROR: Quota exceeded
```
**Solução:** Verifique os limites da sua conta no Google AI Studio

## Monitoramento

### Script de Monitoramento
O script `monitor-production.sh` inclui verificação de conectividade da API:

```bash
./scripts/monitor-production.sh --report
```

### Logs do Sistema
```bash
# Verificar logs do serviço
sudo journalctl -u openmanus -f

# Verificar logs específicos de API
sudo journalctl -u openmanus | grep -i "api\|key\|auth"
```

## Suporte

Para problemas com configuração de API keys:

1. **Verifique a documentação** do provedor da API
2. **Consulte os logs** do sistema
3. **Teste a conectividade** com o script de monitoramento
4. **Abra uma issue** no [repositório](https://github.com/brunopirz/OpenManus/issues)

---

**OpenManus** - Configuração flexível e segura de APIs LLM

*Documentação atualizada para o repositório: https://github.com/brunopirz/OpenManus*