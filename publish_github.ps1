# Script para publicar modificação do WhatsMeow no GitHub
# Windows PowerShell

Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Publicação do WhatsMeow - Histórico Desabilitado       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verificar se git está instalado
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git não encontrado! Instale: https://git-scm.com/" -ForegroundColor Red
    exit 1
}

# Solicitar informações do usuário
Write-Host "📝 Configuração Inicial" -ForegroundColor Yellow
Write-Host ""

$githubUser = Read-Host "Digite seu usuário do GitHub"
$userName = Read-Host "Digite seu nome completo"
$userEmail = Read-Host "Digite seu email"

Write-Host ""
Write-Host "🔍 Verificando se fork já existe..." -ForegroundColor Yellow

# Verificar se já tem remote configurado
$hasRemote = git remote -v 2>$null | Select-String "origin"

if ($hasRemote) {
    Write-Host "⚠️  Remote 'origin' já existe!" -ForegroundColor Yellow
    $overwrite = Read-Host "Deseja sobrescrever? (s/n)"
    if ($overwrite -ne "s") {
        Write-Host "❌ Operação cancelada." -ForegroundColor Red
        exit 1
    }
    git remote remove origin
}

# Inicializar git se necessário
if (-not (Test-Path ".git")) {
    Write-Host "📦 Inicializando repositório Git..." -ForegroundColor Green
    git init
} else {
    Write-Host "✅ Repositório Git já existe" -ForegroundColor Green
}

# Configurar usuário
Write-Host "⚙️  Configurando Git..." -ForegroundColor Green
git config user.name "$userName"
git config user.email "$userEmail"

# Adicionar remote
Write-Host "🔗 Adicionando remote do GitHub..." -ForegroundColor Green
git remote add origin "https://github.com/$githubUser/whatsmeow.git"

# Verificar arquivos modificados
Write-Host ""
Write-Host "📋 Arquivos a serem commitados:" -ForegroundColor Yellow
Write-Host "  ✏️  store/clientpayload.go (MODIFICADO)" -ForegroundColor White
Write-Host "  📄 LEIA-ME_MODIFICACAO.txt" -ForegroundColor White
Write-Host "  📄 RESUMO_SOLUCAO.md" -ForegroundColor White
Write-Host "  📄 MODIFICACOES_WHATSMEOW.txt" -ForegroundColor White
Write-Host "  📄 COMO_TESTAR.txt" -ForegroundColor White
Write-Host "  📄 INDICE_ARQUIVOS.txt" -ForegroundColor White
Write-Host "  📄 COMO_PUBLICAR_MODIFICACAO.md" -ForegroundColor White
Write-Host "  💻 exemplo_uso.go" -ForegroundColor White
Write-Host ""

$continue = Read-Host "Continuar com o commit? (s/n)"
if ($continue -ne "s") {
    Write-Host "❌ Operação cancelada." -ForegroundColor Red
    exit 1
}

# Adicionar arquivos
Write-Host ""
Write-Host "📦 Adicionando arquivos..." -ForegroundColor Green
git add store/clientpayload.go
git add LEIA-ME_MODIFICACAO.txt
git add RESUMO_SOLUCAO.md
git add MODIFICACOES_WHATSMEOW.txt
git add COMO_TESTAR.txt
git add INDICE_ARQUIVOS.txt
git add COMO_PUBLICAR_MODIFICACAO.md
git add exemplo_uso.go

# Verificar se há outros arquivos
Write-Host "❓ Deseja adicionar TODOS os outros arquivos do WhatsMeow? (s/n)" -ForegroundColor Yellow
$addAll = Read-Host
if ($addAll -eq "s") {
    git add .
    Write-Host "✅ Todos os arquivos adicionados" -ForegroundColor Green
}

# Criar commit
Write-Host ""
Write-Host "💾 Criando commit..." -ForegroundColor Green
$commitMessage = @"
feat: Adicionar configuração para desabilitar sincronização de histórico

- Adiciona HistorySyncConfig em DeviceProps com limites zerados por padrão
- Cria função SetHistorySyncConfig() para personalização
- Resolve problema de bloqueio de mensagens novas por sync de histórico
- Adiciona documentação completa em português
- Adiciona exemplos de uso e testes

