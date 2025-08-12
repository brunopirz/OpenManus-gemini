#!/bin/bash

# Script de instalação corrigido para OpenManus no Linux
# Resolve problemas de ambiente virtual e dependências

set -e  # Para em caso de erro

echo "🚀 Iniciando instalação do OpenManus..."

# Verificar se estamos no diretório correto
if [ ! -f "main.py" ]; then
    echo "❌ Erro: Execute este script no diretório raiz do OpenManus"
    exit 1
fi

# Verificar se Python 3 está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 não encontrado. Instalando..."
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv python3-full
fi

echo "✅ Python $(python3 --version) encontrado"

# Criar ambiente virtual
echo "📦 Criando ambiente virtual..."
if [ -d ".venv" ]; then
    echo "⚠️  Ambiente virtual já existe. Removendo..."
    rm -rf .venv
fi

python3 -m venv .venv
echo "✅ Ambiente virtual criado"

# Ativar ambiente virtual
echo "🔧 Ativando ambiente virtual..."
source .venv/bin/activate

# Verificar se a ativação funcionou
if [ "$VIRTUAL_ENV" = "" ]; then
    echo "❌ Erro: Falha ao ativar ambiente virtual"
    exit 1
fi

echo "✅ Ambiente virtual ativado: $VIRTUAL_ENV"

# Atualizar pip
echo "📦 Atualizando pip..."
python -m pip install --upgrade pip

# Instalar dependências
echo "📦 Instalando dependências..."
python -m pip install -r requirements.txt

echo "✅ Dependências instaladas com sucesso"

# Criar arquivo de configuração se não existir
if [ ! -f "config/config.toml" ]; then
    echo "⚙️  Criando arquivo de configuração..."
    cp config/config.example.toml config/config.toml
    echo "✅ Arquivo config/config.toml criado"
else
    echo "✅ Arquivo de configuração já existe"
fi

# Verificar se .env existe
if [ ! -f ".env" ]; then
    echo "⚙️  Criando arquivo .env..."
    cp .env.example .env
    echo "✅ Arquivo .env criado"
else
    echo "✅ Arquivo .env já existe"
fi

echo ""
echo "🎉 Instalação concluída com sucesso!"
echo ""
echo "📋 Próximos passos:"
echo "1. Configure sua API Key no arquivo .env ou config/config.toml"
echo "2. Ative o ambiente virtual: source .venv/bin/activate"
echo "3. Execute o OpenManus: python main.py --prompt 'Olá, teste'"
echo ""
echo "📚 Para mais informações, consulte: docs/README.md"
echo ""
echo "🔑 Para configurar API Keys:"
echo "   - Google Gemini: https://makersuite.google.com/app/apikey"
echo "   - Anthropic Claude: https://console.anthropic.com/"
echo "   - OpenAI: https://platform.openai.com/api-keys"
echo ""
echo "🐳 Alternativa Docker:"
echo "   docker-compose up -d"
echo ""