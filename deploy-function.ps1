# 部署 Supabase Edge Function 脚本
# 使用 npx supabase 直接部署
# 使用方式: .\deploy-function.ps1 <access_token>

param(
    [Parameter(Mandatory=$true)]
    [string]$accessToken
)

$projectRef = "ibffrwevphkkbcfgaift"
$functionName = "alipay-order"

# 设置环境变量
$env:SUPABASE_ACCESS_TOKEN = $accessToken

# 检查 supabase CLI
$npxPath = Get-Command npx -ErrorAction SilentlyContinue
if (-not $npxPath) {
    Write-Host "npx 未找到，尝试安装..." -ForegroundColor Red
    npm install -g npx
}

# 部署函数
Write-Host "正在部署 Edge Function: $functionName" -ForegroundColor Cyan
Write-Host "项目: $projectRef" -ForegroundColor Cyan
Write-Host ""

try {
    npx supabase functions deploy $functionName --project-ref $projectRef
    Write-Host ""
    Write-Host "✅ 部署完成！" -ForegroundColor Green
} catch {
    Write-Host "❌ 部署失败: $_" -ForegroundColor Red
}