Mudanças:
- store/clientpayload.go: Configuração de histórico
- Documentação: 6 arquivos de guia completo
- exemplo_uso.go: Código pronto para usar

Esta modificação faz com que mensagens novas cheguem imediatamente
ao reconectar, sem bloqueio por sincronização de histórico.
"@

git commit -m $commitMessage

# Criar branch main se necessário
Write-Host ""
Write-Host "🌿 Configurando branch main..." -ForegroundColor Green
git branch -M main

# Push
Write-Host ""
Write-Host "🚀 Fazendo push para GitHub..." -ForegroundColor Green
Write-Host "⚠️  IMPORTANTE: Você precisará autenticar no GitHub!" -ForegroundColor Yellow
Write-Host "   Use seu token pessoal como senha (não a senha da conta)" -ForegroundColor Yellow
Write-Host ""

$doPush = Read-Host "Fazer push agora? (s/n)"
if ($doPush -eq "s") {
    git push -u origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Push realizado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ Erro no push. Verifique:" -ForegroundColor Red
        Write-Host "   1. Se você criou o fork em: https://github.com/$githubUser/whatsmeow" -ForegroundColor Yellow
        Write-Host "   2. Se você tem permissões corretas" -ForegroundColor Yellow
        Write-Host "   3. Se usou o token pessoal correto" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Para criar o fork:" -ForegroundColor Cyan
        Write-Host "   1. Vá para: https://github.com/tulir/whatsmeow" -ForegroundColor White
        Write-Host "   2. Clique em 'Fork' no canto superior direito" -ForegroundColor White
        Write-Host ""
        Write-Host "Para criar token pessoal:" -ForegroundColor Cyan
        Write-Host "   1. Vá para: https://github.com/settings/tokens" -ForegroundColor White
        Write-Host "   2. Clique em 'Generate new token (classic)'" -ForegroundColor White
        Write-Host "   3. Marque 'repo' e 'workflow'" -ForegroundColor White
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "ℹ️  Push não realizado. Execute manualmente:" -ForegroundColor Cyan
    Write-Host "   git push -u origin main" -ForegroundColor White
}

# Criar tag
Write-Host ""
Write-Host "🏷️  Deseja criar uma tag/release? (s/n)" -ForegroundColor Yellow
$createTag = Read-Host

if ($createTag -eq "s") {
    $tagName = Read-Host "Nome da tag (ex: v1.0.0)"
    $tagMessage = Read-Host "Mensagem da tag"
    
    git tag -a $tagName -m "$tagMessage"
    
    $pushTag = Read-Host "Fazer push da tag? (s/n)"
    if ($pushTag -eq "s") {
        git push origin $tagName
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Tag $tagName publicada!" -ForegroundColor Green
        }
    }
}

# Resumo final
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║           ✅ PUBLICAÇÃO CONCLUÍDA COM SUCESSO!           ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Seu fork está em:" -ForegroundColor Cyan
Write-Host "   https://github.com/$githubUser/whatsmeow" -ForegroundColor White
Write-Host ""
Write-Host "📦 Outros usuários podem usar com:" -ForegroundColor Cyan
Write-Host "   go get github.com/$githubUser/whatsmeow" -ForegroundColor White
Write-Host ""
Write-Host "   Ou no go.mod:" -ForegroundColor Cyan
Write-Host "   replace go.mau.fi/whatsmeow => github.com/$githubUser/whatsmeow main" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Próximos passos:" -ForegroundColor Yellow
Write-Host "   1. Edite o README.md no GitHub explicando as diferenças" -ForegroundColor White
Write-Host "   2. Crie uma Release no GitHub (opcional)" -ForegroundColor White
Write-Host "   3. Compartilhe na comunidade WhatsMeow" -ForegroundColor White
Write-Host "   4. Considere criar um Pull Request para o projeto original" -ForegroundColor White
Write-Host ""
Write-Host "💬 Divulgue em:" -ForegroundColor Yellow
Write-Host "   - GitHub Discussions: https://github.com/tulir/whatsmeow/discussions" -ForegroundColor White
Write-Host "   - Matrix Room: https://matrix.to/#/#whatsmeow:maunium.net" -ForegroundColor White
Write-Host ""

pause
