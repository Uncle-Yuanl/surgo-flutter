// 只读取后端存下来的题图和音频：库里内嵌的 base64，或者本机后端栈的文件存储（docker 容器 surgo-app）。
// 取出来的字节按库里记的 sha256 / 大小核对，对不上就报错；核对过，图再缩成网页用的大小，录音转成 MP3。
const crypto = require('crypto');
const { execFileSync } = require('child_process');

// 原图是 2048×1536 的 PNG（约 2.5 MB），手机页面最宽只画 350 多像素：缩到 1200 宽、转成 JPEG，
// 一张一两百 KB，国内打开才不用等。用 python + Pillow（tool/ 下的脚本本来就依赖它）。
const SHRINK = `
import io, sys
from PIL import Image
im = Image.open(io.BytesIO(sys.stdin.buffer.read())).convert('RGB')
if im.width > 1200:
    im = im.resize((1200, round(im.height * 1200 / im.width)), Image.LANCZOS)
out = io.BytesIO()
im.save(out, 'JPEG', quality=85, optimize=True)
sys.stdout.buffer.write(out.getvalue())
`;
function shrink(buf, what) {
  try {
    return execFileSync('python', ['-c', SHRINK], { input: buf, encoding: 'buffer', maxBuffer: 64 << 20, stdio: ['pipe', 'pipe', 'pipe'] });
  } catch {
    throw new Error(`${what}: cannot shrink the figure (needs python with Pillow on PATH)`);
  }
}

// 后端本地存储的根目录（后端 src/services/storage.js）：scope 'user' 在 uploads/user-data/ 下，
// 'cache' 直接在 uploads/ 下。
const ROOTS = { user: '/app/uploads/user-data', cache: '/app/uploads' };
const PNG = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

function matches(buf, { sha256, size }, what) {
  if (size != null && buf.length !== Number(size)) throw new Error(`${what}: ${buf.length} bytes, the database row says ${size}`);
  if (sha256 && crypto.createHash('sha256').update(buf).digest('hex') !== sha256) throw new Error(`${what}: sha256 differs from the database row`);
  return buf;
}

function checked(buf, row, what) {
  if (!matches(buf, row, what).subarray(0, PNG.length).equals(PNG)) throw new Error(`${what}: not a PNG`);
  return shrink(buf, what);
}

/** 按 object_key 读一个存储对象的原始字节（只读：docker exec … cat），按库里记的 sha256 / 大小核对。 */
function object({ scope, key, sha256, size }, what) {
  if (!ROOTS[scope] || key.split('/').includes('..')) throw new Error(`${what}: unexpected storage location`);
  let buf;
  try {
    buf = execFileSync('docker', ['exec', 'surgo-app', 'cat', `${ROOTS[scope]}/${key}`], { encoding: 'buffer', maxBuffer: 64 << 20, stdio: ['ignore', 'pipe', 'pipe'] });
  } catch {
    // 对象键里带着用户和场次的 id，报错只写文件名。
    throw new Error(`${what}: cannot read ${key.split('/').pop()} from the surgo-app container's storage`);
  }
  return matches(buf, { sha256, size }, what);
}

/** 按 object_key 读一张存着的题图，返回缩好的 JPEG。 */
const stored = (row, what) => checked(object(row, what), {}, what);

/** 库里内嵌的图（阅读题的 media[].image：{ base64, sha256, … }），返回缩好的 JPEG。 */
const inline = (image, what) => checked(Buffer.from(image.base64, 'base64'), { sha256: image.sha256 }, what);

// ---------- 音频 ----------

/**
 * 后端按内容寻址缓存的朗读音频（uploads/tts/<sha256>.mp3，后端 src/speech/azureTts.js 的 buildCacheIdentity）：
 * 一个人读的是「音色、换行、原文」的 sha256，多人对话是「dialogue-v1、换行、音色+音色、换行、原文」的。
 * 库里不记这份音频，文件名本身就是「这个音色读这段原文」的凭据；缓存里没有就报错。
 */
function spoken(text, voices, what) {
  const input = (voices.length > 1 ? ['dialogue-v1', voices.join('+'), text] : [voices[0], text]).join('\n');
  return object({ scope: 'cache', key: `tts/${crypto.createHash('sha256').update(input).digest('hex')}.mp3` }, what);
}

function ffmpeg(args, input, what) {
  // ffmpeg 把进度和文件信息写在 stderr，正常结束也有内容，所以两路都收。
  const run = require('child_process').spawnSync('ffmpeg', ['-hide_banner', '-nostdin', ...args], { input, maxBuffer: 64 << 20 });
  // 只看退出码：截取一段时 ffmpeg 读够了就关掉输入，node 会记一个写管道的错，那不是失败。
  if (run.status !== 0) throw new Error(`${what}: ffmpeg failed (needs ffmpeg on PATH): ${run.error ? run.error.message : String(run.stderr).trim().split('\n').pop()}`);
  return run;
}

/**
 * 导出一段音频：返回 { bytes: MP3 字节, sec: 时长（秒，保留一位小数） }。
 * 后端存的听力 / 考官音频本来就是 MP3，原样带走；学员的录音是 WAV，转成单声道 48 kbps 的 MP3
 * （一分钟约 360 KB，原始 WAV 约 1.9 MB）。cut: { fromMs, toMs } 只取其中一段（整场录音里的一轮作答）。
 * 时长是把成品从头解码一遍量出来的：页面的进度条和放不出声时的空走都按它。
 */
function audio(buf, what, { cut } = {}) {
  const mp3 = buf.subarray(0, 3).toString('latin1') === 'ID3' || (buf[0] === 0xff && (buf[1] & 0xe0) === 0xe0);
  const wav = buf.subarray(0, 4).toString('latin1') === 'RIFF' && buf.subarray(8, 12).toString('latin1') === 'WAVE';
  if (!mp3 && !wav) throw new Error(`${what}: neither MP3 nor WAV`);
  const span = cut ? ['-ss', String(cut.fromMs / 1000), '-to', String(cut.toMs / 1000)] : [];
  const bytes = mp3 && !cut ? buf
    : ffmpeg(['-loglevel', 'error', '-i', 'pipe:0', ...span, '-vn', '-ac', '1', '-b:a', '48k', '-f', 'mp3', 'pipe:1'], buf, what).stdout;
  const times = [...String(ffmpeg(['-i', 'pipe:0', '-f', 'null', '-'], bytes, what).stderr).matchAll(/time=(\d+):(\d+):(\d+(?:\.\d+)?)/g)];
  if (!bytes.length || !times.length) throw new Error(`${what}: no audio came out`);
  const [, h, m, sec] = times[times.length - 1];
  return { bytes, sec: Math.round((Number(h) * 3600 + Number(m) * 60 + Number(sec)) * 10) / 10 };
}

/** 页面认的音频描述（和 figure 一样，文件由模块以 Buffer 返回）：{ asset, sec }。 */
const clip = (name, sec) => ({ asset: `assets/data/${name}`, sec });

/**
 * 页面认的题图描述。图文件由模块以 Buffer 返回，导出时写进 demo_data/，构建时和 JSON 一起
 * 盖进 assets/data/；宽高是原图像素，页面按这个比例留位置。
 */
const figure = (name, { width, height, alt }) => ({ asset: `assets/data/${name}`, width, height, ...(alt ? { alt } : {}) });

module.exports = { stored, inline, figure, object, spoken, audio, clip };
