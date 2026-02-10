# ============================================================
# Script para configurar políticas de protección en la rama Dev
# Requiere: GitHub CLI (gh) autenticado con permisos de admin
# Uso: .\configure-branch-protection.ps1
# ============================================================

$owner = "Angelra076"
$repo = "DME"
$branch = "Dev"

Write-Host "Configurando politicas de proteccion para la rama '$branch'..." -ForegroundColor Cyan

# Verificar que gh CLI esta instalado y autenticado
try {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: GitHub CLI no esta autenticado. Ejecuta 'gh auth login' primero." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error: GitHub CLI (gh) no esta instalado. Instalalo desde https://cli.github.com/" -ForegroundColor Red
    exit 1
}

# Configurar Branch Protection Rules via GitHub API
$body = @{
    required_status_checks = @{
        strict = $true
        contexts = @("check-issue")
    }
    enforce_admins = $true
    required_pull_request_reviews = @{
        required_approving_review_count = 1
        dismiss_stale_reviews = $true
        require_code_owner_reviews = $false
    }
    restrictions = $null
    required_linear_history = $true
    required_conversation_resolution = $true
} | ConvertTo-Json -Depth 5

Write-Host ""
Write-Host "=== Politicas a configurar ===" -ForegroundColor Yellow
Write-Host "1. Politica de revision de codigo:" -ForegroundColor Green
Write-Host "   - Pull Request obligatorio antes de merge"
Write-Host "   - Minimo 1 aprobacion requerida"
Write-Host "   - Aprobaciones anteriores se invalidan con nuevos commits"
Write-Host ""
Write-Host "2. Politica de link de work items (Issues):" -ForegroundColor Green
Write-Host "   - Status check 'check-issue' obligatorio"
Write-Host "   - Workflow valida referencia a Issue (#XX) en titulo o cuerpo del PR"
Write-Host ""
Write-Host "3. Politica de Pull Request:" -ForegroundColor Green
Write-Host "   - Conversaciones deben resolverse antes del merge"
Write-Host "   - Historial lineal requerido"
Write-Host "   - Admins no pueden hacer bypass"
Write-Host ""

gh api `
    --method PUT `
    -H "Accept: application/vnd.github+json" `
    "/repos/$owner/$repo/branches/$branch/protection" `
    --input - <<< $body

if ($LASTEXITCODE -eq 0) {
    Write-Host "Politicas de proteccion configuradas exitosamente en la rama '$branch'." -ForegroundColor Green
} else {
    Write-Host "Error al configurar las politicas. Verifica que tienes permisos de admin." -ForegroundColor Red
    Write-Host "Alternativa: Configura manualmente en https://github.com/$owner/$repo/settings/branches" -ForegroundColor Yellow
    exit 1
}
