# Instalação e Execução com Docker

Este guia explica como executar o OpenManus usando Docker e Docker Compose, incluindo instruções específicas para o Portainer.

## Pré-requisitos

- Docker Engine 20.10+
- Docker Compose 2.0+
- Pelo menos 2GB de RAM disponível
- Chaves de API configuradas (Google Gemini, Anthropic, etc.)

## Instalação Rápida

### 1. Clone o Repositório

```bash
git clone https://github.com/brunopirz/OpenManus-gemini.git
cd OpenManus-gemini
```

### 2. Configuração

#### Opção A: Usando arquivo de configuração

1. Copie o arquivo de exemplo:
```bash
cp config/config.example.toml config/config.toml
```

2. Edite o arquivo `config/config.toml` com suas chaves de API:
```toml
[llm]
model = "gemini-2.5-pro"
base_url = "https://generativelanguage.googleapis.com/v1beta/openai/"
api_key = "SUA_CHAVE_GOOGLE_API_AQUI"
max_tokens = 8192
temperature = 0.0
```

#### Opção B: Usando variáveis de ambiente

Crie um arquivo `.env` na raiz do projeto:
```bash
# Chaves de API
GOOGLE_API_KEY=sua_chave_google_aqui
ANTHROPIC_API_KEY=sua_chave_anthropic_aqui

# Configurações opcionais
PYTHONUNBUFFERED=1
PYTHONDONTWRITEBYTECODE=1
```

### 3. Execução

#### Usando Docker Compose (Recomendado)

```bash
# Build e execução
docker-compose up -d

# Verificar logs
docker-compose logs -f openmanus

# Parar o serviço
docker-compose down
```

#### Usando Docker diretamente

```bash
# Build da imagem
docker build -t openmanus .

# Execução
docker run -d \
  --name openmanus-app \
  -v $(pwd)/config:/app/config:ro \
  -v $(pwd)/logs:/app/logs \
  -e GOOGLE_API_KEY=sua_chave_aqui \
  openmanus
```

## Uso no Portainer

### Método 1: Stack do Docker Compose

1. Acesse o Portainer
2. Vá para **Stacks** → **Add Stack**
3. Nomeie a stack como "openmanus"
4. Cole o conteúdo do `docker-compose.yml`:

```yaml
version: '3.8'

services:
  openmanus:
    image: openmanus:latest
    container_name: openmanus-app
    restart: unless-stopped
    environment:
      - PYTHONUNBUFFERED=1
      - PYTHONDONTWRITEBYTECODE=1
      - GOOGLE_API_KEY=${GOOGLE_API_KEY}
    volumes:
      - openmanus-config:/app/config
      - openmanus-logs:/app/logs
      - openmanus-data:/app/data
    ports:
      - "8000:8000"
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
    networks:
      - openmanus-network

networks:
  openmanus-network:
    driver: bridge

volumes:
  openmanus-config:
  openmanus-logs:
  openmanus-data:
```

5. Na seção **Environment variables**, adicione:
   - `GOOGLE_API_KEY`: sua chave da API do Google
   - `ANTHROPIC_API_KEY`: sua chave da API da Anthropic (opcional)

6. Clique em **Deploy the stack**

### Método 2: Build a partir do repositório

1. No Portainer, vá para **Images** → **Build a new image**
2. Nomeie a imagem como "openmanus:latest"
3. Em **Build method**, selecione **Git Repository**
4. URL: `https://github.com/brunopirz/OpenManus-gemini.git`
5. Dockerfile path: `Dockerfile`
6. Clique em **Build the image**
7. Após o build, use o Método 1 para criar a stack

## Configuração Avançada

### Volumes Persistentes

O docker-compose.yml já configura volumes para:
- `/app/config`: Arquivos de configuração
- `/app/logs`: Logs da aplicação
- `/app/data`: Dados persistentes

### Recursos do Sistema

Por padrão, o container está limitado a:
- **Memória**: 2GB (limite), 512MB (reservado)
- **CPU**: 1.0 core (limite), 0.5 core (reservado)

Para ajustar, edite a seção `deploy.resources` no docker-compose.yml.

### Healthcheck

O container inclui um healthcheck que verifica a cada 30 segundos se o Python está funcionando corretamente.

## Monitoramento

### Verificar Status

```bash
# Status dos containers
docker-compose ps

# Logs em tempo real
docker-compose logs -f openmanus

# Uso de recursos
docker stats openmanus-app
```

### No Portainer

1. Vá para **Containers**
2. Clique no container "openmanus-app"
3. Use as abas **Logs**, **Stats**, e **Console** para monitoramento

## Solução de Problemas

### Container não inicia

1. Verifique os logs:
```bash
docker-compose logs openmanus
```

2. Verifique se as chaves de API estão corretas
3. Verifique se há recursos suficientes disponíveis

### Problemas de dependências

Se houver conflitos de dependências Python:

1. Rebuild a imagem:
```bash
docker-compose build --no-cache openmanus
docker-compose up -d
```

### Acesso aos arquivos de configuração

Para editar configurações em um container em execução:

```bash
# Acessar o container
docker-compose exec openmanus bash

# Ou copiar arquivos
docker cp config.toml openmanus-app:/app/config/
```

## Atualizações

### Atualizar para nova versão

```bash
# Parar o serviço
docker-compose down

# Atualizar código
git pull origin main

# Rebuild e reiniciar
docker-compose build --no-cache
docker-compose up -d
```

## Segurança

- O container executa com usuário não-root (`openmanus`)
- Arquivos de configuração são montados como somente leitura
- Variáveis de ambiente são usadas para informações sensíveis
- Rede isolada para comunicação entre serviços

## Suporte

Para problemas relacionados ao Docker:
1. Verifique os logs do container
2. Confirme que as dependências estão instaladas
3. Verifique a configuração de rede
4. Consulte a [documentação oficial do Docker](https://docs.docker.com/)

Para problemas específicos do OpenManus:
- Consulte a [documentação principal](README.md)
- Abra uma [issue no GitHub](https://github.com/brunopirz/OpenManus-gemini/issues)