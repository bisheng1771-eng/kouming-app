/**
 * 叩命后端服务
 * 职责：
 * 1. 支付宝 APP 支付 - RSA2 签名生成 orderStr
 * 2. 支付回调通知处理
 * 3. 数据存储（可选，简易版用文件存储）
 */

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const AlipaySdk = require('alipay-sdk').default;

// ============================================================
//  支付宝配置 - 请填写你的真实配置
// ============================================================
const ALIPAY_CONFIG = {
  appId: '2021006149691180',
  privateKey: `-----BEGIN RSA PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCiLpe4dMwL+wm3
ubmUKGUHAovg37Fo6WDiu+GLXZWce+ocpubdaYwAepgfbFHX9oGdDGG3TcKFmtW0W
IvVhjwGKSLXfUMSQI4Gtll1ldV1+bLy45lvdx4E37HT2dzzYWenVHYdYDTP4Qx+t
CEdBEf0a/Qf29Umj8XMBAWeaRL6Wunu9MPDsqjFCnd9kTv1Qt1IsXUpeGfAGuCfFS
ZaaImxwmGwE3yh37YJiazItednt9mrUP19EdCe1Ah3bM2q2U6YPTnuhHHCxUOlF05
csO2XoL9o8IlnygSOZvNF4XC3jO+YtebzOM2lpOrYRtWaoP0c41CskbqYAJR2/vC5
Xf35AgMBAAECggEAM8KTAXelN52i+FP5+mL5+0bAxcAeqtDw7uvvi78OZKbXjNVnk
PqCiBSYQE8dv8MYkrrE5O+YSXOlCK3J0xfISF8Qk52SrlyT92hzHKf5PHG4vvQMoB
pwJjYOVwKNFc/cePbny3BM6pt0lWt/tfcLz+I0Q4axfGEeS4JtGKWIPQYMcI0Iy3a
XyeBhfjwmV76tvwmvgKCGGpjaAkwQoOCqmY4o9cSB/u+rJOiE2DAHgFxhnK0W1HTe
PUtf6slxVATL1XMFPeAoMRNQa6WC2xWybxfbaskRqfP5mJ5+ZFNtrnXL1GlWNfGV
NwXxsSAtofyqku8oKyDhZc0+iH2pAGR/UQKBgQDcvF3482TXvd8KsFM3dXcJmmNv
/OxmSqmUQNpRDX0ZolZAAj6QHBFMTmOdj5Ci8GBNKuUvmBJeQreXo74A/NNWxwRA3
9GwPtocLR9c2/8ETt34ikP79axNxnFHV9HP5DRmk/BNXQxmZo5cTl7E/zb7uV7ap
62zSD/XlVrs/o/nwwKBgQC8F39TNC9sRGnnHXbApSNxZtVbdUw6s3wcTVBjRDB5e1
1p1/dkn3CVo5qnxFJcf+k5EJGOhjgn3l4tF4WG2SELIMr7Gki8s84nI34npIZ3mD1
7r/ZgEuwTjHmTaqLeV6LTNifsh6KyC+N8MODiHqRCHaIweJ0uJrGnnM3B2z7jkwKB
gGa8yaRAbLQ5bGGGNgU/B/uRPyz1dHYb1Bfro3FMLOjMdQZvxPzAA5EXfyfrlS8x
YDEqgOeJCSuUM+1BSgMdqaPfF2y2f9tfNZcdrVZEEsrHhmrSt9fCvcKpVToWdtIi7
fy8aIEpiMb0ftgZpeRcwROicLKmjqM+QnCt1FcwGHyPAoGBAK1XBks6o52maubIG4
Gsbr56o5PWxLqwYGeAxN3GoNnD3DHIC0FbQplVHhkQb0q5wsiJQWtUvHnZj3cE31
SH09D6lrXU4kWtewZMyl1kXVvoHHlZj7e4mIHnir9VneVEZFU76o0r7r8g/7ObJB
SfYodf4fHDpi87D6xFcMX/9LQrAoGBAKg3P1l+XcbUqOIQwSGRxcG5jWVQgIRiUC
ZGCzA5Qtdz9dRY71Yp2IA2eE5Mr6hq6HjyCnw13poP4BrrfAh+Pu2mG0LPj6tvj1T
PvlvfxqWXvXQUZ1qDFatK6+lLhgAXEs7sMdlNi7hgMDJtpnCJkxSOTKdnyxEyVFg
soTrm1TWE
-----END RSA PRIVATE KEY-----`,
  alipayPublicKey: `-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoi6XuHTMC/sJt7m5lChlB
wKL4N+xaOlg4rvhi12VnHvqHKbm3WmMAHqYH2xR1/aBnQxht03ChZrVtFiL1YY8Bk
i131DEkCOBrZZdZXVdfmy8uOZb3ceBN+x09nc82Fnp1R2HWA0z+EMfrQhHQRH9Gv0
H9vVJo/FzAQFnmkS+lrp7vTDw7KoxQp3fZE79ULdSLF1KXhnwBrgnxUmWmiJscJhsB
N8od+2CYmsyLXnZ7fZq1D9fRHQntQId2zNqtlOmD057oRxwsVDpRdOXLDtl6C/aPCJ
Z8oEjmbzReFwt4zvmLXm8zjNpaTq2EbVmqD9HONQrJG6mACUdv7wuV39+QIDAQAB
-----END PUBLIC KEY-----`,
  gateway: 'https://openapi.alipay.com/gateway.do',
  notifyUrl: 'https://YOUR_SERVER/api/alipay/notify',
};

