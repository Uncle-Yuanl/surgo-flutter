// 打开指定路由，点一下答题卡入口，再截图 —— 用来核对「答题卡弹窗全局统一为图2」。
// 用法: node tool/capture_answer_sheet.cjs <port> <route> <lang> <x> <y> <outPng> [scrollY]
const fs = require('fs'), path = require('path'), { spawn } = require('child_process');
const ROOT = path.resolve(__dirname, '..');
const [port, route, lang, cx, cy, out, scrollY] = process.argv.slice(2);
const wait = ms => new Promise(r => setTimeout(r, ms));

async function main() {
  const profile = path.join(ROOT, 'artifacts/visual_audit/chrome-sheet-' + Date.now());
  fs.mkdirSync(profile, { recursive: true });
  const child = spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', [
    '--headless=new', '--remote-debugging-port=0', '--no-first-run', '--no-default-browser-check',
    '--user-data-dir=' + profile, '--window-size=390,844', '--force-device-scale-factor=1',
    '--hide-scrollbars', 'about:blank',
  ], { stdio: ['ignore', 'pipe', 'pipe'] });
  const portfile = path.join(profile, 'DevToolsActivePort');
  for (let i = 0; i < 200 && !fs.existsSync(portfile); i++) await wait(100);
  const dp = fs.readFileSync(portfile, 'utf8').split('\n')[0];
  const target = await (await fetch(`http://127.0.0.1:${dp}/json/new?about:blank`, { method: 'PUT' })).json();
  const WebSocket = globalThis.WebSocket;
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej; });
  let id = 0; const pending = new Map();
  ws.onmessage = e => {
    const m = JSON.parse(e.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  };
  const send = (method, params = {}) => new Promise((res, rej) => {
    const n = ++id; pending.set(n, m => m.error ? rej(Error(method + ': ' + m.error.message)) : res(m.result));
    ws.send(JSON.stringify({ id: n, method, params }));
  });
  await send('Page.enable'); await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 1, mobile: true });
  await send('Page.navigate', { url: `http://127.0.0.1:${port}/?route=${route}&lang=${lang}` });
  await wait(4500);
  if (scrollY) {
    for (let i = 0; i < 4; i++) {
      await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 195, y: 600, deltaX: 0, deltaY: Number(scrollY) / 4 });
      await wait(120);
    }
  }
  await send('Input.dispatchMouseEvent', { type: 'mousePressed', button: 'left', clickCount: 1, x: Number(cx), y: Number(cy) });
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', button: 'left', clickCount: 1, x: Number(cx), y: Number(cy) });
  await wait(900);
  const shot = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false, clip: { x: 0, y: 0, width: 390, height: 844, scale: 1 } });
  fs.mkdirSync(path.dirname(path.join(ROOT, out)), { recursive: true });
  fs.writeFileSync(path.join(ROOT, out), Buffer.from(shot.data, 'base64'));
  console.log('wrote', out);
  ws.close(); child.kill('SIGKILL');
}
main().catch(e => { console.error(e); process.exit(1); });
