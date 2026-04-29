// 测试 Secrets 读取
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

serve(async (req) => {
  const rawKey = Deno.env.get('ALIPAY_PRIVATE_KEY') || '';
  
  // 返回密钥的诊断信息（隐藏敏感内容）
  const diagnostics = {
    length: rawKey.length,
    hasBeginMarker: rawKey.includes('BEGIN'),
    hasEndMarker: rawKey.includes('END'),
    newlineCount: (rawKey.match(/\n/g) || []).length,
    backslashNCount: (rawKey.match(/\\n/g) || []).length,
    startsWithQuote: rawKey.startsWith('"') || rawKey.startsWith("'"),
    endsWithQuote: rawKey.endsWith('"') || rawKey.endsWith("'"),
    first50Chars: rawKey.substring(0, 50).replace(/\n/g, '\\n'),
    last50Chars: rawKey.substring(rawKey.length - 50).replace(/\n/g, '\\n'),
  };

  return new Response(JSON.stringify(diagnostics), {
    headers: { 'Content-Type': 'application/json' },
  });
});
