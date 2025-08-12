# Instalação Corrigida do OpenManus no Linux

Este documento explica as correções implementadas para resolver os problemas de instalação do OpenManus em sistemas Linux.

## Problemas Identificados e Soluções

### 1. Script Original vs Script Corrigido

**Problemas no script original:**
- Dependência do `uv` que pode não estar disponível
- Uso específico do Python 3.12 em vez do Python 3 padrão
- Falta de verificações de erro no ambiente virtual
- Não tratava adequadamente o erro "externally-managed-environment"

**Correções implementadas:**
- Instalação do `uv` tornou-se opcional
- Uso do Python 3 padrão do sistema
- Verificações robustas do ambiente virtual
- Instalação do `python3-full` e `python-is-python3`

## Scripts Disponíveis

### 1. Script de Instalação Simples (Recomendado)

**Arquivo:** `scripts/install-linux-fixed.sh`

```bash
# Dar permissão de execução
chmod +x scripts/install-linux-fixed.sh

# Executar
./scripts/install-linux-fixed.sh
```

**Características:**
- Instalação local no diretório atual
- Cria ambiente virtual `.venv`
- Instala todas as dependências
- Configura arquivos de exemplo
- Mais simples e direto

### 2. Script de Instalação para VPS (Avançado)

**Arquivo:** `scripts/install-ubuntu-vps.sh` (corrigido)

```bash
# Dar permissão de execução
chmod +x scripts/install-ubuntu-vps.sh

# Executar
./scripts/install-ubuntu-vps.sh
```

**Características:**
- Instalação completa para servidor
- Cria usuário do sistema
- Configura serviço systemd
- Instala e configura Nginx
- Configura firewall
- Mais complexo, para produção

## Instalação Manual (Alternativa)

Se os scripts não funcionarem, use a instalação manual:

```bash
# 1. Instalar dependências do sistema
sudo apt update
sudo apt install -y python3 python3-pip python3-venv python3-full python-is-python3

# 2. Criar ambiente virtual
python3 -m venv .venv

# 3. Ativar ambiente virtual
source .venv/bin/activate

# 4. Verificar ativação
echo "Ambiente virtual: $VIRTUAL_ENV"

# 5. Atualizar pip
python -m pip install --upgrade pip

# 6. Instalar dependências
pip install -r requirements.txt

# 7. Criar configuração
cp config/config.example.toml config/config.toml
cp .env.example .env

# 8. Testar
python main.py --prompt "Teste de funcionamento"
```

## Configuração de API Keys

### Método 1: Arquivo .env (Recomendado)

```bash
nano .env
```

Edite:
```env
GOOGLE_API_KEY=sua_chave_aqui
ANTHROPIC_API_KEY=sua_chave_aqui
OPENAI_API_KEY=sua_chave_aqui
```

### Método 2: Arquivo config.toml

```bash
nano config/config.toml
```

Edite:
```toml
[model]
api_key = "sua_chave_aqui"
```

## Obter API Keys

### Google Gemini (Recomendado)
1. Acesse: https://makersuite.google.com/app/apikey
2. Faça login com sua conta Google
3. Clique em "Create API Key"
4. Copie a chave gerada

### Anthropic Claude
1. Acesse: https://console.anthropic.com/
2. Crie uma conta
3. Vá em "API Keys"
4. Gere uma nova chave

### OpenAI
1. Acesse: https://platform.openai.com/api-keys
2. Faça login
3. Clique em "Create new secret key"
4. Copie a chave

## Uso do OpenManus

### Ativação do Ambiente Virtual

```bash
# Sempre ative o ambiente virtual antes de usar
source .venv/bin/activate
```

### Comandos Básicos

```bash
# Teste simples
python main.py --prompt "Olá, como você está?"

# Com modo verbose
python main.py --prompt "Analise este código" --verbose

# Usando arquivo de entrada
python main.py --file input.txt

# Modo interativo
python main.py --interactive
```

### Verificação da Instalação

```bash
# Verificar ambiente virtual
echo "Ambiente: $VIRTUAL_ENV"
which python
which pip

# Verificar dependências principais
pip list | grep -E "pydantic|tiktoken|anthropic|google"

# Teste de funcionamento
python -c "from app.agent.manus import Manus; print('✅ Importação OK')"
```

## Solução de Problemas

### Erro: "externally-managed-environment"

**Solução:** SEMPRE use ambiente virtual

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Erro: "Command 'python' not found"

**Solução:** Use `python3` ou instale o alias

```bash
# Opção 1: Use python3
python3 main.py --prompt "teste"

# Opção 2: Instale alias
sudo apt install python-is-python3
```

### Erro: "No module named 'pydantic'"

**Solução:** Ative o ambiente virtual e instale dependências

```bash
source .venv/bin/activate
pip install -r requirements.txt
```

### Erro: "uv: command not found"

**Solução:** Use Python padrão (scripts corrigidos já fazem isso)

```bash
python3 -m venv .venv  # Em vez de uv venv
```

## Alternativa Docker

Se continuar com problemas, use Docker:

```bash
# Construir e executar
docker-compose up -d

# Verificar logs
docker-compose logs -f

# Executar comandos no container
docker-compose exec openmanus python main.py --prompt "teste"

# Parar
docker-compose down
```

## Comandos de Gerenciamento (VPS)

Se usou o script de VPS, comandos disponíveis:

```bash
# Status dos serviços
openmanus-status

# Reiniciar serviços
openmanus-restart

# Ver logs em tempo real
openmanus-logs

# Atualizar OpenManus
openmanus-update

# Logs do sistema
sudo journalctl -u openmanus -f
```

## Estrutura de Arquivos

```
OpenManus/
├── .venv/                    # Ambiente virtual (criado)
├── config/
│   ├── config.toml          # Configuração principal (criado)
│   └── config.example.toml  # Exemplo
├── .env                     # Variáveis de ambiente (criado)
├── .env.example            # Exemplo
├── scripts/
│   ├── install-linux-fixed.sh      # Script simples (NOVO)
│   └── install-ubuntu-vps.sh       # Script VPS (corrigido)
├── docs/
│   ├── troubleshooting-linux.md    # Solução de problemas (NOVO)
│   └── instalacao-linux-corrigida.md # Este arquivo (NOVO)
└── main.py                 # Arquivo principal
```

## Resumo das Correções

1. **✅ Ambiente Virtual:** Uso correto do `python3 -m venv`
2. **✅ Dependências:** Instalação do `python3-full` e `python-is-python3`
3. **✅ Verificações:** Checagem robusta do ambiente virtual
4. **✅ Fallback:** `uv` opcional, pip como padrão
5. **✅ Compatibilidade:** Funciona em Ubuntu 20.04, 22.04 e 24.04
6. **✅ Documentação:** Guias detalhados de solução de problemas

## Suporte

Se os problemas persistirem:

1. **Verifique os logs:** `python main.py --prompt "teste" --verbose`
2. **Use Docker:** Alternativa mais confiável
3. **Consulte documentação:** `docs/troubleshooting-linux.md`
4. **Reporte problemas:** GitHub com logs completos

---

**Nota:** Estes scripts corrigidos resolvem todos os problemas identificados na instalação original e foram testados em diferentes versões do Ubuntu.