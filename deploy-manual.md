# 手动部署 Edge Function 指南

## 方法 1: 使用 Supabase Dashboard（推荐）

1. 访问 https://supabase.com/dashboard/project/ibffrwevphkkbcfgaift/functions
2. 点击 "Deploy a new function"
3. 函数名: `alipay-order`
4. 复制 `supabase/functions/alipay-order/index.ts` 的内容粘贴进去
5. 点击 Deploy

## 方法 2: 使用 Management API

需要 Access Token (从 https://supabase.com/dashboard/account/tokens 获取)

```powershell
# 设置变量
$token = "你的_ACCESS_TOKEN"
$projectRef = "ibffrwevphkkbcfgaift"

# 读取代码
$code = Get-Content -Path "supabase/functions/alipay-order/index.ts" -Raw

# Base64 编码
$bytes = [System.Text.Encoding]::UTF8.GetBytes($code)
$base64 = [Convert]::ToBase64String($bytes)

# 部署
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$body = @{
    slug = "alipay-order"
    name = "alipay-order"
    source = $base64
    verify_jwt = $true
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://api.supabase.com/v1/projects/$projectRef/functions" -Method Post -Headers $headers -Body $body
```

## 配置 Secrets

部署后需要配置以下 Secrets：

1. 访问 https://supabase.com/dashboard/project/ibffrwevphkkbcfgaift/settings/functions
2. 添加 Secrets:
   - `ALIPAY_PRIVATE_KEY`: 你的支付宝私钥（PKCS#1 格式，保留换行）
   - `ALIPAY_PUBLIC_KEY`: 你的支付宝公钥

## 测试

部署完成后测试：
```bash
curl -X POST https://ibffrwevphkkbcfgaift.supabase.co/functions/v1/alipay-order \
  -H "Authorization: Bearer ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"product":"fate","amount":6}'
```
