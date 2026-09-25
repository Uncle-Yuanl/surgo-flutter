#!/usr/bin/env python3
"""测量开屏页截图里白色 logo 的垂直位置，用来验证「上移 50px」是否真的生效。

判定依据：logo 是纯白（255,255,255）且带黑色模糊投影，插画里没有同样的大面积纯白块。
按行统计接近纯白的像素数，取连续白行区间的上下边界与中心。

用法: python3 tool/measure_logo_y.py <png> [<png> ...]
"""
import struct
import sys
import zlib


def decode(path):
    data = open(path, 'rb').read()
    pos, idat, meta = 8, b'', None
    while pos < len(data):
        ln = struct.unpack('>I', data[pos:pos + 4])[0]
        typ = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + ln]
        if typ == b'IHDR':
            meta = struct.unpack('>IIBBBBB', body)
        elif typ == b'IDAT':
            idat += body
        elif typ == b'IEND':
            break
        pos += 12 + ln
    w, h, bitd, ct = meta[0], meta[1], meta[2], meta[3]
    nch = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ct]
    assert bitd == 8 and meta[6] == 0, (path, meta)
    raw = zlib.decompress(idat)
    stride = w * nch
    out = bytearray(h * stride)
    prev = bytearray(stride)
    p = 0
    for y in range(h):
        ft = raw[p]
        p += 1
        line = bytearray(raw[p:p + stride])
        p += stride
        if ft == 1:
            for i in range(nch, stride):
                line[i] = (line[i] + line[i - nch]) & 0xff
        elif ft == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xff
        elif ft == 3:
            for i in range(stride):
                a = line[i - nch] if i >= nch else 0
                line[i] = (line[i] + ((a + prev[i]) >> 1)) & 0xff
        elif ft == 4:
            for i in range(stride):
                a = line[i - nch] if i >= nch else 0
                b = prev[i]
                c = prev[i - nch] if i >= nch else 0
                pp = a + b - c
                pa, pb, pc = abs(pp - a), abs(pp - b), abs(pp - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xff
        out[y * stride:(y + 1) * stride] = line
        prev = line
    return w, h, nch, bytes(out)


# logo 只占画面中间一条竖带，限制 x 范围避免把插画里的白墙、云朵算进来。
for path in sys.argv[1:]:
    w, h, nch, px = decode(path)
    x0, x1 = int(w * 0.30), int(w * 0.70)
    rows = []
    for y in range(h):
        n = 0
        for x in range(x0, x1):
            i = (y * w + x) * nch
            r, g, b = px[i], px[i + 1], px[i + 2]
            if r >= 250 and g >= 250 and b >= 250:
                n += 1
        rows.append(n)
    # 纯白像素明显成片的行才算 logo 行
    thr = 12
    hits = [y for y, n in enumerate(rows) if n >= thr]
    if not hits:
        print(f'{path}: 未检出纯白 logo 行（阈值 {thr}）')
        continue
    top, bot = hits[0], hits[-1]
    peak = max(range(h), key=lambda y: rows[y])
    print(f'{path.split("/")[-1]:24s} 画面 {w}x{h}  '
          f'logo 白行 top={top} bottom={bot} 中心={(top + bot) // 2} '
          f'最密行={peak}({rows[peak]}px)')
