# 部署 Supabase Edge Function 脚本
# 使用 Management API 直接部署

param(
    [Parameter(Mandatory=$true)]
    [string]$AccessToken,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectRef,
    
    [string]$FunctionName = "alipay-order"
)

$ErrorActionPreference = "Stop"

# Edge Function 文件路径
$functionDir = "supabase/functions/$FunctionName"
$indexFile = "$functionDir/index.ts"

if (-not (Test-Path $indexFile)) {
    Write-Error "Edge Function 文件不存在: $indexFile"
    exit 1
}

# 读取 Edge Function 代码
$code = Get-Content -Path $indexFile -Raw -Encoding UTF8

# 创建部署包（base64 编码）
$bytes = [System.Text.Encoding]::UTF8.GetBytes($code)
$base64Code = [Convert]::ToBase64String($bytes)

# 使用 Supabase Management API 部署
$headers = @{
    "Authorization" = "Bearer $AccessToken"
    "Content-Type" = "application/json"
}

$body = @{
    slug = $FunctionName
    name = $FunctionName
    source = $base64Code
    verify_jwt = $true
} | ConvertTo-Json -Depth 10

Write-Host "正在部署 Edge Function: $FunctionName..." -ForegroundColor Cyan
Write-Host "项目: $ProjectRef" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "https://api.supabase.com/v1/projects/$ProjectRef/functions" -Method Post -Headers $headers -Body $body
    Write-Host "✅ Edge Function 部署成功!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 5) -ForegroundColor Gray
} catch {
    Write-Host "❌ 部署失败" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    # 尝试更新（如果已存在）
    Write-Host "尝试更新现有函数..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "https://api.supabase.com/v1/projects/$ProjectRef/functions/$FunctionName" -Method Patch -Headers $headers -Body $body
        Write-Host "✅ Edge Function 更新成功!" -ForegroundColor Green
    } catch {
        Write-Host "❌ 更新也失败了" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
