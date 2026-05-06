const WebSocket = require('ws');
const fs = require('fs');

const CDP_PORT = process.argv[2] || 53116;
const OUTPUT = process.argv[3] || 'screenshots/shop.png';

async function getWsUrl() {
  return new Promise((resolve, reject) => {
    const http = require('http');
    http.get(`http://127.0.0.1:${CDP_PORT}/json`, r => {
      let d = '';
      r.on('data', c => d += c);
      r.on('end', () => {
        const tabs = JSON.parse(d);
        const target = tabs.find(t => t.url.includes('localhost:8080') && t.type === 'page');
        if (target) resolve(target.webSocketDebuggerUrl);
        else reject(new Error('No target page found'));
      });
    }).on('error', reject);
  });
}

let msgId = 1;
function send(ws, method, params) {
  return new Promise((resolve, reject) => {
    const id = msgId++;
    const handler = (data) => {
      const msg = JSON.parse(data.toString());
      if (msg.id === id) {
        ws.removeListener('message', handler);
        if (msg.error) reject(new Error(JSON.stringify(msg.error)));
        else resolve(msg.result);
      }
    };
    ws.on('message', handler);
    ws.send(JSON.stringify({ id, method, params: params || {} }));
    setTimeout(() => { ws.removeListener('message', handler); reject(new Error('timeout: ' + method)); }, 8000);
  });
}

async function main() {
  const wsUrl = await getWsUrl();
  console.log('Connecting...');
  const ws = new WebSocket(wsUrl);
  await new Promise((resolve, reject) => { ws.on('open', resolve); ws.on('error', reject); });

  try {
    await send(ws, 'Page.enable');
    // Use CSS pixels (no override needed - use default viewport)
    await send(ws, 'Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 1, mobile: true });

    // Flutter web renders in a canvas element
    // The canvas fills the viewport, and Flutter handles its own coordinate system
    // With deviceScaleFactor=1, the viewport is 390x844 CSS pixels
    // Bottom nav bar "供奉" is the rightmost of 3 tabs
    
    // Try clicking with dispatchTouchEvent for mobile simulation
    // Shop tab position: ~292px from left (3rd of 3), ~815px from top (bottom nav)
    
    // First try touch event (more reliable for Flutter web)
    console.log('Dispatching touch event at (292, 815)...');
    await send(ws, 'Input.dispatchTouchEvent', {
      type: 'touchStart',
      touchPoints: [{ x: 292, y: 815 }]
    });
    await new Promise(r => setTimeout(r, 100));
    await send(ws, 'Input.dispatchTouchEvent', {
      type: 'touchEnd',
      touchPoints: [{ x: 292, y: 815 }]
    });
    await new Promise(r => setTimeout(r, 2000));

    const result = await send(ws, 'Page.captureScreenshot', { format: 'png' });
    const buf = Buffer.from(result.data, 'base64');
    fs.writeFileSync(OUTPUT, buf);
    console.log('Saved:', OUTPUT, '(' + buf.length + ' bytes)');
  } catch (e) {
    console.error('Error:', e.message);
  }

  ws.close();
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
