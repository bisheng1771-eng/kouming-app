// Supabase Edge Function: 生成支付宝订单 (无签名版本)
// 签名由 Flutter 端本地完成

const ALIPAY_CONFIG = {
  appId: '2021006149691180',
  gateway: 'https://openapi.alipay.com/gateway.do',
  notifyUrl: 'https://ibffrwevphkkbcfgaift.supabase.co/functions/v1/alipay-notify',
};

const PRODUCTS: Record<string, { name: string; price: number }> = {
  oracle:  { name: '算卦解读', price: 6.00 },
  fate:    { name: '天命签',   price: 6.00 },
  fulfill: { name: '还愿仪式', price: 3.60 },
  incense: { name: '微光',     price: 1.00 },
  lotus:   { name: '花灯',     price: 2.00 },
  river:   { name: '长明灯',   price: 3.00 },
};

function generateOrderId(): string {
  const ts = Date.now().toString(36).toUpperCase();
  const rand = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `KM${ts}${rand}`;
}

Deno.serve(async (req: Request) => {
  // CORS
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

  try {
    const { product, userId } = await req.json();

    if (!product || !PRODUCTS[product]) {
      return new Response(JSON.stringify({ error: 'Invalid product', products: Object.keys(PRODUCTS) }), { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } });
    }

    const prod = PRODUCTS[product];
    const outTradeNo = generateOrderId();
    const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);

    // 返回给 Flutter 的数据（不签名，Flutter 本地签名）
    const orderData = {
      app_id: ALIPAY_CONFIG.appId,
      method: 'alipay.trade.app.pay',
      format: 'JSON',
      charset: 'utf-8',
      sign_type: 'RSA2',
      timestamp,
      version: '1.0',
      notify_url: ALIPAY_CONFIG.notifyUrl,
      biz_content: JSON.stringify({
        out_trade_no: outTradeNo,
        total_amount: prod.price.toFixed(2),
        subject: prod.name,
        product_code: 'QUICK_MSECURITY_PAY',
      }),
    };

    return new Response(JSON.stringify({
      success: true,
      outTradeNo,
      orderData,  // Flutter 用这个做签名
      product: product,
      productName: prod.name,
      amount: prod.price,
    }), { status: 200, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } });

  } catch (error) {
    console.error('Error:', error);
    return new Response(JSON.stringify({
      error: 'Internal server error',
      message: String(error),
    }), { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } });
  }
});
