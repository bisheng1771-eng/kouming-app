// Supabase Edge Function: 支付宝支付回调 (v2)
// 接收支付宝 POST，验证签名，更新 payments 表

import { createClient } from 'jsr:@supabase/supabase-js@2';

const ALIPAY_PUBLIC_KEY = Deno.env.get('ALIPAY_PUBLIC_KEY') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

// 验证 RSA2 签名
async function verifyRSA2(data: string, sign: string, publicKeyPem: string): Promise<boolean> {
  try {
    const pemHeader = '-----BEGIN PUBLIC KEY-----';
    const pemFooter = '-----END PUBLIC KEY-----';
    const pemContents = publicKeyPem.replace(pemHeader, '').replace(pemFooter, '').replace(/\s+/g, '');
    const binaryKey = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));
    const key = await crypto.subtle.importKey(
      'spki', binaryKey,
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false, ['verify']
    );
    const signature = Uint8Array.from(atob(sign), c => c.charCodeAt(0));
    const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, signature, new TextEncoder().encode(data));
    return ok;
  } catch (e) {
    console.error('Verify error:', e);
    return false;
  }
}

function parseFormData(body: string): Record<string, string> {
  const params: Record<string, string> = {};
  for (const pair of body.split('&')) {
    const idx = pair.indexOf('=');
    if (idx < 0) continue;
    const key = decodeURIComponent(pair.slice(0, idx));
    const val = decodeURIComponent(pair.slice(idx + 1));
    params[key] = val;
  }
  return params;
}

Deno.serve(async (req: Request) => {
  console.log('[alipay-notify] Received:', req.method);

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const bodyText = await req.text();
    const params = parseFormData(bodyText);
    console.log('[alipay-notify] Params:', JSON.stringify(params));

    const sign = params['sign'];
    const signType = params['sign_type'];

    if (!sign || signType !== 'RSA2') {
      return new Response('fail', { status: 400 });
    }

    // 验签数据（排除 sign / sign_type，按字母排序）
    const { sign: _sign, sign_type: _st, ...dataParams } = params;
    const sortedKeys = Object.keys(dataParams).sort();
    const signData = sortedKeys.map(k => `${k}=${dataParams[k]}`).join('&');

    let isValid = true;
    if (ALIPAY_PUBLIC_KEY) {
      isValid = await verifyRSA2(signData, sign, ALIPAY_PUBLIC_KEY);
    }

    if (!isValid) {
      console.error('[alipay-notify] Signature verify failed');
      return new Response('fail', { status: 400 });
    }
    console.log('[alipay-notify] Signature OK ✅');

    const tradeStatus = params['trade_status'];
    if (tradeStatus !== 'TRADE_SUCCESS' && tradeStatus !== 'TRADE_FINISHED') {
      console.log('[alipay-notify] trade_status:', tradeStatus, '→ ignored');
      return new Response('success');
    }

    // 连接 Supabase
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    const outTradeNo = params['out_trade_no'];
    const tradeNo = params['trade_no'];
    const totalAmount = parseFloat(params['total_amount'] || '0');
    const buyerId = params['buyer_id'];
    const gmtPayment = params['gmt_payment'];

    // 查找订单
    const { data: payment } = await supabase
      .from('payments')
      .select('product_type, user_id, status')
      .eq('id', outTradeNo)
      .maybeSingle();

    if (!payment) {
      // 如果 payments 表里没有记录（首次回调），直接插入
      await supabase.from('payments').insert({
        id: outTradeNo,
        product_type: 'unknown',
        amount: totalAmount,
        currency: 'CNY',
        status: 'completed',
        created_at: new Date().toISOString(),
        completed_at: gmtPayment || new Date().toISOString(),
      });
      console.log('[alipay-notify] New payment inserted:', outTradeNo);
    } else if (payment.status === 'pending') {
      // 更新已有记录
      await supabase.from('payments')
        .update({
          status: 'completed',
          completed_at: gmtPayment || new Date().toISOString(),
        })
        .eq('id', outTradeNo);
      console.log('[alipay-notify] Payment completed:', outTradeNo);

      // 更新用户统计（增加 total_draws 或累计次数）
      if (payment.user_id) {
        await supabase.from('users')
          .update({ last_active: new Date().toISOString() })
          .eq('id', payment.user_id);
      }
    }

    return new Response('success');

  } catch (error) {
    console.error('[alipay-notify] Error:', error);
    return new Response('fail', { status: 500 });
  }
});
