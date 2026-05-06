# 测试 Edge Function 的 PowerShell 脚本

$uri = 'https://ibffrwevphkkbcfgaift.supabase.co/functions/v1/alipay-order'
$anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImliZmZyd2V2cGhra2JjZmdhaWZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMDI3MTEsImV4cCI6MjA5MjY3ODcxMX0.hWJw5bnMTYfnox2BAk4_0DFDmMi-b2H4mTemZSwWwEA'

# 测试 1: 正确的请求格式
Write-Host "=== Test 1: Correct request ==="
$headers = @{
  'Content-Type' = 'application/json'
  'Authorization' = "Bearer $anonKey"
}
$body = '{"product":"oracle","userId":"test123"}'

try {
  $resp = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -Body $body -UseBasicParsing
  Write-Host "Status: $($resp.StatusCode)"
  Write-Host "Response: $($resp.Content)"
} catch {
  Write-Host "Error: $($_.Exception.Message)"
  if ($_.Exception.Response) {
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    Write-Host "Error Body: $($reader.ReadToEnd())"
  }
}

Write-Host ""
Write-Host "=== Test 2: Check if function exists ==="
try {
  $resp = Invoke-WebRequest -Uri $uri -Method OPTIONS -UseBasicParsing
  Write-Host "OPTIONS Status: $($resp.StatusCode)"
  Write-Host "Headers: $($resp.Headers | ConvertTo-Json)"
} catch {
  Write-Host "OPTIONS Error: $($_.Exception.Message)"
}
