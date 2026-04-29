// Supabase Edge Function: 生成支付宝订单签名 (v2)
// Flutter 调此接口获取 orderStr，然后调支付宝 SDK

// ===== 支付宝配置 =====
const ALIPAY_CONFIG = {
  appId: '2021006149691180',
  // 应用私钥（PKCS#8格式，需通过 supabase secrets 配置）
  // 支持两种格式：
  // 1. 完整 PEM 格式（含 BEGIN/END 标记和换行）
  // 2. 纯 base64 字符串（不含标记和换行，代码会自动添加）
  privateKey: (() => {
    let key = Deno.env.get('ALIPAY_PRIVATE_KEY') || '';
    
    // 清理
    key = key.replace(/\\n/g, '\n').replace(/\r/g, '').trim();
    
    // 如果 key 不包含 BEGIN 标记，说明是纯 base64，需要添加 PEM 包装
    if (!key.includes('BEGIN')) {
      // 移除所有空白字符
      key = key.replace(/\s/g, '');
      // 添加 PEM 标记和换行（每64字符一行）
      const lines = key.match(/.{1,64}/g) || [];
      key = '-----BEGIN PRIVATE KEY-----\n' + lines.join('\n') + '\n-----END PRIVATE KEY-----';
    }
    
    return key;
  })(),
  gateway: 'https://openapi.alipay.com/gateway.do',
  notifyUrl: 'https://ibffrwevphkkbcfgaift.supabase.co/functions/v1/alipay-notify',
};

// 产品配置
const PRODUCTS: Record<string, { name: string; price: number }> = {
  oracle:  { name: '算卦解读', price: 6.00 },
  fate:    { name: '天命签',   price: 6.00 },
  fulfill: { name: '还愿仪式', price: 3.60 },
};

// ASN.1 DER 编码辅助函数
function encodeLength(length: number): Uint8Array {
  if (length < 128) return new Uint8Array([length]);
  const hex = length.toString(16);
  const bytes = hex.match(/.{2}/g)!.map(b => parseInt(b, 16));
  return new Uint8Array([0x80 | bytes.length, ...bytes]);
}

function encodeInteger(value: Uint8Array): Uint8Array {
  // 如果最高位为1，需要添加前导零
  const needsPadding = value[0] >= 0x80;
  const content = needsPadding ? new Uint8Array([0, ...value]) : value;
  const length = encodeLength(content.length);
  const result = new Uint8Array(1 + length.length + content.length);
  result[0] = 0x02; // INTEGER tag
  result.set(length, 1);
  result.set(content, 1 + length.length);
  return result;
}

function encodeSequence(children: Uint8Array[]): Uint8Array {
  const totalLength = children.reduce((sum, child) => sum + child.length, 0);
  const length = encodeLength(totalLength);
  const result = new Uint8Array(1 + length.length + totalLength);
  result[0] = 0x30; // SEQUENCE tag
  result.set(length, 1);
  let offset = 1 + length.length;
  for (const child of children) {
    result.set(child, offset);
    offset += child.length;
  }
  return result;
}

function encodeOctetString(value: Uint8Array): Uint8Array {
  const length = encodeLength(value.length);
  const result = new Uint8Array(1 + length.length + value.length);
  result[0] = 0x04; // OCTET STRING tag
  result.set(length, 1);
  result.set(value, 1 + length.length);
  return result;
}

// 解析 PKCS#1 私钥，提取关键字段
function parsePKCS1PrivateKey(pkcs1Der: Uint8Array): {
  n: Uint8Array; e: Uint8Array; d: Uint8Array;
  p: Uint8Array; q: Uint8Array; dp: Uint8Array; dq: Uint8Array; qi: Uint8Array;
} {
  // 简单解析：跳过 SEQUENCE 头和 version，直接读取 9 个 INTEGER
  let offset = 0;
  
  // 跳过外层 SEQUENCE
  if (pkcs1Der[offset++] !== 0x30) throw new Error('Expected SEQUENCE');
  const seqLen = pkcs1Der[offset++];
  if (seqLen & 0x80) offset += (seqLen & 0x7F);
  
  // 读取 9 个 INTEGER (version, n, e, d, p, q, dp, dq, qi)
  const integers: Uint8Array[] = [];
  for (let i = 0; i < 9; i++) {
    if (pkcs1Der[offset++] !== 0x02) throw new Error(`Expected INTEGER at position ${offset-1}`);
    let intLen = pkcs1Der[offset++];
    if (intLen & 0x80) {
      let lenBytes = intLen & 0x7F;
      intLen = 0;
      for (let j = 0; j < lenBytes; j++) {
        intLen = (intLen << 8) | pkcs1Der[offset++];
      }
    }
    integers.push(pkcs1Der.slice(offset, offset + intLen));
    offset += intLen;
  }
  
  return {
    n: integers[1], e: integers[2], d: integers[3],
    p: integers[4], q: integers[5], dp: integers[6], dq: integers[7], qi: integers[8]
  };
}

