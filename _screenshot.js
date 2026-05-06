const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');

const CDP_PORT = process.argv[2] || 53116;
const OUTPUT = process.argv[3] || 'screenshots/homepage.png';
const WIDTH = parseInt(process.argv[4]) || 390;
const HEIGHT = parseInt(process.argv[5]) || 844;

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
    setTimeout(() => { ws.removeListener('message', handler); reject(new Error('timeout: ' + method)); }, 5000);
  });
}

async function main() {
  const wsUrl = await getWsUrl();
  console.log('Connecting:', wsUrl.substring(0, 80) + '...');

  const ws = new WebSocket(wsUrl);
  await new Promise((resolve, reject) => {
    ws.on('open', resolve);
    ws.on('error', reject);
  });

  try {
    await send(ws, 'Page.enable');
    await send(ws, 'Emulation.setDeviceMetricsOverride', {
      width: WIDTH, height: HEIGHT,
      deviceScaleFactor: 3, mobile: true
    });
    await new Promise(r => setTimeout(r, 1000));
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