// ============================================================
//  产品配置
// ============================================================
const PRODUCTS = {
  oracle: {
    name: '算卦解读',
    price: 6.0,
    description: '深渊池灵深度解读你的愿望',
  },
  fate: {
    name: '天命签',
    price: 6.0,
    description: '抽取专属天命签文',
  },
  fulfill: {
    name: '还愿仪式',
    price: 3.6,
    description: '向深渊还愿，感谢应验',
  },
};

const app = express();
app.use(cors());
app.use(bodyParser.json());

// ============================================================
//  辅助函数
// ============================================================

/** 生成商户订单号 */
function generateTradeNo() {
  const date = new Date();
  const prefix = date.toISOString().slice(0, 10).replace(/-/g, '');
  const uuid = uuidv4().replace(/-/g, '').toUpperCase();
  return `${prefix}${uuid}`.slice(0, 32);
}

/** 验证签名 */
function verifySign(params, sign) {
  const signType = params.sign_type || 'RSA2';
  const keys = Object.keys(params).filter(k => k !== 'sign' && k !== 'sign_type');
  keys.sort();
  const sortedParams = {};
  keys.forEach(k => sortedParams[k] = params[k]);

  const signContent = Object.entries(sortedParams)
    .map(([k, v]) => `${k}=${decodeURIComponent(v)}`)
    .join('&');

  let verify;
  if (signType === 'RSA2') {
    verify = crypto.createVerify('RSA-SHA256');
  } else {
    verify = crypto.createVerify('RSA-SHA1');
  }
  verify.update(signContent);
  return verify.verify(ALIPAY_CONFIG.alipayPublicKey, sign, 'base64');
}

// ============================================================
//  API: 生成支付宝订单签名
//  POST /api/alipay/order
// ============================================================
app.post('/api/alipay/order', async (req, res) => {
  try {
    const { subject, total_amount, out_trade_no, product_code = 'QUICK_MSECURITY_PAY' } = req.body;

    // 参数验证
    if (!subject || !total_amount || !out_trade_no) {
      return res.status(400).json({ success: false, error: '缺少必要参数' });
    }

    // 生成订单参数
    const bizContent = {
      out_trade_no,
      total_amount: String(total_amount),  // 必须是字符串
      subject,
      product_code,
      timeout_express: '30m',
      body: '叩命-深渊许愿池',
    };

    const params = {
      app_id: ALIPAY_CONFIG.appId,
      method: 'alipay.trade.app.pay',
      charset: 'utf-8',
      sign_type: 'RSA2',
      timestamp: new Date().toISOString().slice(0, 19).replace('T', ' '),
      version: '1.0',
      notify_url: ALIPAY_CONFIG.notifyUrl,
      biz_content: JSON.stringify(bizContent),
    };

    // 签名
    const keys = Object.keys(params).sort();
    const sortedParams = {};
    keys.forEach(k => sortedParams[k] = params[k]);

    const signContent = Object.entries(sortedParams)
      .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
      .join('&');

    const sign = crypto
      .createSign('RSA-SHA256')
      .update(signContent)
      .sign(ALIPAY_CONFIG.privateKey, 'base64');

    const orderStr = signContent + '&sign=' + encodeURIComponent(sign);

    console.log(`[订单生成] ${out_trade_no} - ${subject} - ¥${total_amount}`);

    res.json({
      success: true,
      order_str: orderStr,
      out_trade_no,
    });
  } catch (error) {
    console.error('[订单生成失败]', error);
    res.status(500).json({ success: false, error: '服务器错误' });
  }
});

// ============================================================
//  API: 支付宝异步回调通知
//  POST /api/alipay/notify
// ============================================================
app.post('/api/alipay/notify', (req, res) => {
  const params = req.body;

  console.log('[支付宝回调]', JSON.stringify(params, null, 2));

  // 验证签名
  if (!verifySign(params, params.sign)) {
    console.error('[签名验证失败]');
    return res.send('fail');
  }

  const tradeStatus = params.trade_status;

  if (tradeStatus === 'TRADE_SUCCESS' || tradeStatus === 'TRADE_FINISHED') {
    // 支付成功：更新订单状态
    const outTradeNo = params.out_trade_no;
    const totalAmount = params.total_amount;
    const buyerPayAmount = params.buyer_pay_amount;

    console.log(`[支付成功] ${outTradeNo} 实付¥${buyerPayAmount}`);

    // TODO: 在这里更新你的数据库（如 Supabase）
    // await supabase.from('orders').update({ status: 'paid' }).eq('trade_no', outTradeNo);

    res.send('success');
  } else {
    res.send('fail');
  }
});

// ============================================================
//  API: 订单状态查询（App 端轮询）
//  GET /api/alipay/query?out_trade_no=xxx
// ============================================================
app.get('/api/alipay/query', async (req, res) => {
  const { out_trade_no } = req.query;

  if (!out_trade_no) {
    return res.status(400).json({ error: '缺少订单号' });
  }

  try {
    const alipaySdk = new AlipaySdk({
      appId: ALIPAY_CONFIG.appId,
      privateKey: ALIPAY_CONFIG.privateKey,
      alipayPublicKey: ALIPAY_CONFIG.alipayPublicKey,
      gateway: ALIPAY_CONFIG.gateway,
    });

    const result = await alipaySdk.exec('alipay.trade.query', {
      bizContent: { out_trade_no },
    });

    res.json(result);
  } catch (error) {
    console.error('[查询失败]', error);
    res.status(500).json({ error: '查询失败' });
  }
});

// ============================================================
//  API: 健康检查
//  GET /api/health
// ============================================================
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'kouming-server', version: '1.0.0' });
});

// ============================================================
//  启动服务
// ============================================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`叩命后端服务启动: http://localhost:${PORT}`);
  console.log(`支付宝网关: ${ALIPAY_CONFIG.gateway}`);
  console.log(`回调地址: ${ALIPAY_CONFIG.notifyUrl}`);
});