// 将 PKCS#1 转换为 PKCS#8
function convertPKCS1ToPKCS8(pkcs1Pem: string): Uint8Array {
  // 清理 PEM
  const base64 = pkcs1Pem
    .replace(/-----BEGIN (RSA )?PRIVATE KEY-----/g, '')
    .replace(/-----END (RSA )?PRIVATE KEY-----/g, '')
    .replace(/\s+/g, '');
  const pkcs1Der = Uint8Array.from(atob(base64), c => c.charCodeAt(0));
  
  // 解析 PKCS#1
  const key = parsePKCS1PrivateKey(pkcs1Der);
  
  // 构建 PKCS#8
  // PrivateKeyInfo ::= SEQUENCE {
  //   version Version,
  //   algorithm AlgorithmIdentifier,
  //   PrivateKey OCTET STRING
  // }
  
  // Version = INTEGER 0
  const version = encodeInteger(new Uint8Array([0]));
  
  // AlgorithmIdentifier for RSA: SEQUENCE { OID 1.2.840.113549.1.1.1, NULL }
  const rsaOid = new Uint8Array([0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01]);
  const nullParam = new Uint8Array([0x05, 0x00]);
  const algorithm = encodeSequence([rsaOid, nullParam]);
  
  // 重新构建 PKCS#1 内容作为 OCTET STRING
  const pkcs1Content = encodeSequence([
    encodeInteger(new Uint8Array([0])), // version
    encodeInteger(key.n),
    encodeInteger(key.e),
    encodeInteger(key.d),
    encodeInteger(key.p),
    encodeInteger(key.q),
    encodeInteger(key.dp),
    encodeInteger(key.dq),
    encodeInteger(key.qi)
  ]);
  const privateKey = encodeOctetString(pkcs1Content);
  
  return encodeSequence([version, algorithm, privateKey]);
}

// RSA2 签名（支持 PKCS#1 和 PKCS#8 格式）
async function signRSA2(data: string, privateKeyPem: string): Promise<string> {
  // 判断是否是 PKCS#1 格式
  const isPKCS1 = privateKeyPem.includes('BEGIN RSA PRIVATE KEY');
  
  let binaryKey: Uint8Array;
  if (isPKCS1) {
    // 转换 PKCS#1 到 PKCS#8
    binaryKey = convertPKCS1ToPKCS8(privateKeyPem);
  } else {
    // 直接使用 PKCS#8
    const pemContents = privateKeyPem
      .replace(/-----BEGIN PRIVATE KEY-----/g, '')
      .replace(/-----END PRIVATE KEY-----/g, '')
      .replace(/\s+/g, '');
    binaryKey = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));
  }
  
  const key = await crypto.subtle.importKey(
    'pkcs8', binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign']
  );
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(data));
  return btoa(String.fromCharCode(...new Uint8Array(signature)));
}

function generateOrderId(): string {
  const ts = Date.now().toString(36).toUpperCase();
  const rand = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `KM${ts}${rand}`;
}

function encodeAlipay(str: string): string {
  return encodeURIComponent(str).replace(/%20/g, '+');
}

Deno.serve(async (req: Request) => {
  // CORS 预检请求处理
  if (req.method === 'OPTIONS') {
    return new Response(null, { 
      status: 204, 
      headers: { 
        'Access-Control-Allow-Origin': '*', 
        'Access-Control-Allow-Methods': 'POST, OPTIONS', 
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey',
        'Access-Control-Max-Age': '86400',
      } 
    });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } });
  }

  // 验证请求（允许匿名访问，但检查基本格式）
  const authHeader = req.headers.get('Authorization') || req.headers.get('apikey');
  if (!authHeader) {
    console.log('Warning: No auth header provided, allowing anonymous request');
  }

  try {
    const { product, userId } = await req.json();

    if (!product || !PRODUCTS[product]) {
      return new Response(JSON.stringify({ error: 'Invalid product' }), { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } });
    }

    if (!ALIPAY_CONFIG.privateKey) {
      return new Response(JSON.stringify({ error: 'Server config error: missing ALIPAY_PRIVATE_KEY' }), { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } });
    }

    const prod = PRODUCTS[product];
    const outTradeNo = generateOrderId();
    const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);

    const bizContent = {
      out_trade_no: outTradeNo,
      total_amount: prod.price.toFixed(2),
      subject: prod.name,
      product_code: 'QUICK_MSECURITY_PAY',
    };

    const params: Record<string, string> = {
      app_id: ALIPAY_CONFIG.appId,
      method: 'alipay.trade.app.pay',
      format: 'JSON',
      charset: 'utf-8',
      sign_type: 'RSA2',
      timestamp,
      version: '1.0',
      notify_url: ALIPAY_CONFIG.notifyUrl,
      biz_content: JSON.stringify(bizContent),
    };

    const sortedKeys = Object.keys(params).sort();
    const signData = sortedKeys.map(k => `${k}=${params[k]}`).join('&');
    const sign = await signRSA2(signData, ALIPAY_CONFIG.privateKey);

    const orderStr = sortedKeys
      .map(k => `${k}=${encodeAlipay(params[k])}`)
      .join('&') + `&sign=${encodeAlipay(sign)}`;

    return new Response(JSON.stringify({
      success: true,
      outTradeNo,
      orderStr,
      product: product,
      productName: prod.name,
      amount: prod.price,
    }), { status: 200, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } });

  } catch (error) {
    console.error('Error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error', message: String(error) }), { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } });
  }
});
