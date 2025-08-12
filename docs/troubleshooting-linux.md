# Guia de Solução de Problemas - Linux

Este documento resolve os problemas comuns encontrados durante a instalação do OpenManus em sistemas Linux.

## Problemas Identificados e Soluções

### 1. Comando `uv` não encontrado

**Problema:**
```bash
uv: command not found
```

**Solução:**
O `uv` não está instalado no sistema. Use o Python padrão para criar o ambiente virtual:

```bash
python3 -m venv .venv
```

### 2. Ambiente virtual não existe

**Problema:**
```bash
-bash: .venv/bin/activate: No such file or directory
```

**Solução:**
Crie o ambiente virtual primeiro:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Comando `python` não encontrado

**Problema:**
```bash
Command 'python' not found, did you mean:
  command 'python3' from deb python3
```

**Solução:**
Use `python3` em vez de `python`, ou instale o alias:

```bash
# Opção 1: Use python3
python3 main.py --prompt "Olá, teste"

# Opção 2: Instale o alias python
sudo apt install python-is-python3
```

### 4. Ambiente externamente gerenciado

**Problema:**
```bash
error: externally-managed-environment
× This environment is externally managed
```

**Solução:**
Este é um recurso de segurança do Python 3.12+. SEMPRE use um ambiente virtual:

```bash
# Criar ambiente virtual
python3 -m venv .venv

# Ativar ambiente virtual
source .venv/bin/activate

# Instalar dependências
pip install -r requirements.txt
```

### 5. Módulos não encontrados

**Problema:**
```bash
ModuleNotFoundError: No module named 'pydantic'
```

**Solução:**
Instale as dependências no ambiente virtual ativado:

```bash
source .venv/bin/activate
pip install -r requirements.txt
```

## Script de Instalação Corrigido

Use o script corrigido que resolve todos esses problemas:

```bash
# Dar permissão de execução
chmod +x scripts/install-linux-fixed.sh

# Executar o script
./scripts/install-linux-fixed.sh
```

## Instalação Manual Passo a Passo

Se preferir fazer a instalação manual:

```bash
# 1. Verificar Python
python3 --version

# 2. Instalar dependências do sistema (se necessário)
sudo apt update
sudo apt install -y python3 python3-pip python3-venv python3-full

# 3. Criar ambiente virtual
python3 -m venv .venv

# 4. Ativar ambiente virtual
source .venv/bin/activate

# 5. Atualizar pip
python -m pip install --upgrade pip

# 6. Instalar dependências
pip install -r requirements.txt

# 7. Criar configuração
cp config/config.example.toml config/config.toml
cp .env.example .env

# 8. Testar instalação
python main.py --prompt "Olá, teste"
```

## Configuração de API Keys

Após a instalação, configure suas API keys:

### Opção 1: Arquivo .env
```bash
nano .env
```

Edite as linhas:
```env
GOOGLE_API_KEY=sua_chave_aqui
ANTHROPIC_API_KEY=sua_chave_aqui
OPENAI_API_KEY=sua_chave_aqui
```

### Opção 2: Arquivo config.toml
```bash
nano config/config.toml
```

Edite a seção:
```toml
[model]
api_key = "sua_chave_aqui"
```

## Alternativa Docker

Se continuar com problemas, use Docker:

```bash
# Construir e executar
docker-compose up -d

# Verificar logs
docker-compose logs -f

# Parar
docker-compose down
```

## Verificação da Instalação

Para verificar se tudo está funcionando:

```bash
# Ativar ambiente virtual
source .venv/bin/activate

# Verificar Python e pip
which python
which pip

# Verificar dependências instaladas
pip list | grep pydantic
pip list | grep tiktoken

# Testar aplicação
python main.py --prompt "Teste de funcionamento"
```

## Dicas Importantes

1. **SEMPRE** use ambiente virtual no Linux moderno
2. **NUNCA** use `--break-system-packages` (pode quebrar o sistema)
3. Use `python3` em vez de `python` se não tiver o alias
4. Mantenha o ambiente virtual ativado durante o uso
5. Para reativar: `source .venv/bin/activate`

## Suporte

Se os problemas persistirem:

1. Verifique os logs: `python main.py --prompt "teste" --verbose`
2. Consulte a documentação: `docs/README.md`
3. Use Docker como alternativa
4. Reporte problemas no GitHub com os logs completos