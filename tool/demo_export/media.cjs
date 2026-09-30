// 只读取后端存下来的题图：库里内嵌的 base64，或者本机后端栈的文件存储（docker 容器 surgo-app）。
// 取出来的字节按库里记的 sha256 / 大小核对，对不上就报错；核对过再缩成网页用的大小。
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

function checked(buf, { sha256, size }, what) {
  if (size != null && buf.length !== Number(size)) throw new Error(`${what}: ${buf.length} bytes, the database row says ${size}`);
  if (sha256 && crypto.createHash('sha256').update(buf).digest('hex') !== sha256) throw new Error(`${what}: sha256 differs from the database row`);
  if (!buf.subarray(0, PNG.length).equals(PNG)) throw new Error(`${what}: not a PNG`);
  return shrink(buf, what);
}

/** 按 object_key 读一个存储对象，返回缩好的 JPEG（只读：docker exec … cat）。 */
function stored({ scope, key, sha256, size }, what) {
  if (!ROOTS[scope] || key.split('/').includes('..')) throw new Error(`${what}: unexpected storage location`);
  let buf;
  try {
    buf = execFileSync('docker', ['exec', 'surgo-app', 'cat', `${ROOTS[scope]}/${key}`], { encoding: 'buffer', maxBuffer: 64 << 20, stdio: ['ignore', 'pipe', 'pipe'] });
  } catch {
    // 对象键里带着用户和场次的 id，报错只写文件名。
    throw new Error(`${what}: cannot read ${key.split('/').pop()} from the surgo-app container's storage`);
  }
  return checked(buf, { sha256, size }, what);
}

/** 库里内嵌的图（阅读题的 media[].image：{ base64, sha256, … }），返回缩好的 JPEG。 */
const inline = (image, what) => checked(Buffer.from(image.base64, 'base64'), { sha256: image.sha256 }, what);

/**
 * 页面认的题图描述。图文件由模块以 Buffer 返回，导出时写进 demo_data/，构建时和 JSON 一起
 * 盖进 assets/data/；宽高是原图像素，页面按这个比例留位置。
 */
const figure = (name, { width, height, alt }) => ({ asset: `assets/data/${name}`, width, height, ...(alt ? { alt } : {}) });

module.exports = { stored, inline, figure };
