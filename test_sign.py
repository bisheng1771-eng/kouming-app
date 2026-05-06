"""Test RSA2 signing with the new private key"""
from cryptography.hazmat.primitives.serialization import load_der_private_key
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
import base64

# Read private key
with open(r'C:\Users\85932\Documents\支付宝开放平台密钥工具\密钥20260506180137\应用私钥RSA2048-敏感数据，请妥善保管.txt', 'r', encoding='utf-8') as f:
    key_b64 = f.read().strip()

# Add padding if needed
missing = len(key_b64) % 4
if missing:
    key_b64 += '=' * (4 - missing)

data = base64.b64decode(key_b64)
key = load_der_private_key(data, password=None)

# Test sign
test_str = 'app_id=2021006149691180&charset=utf-8&format=JSON&method=alipay.trade.app.pay&sign_type=RSA2&timestamp=2026-05-06 16:26:14&version=1.0'

signature = key.sign(
    test_str.encode('utf-8'),
    padding.PKCS1v15(),
    hashes.SHA256()
)

sign_b64 = base64.b64encode(signature).decode()
print('Signature generated successfully!')
print('Signature length:', len(sign_b64))
print('First 40 chars:', sign_b64[:40])
