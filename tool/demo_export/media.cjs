// 只读取后端存下来的题图：库里内嵌的 base64，或者本机后端栈的文件存储（docker 容器 surgo-app）。
// 取出来的字节按库里记的 sha256 / 大小核对，对不上就报错；不转码，原样用。
const crypto = require('crypto');
const { execFileSync } = require('child_process');

// 后端本地存储的根目录（后端 src/services/storage.js）：scope 'user' 在 uploads/user-data/ 下，
// 'cache' 直接在 uploads/ 下。
const ROOTS = { user: '/app/uploads/user-data', cache: '/app/uploads' };
const PNG = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

function checked(buf, { sha256, size }, what) {
  if (size != null && buf.length !== Number(size)) throw new Error(`${what}: ${buf.length} bytes, the database row says ${size}`);
  if (sha256 && crypto.createHash('sha256').update(buf).digest('hex') !== sha256) throw new Error(`${what}: sha256 differs from the database row`);
  if (!buf.subarray(0, PNG.length).equals(PNG)) throw new Error(`${what}: not a PNG`);
  return buf;
}

/** 按 object_key 读一个存储对象，返回 Buffer（只读：docker exec … cat）。 */
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

/** 库里内嵌的图（阅读题的 media[].image：{ base64, sha256, … }），返回 Buffer。 */
const inline = (image, what) => checked(Buffer.from(image.base64, 'base64'), { sha256: image.sha256 }, what);

/**
 * 页面认的题图描述。图文件由模块以 Buffer 返回，导出时写进 demo_data/，构建时和 JSON 一起
 * 盖进 assets/data/；宽高是原图像素，页面按这个比例留位置。
 */
const figure = (name, { width, height, alt }) => ({ asset: `assets/data/${name}`, width, height, ...(alt ? { alt } : {}) });

module.exports = { stored, inline, figure };
