// 连拍页面加载后的若干帧，用来验证入场动效真的在播放。
// 只截终态看不出动效，必须抓中途帧。
// 用法: node tool/capture_anim.cjs <port> <route> <lang> <outDir> <帧间隔ms> <帧数>
const fs = require('fs'), path = require('path'), { spawn } = require('child_process');
const ROOT = path.resolve(__dirname, '..');
const [port, route, lang, outDir, stepMs, frames] = process.argv.slice(2);
const wait = ms => new Promise(r => setTimeout(r, ms));

async function main() {
  const profile = path.join(ROOT, 'artifacts/visual_audit/chrome-anim-' + Date.now());
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

  // 先让引擎把资源加载完，再重新挂载路由以触发一次干净的入场动画。
  await send('Page.navigate', { url: `http://127.0.0.1:${port}/?route=${route}&lang=${lang}` });
  await wait(5000);
  await send('Page.reload', { ignoreCache: false });

  const dir = path.join(ROOT, outDir);
  fs.mkdirSync(dir, { recursive: true });
  const n = Number(frames), step = Number(stepMs);
  for (let i = 0; i < n; i++) {
    await wait(step);
    const shot = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false, clip: { x: 0, y: 0, width: 390, height: 844, scale: 1 } });
    const f = path.join(dir, `f${String(i).padStart(2, '0')}.png`);
    fs.writeFileSync(f, Buffer.from(shot.data, 'base64'));
  }
  console.log(`wrote ${n} frames to ${outDir}`);
  ws.close(); child.kill('SIGKILL');
}
main().catch(e => { console.error(e); process.exit(1); });
