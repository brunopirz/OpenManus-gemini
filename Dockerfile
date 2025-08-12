FROM python:3.12-slim

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalar uv para gerenciamento de pacotes Python mais rápido
RUN pip install --no-cache-dir uv

# Criar usuário não-root para segurança
RUN useradd --create-home --shell /bin/bash openmanus

# Definir diretório de trabalho
WORKDIR /app

# Copiar arquivos de dependências primeiro (para cache do Docker)
COPY requirements.txt .

# Instalar dependências Python
RUN uv pip install --system -r requirements.txt

# Copiar código da aplicação
COPY . .

# Criar diretório para configurações
RUN mkdir -p /app/config && chown -R openmanus:openmanus /app

# Mudar para usuário não-root
USER openmanus

# Expor porta (se necessário para APIs futuras)
EXPOSE 8000

# Comando padrão
CMD ["python", "main.py"]
