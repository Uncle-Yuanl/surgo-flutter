#!/usr/bin/env python3
"""把白底图标抠成透明 PNG，并裁掉四周空白。

用于桌面 icon/logo.jpg → 开屏页 logo：原图是白底黑字的 JPEG，
直接贴到黄底上会出现白方块。

用法: python3 tool/logo_to_transparent.py <输入> <输出> [白阈值=245]
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
    assert bitd == 8 and meta[6] == 0, meta
    nch = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ct]
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


def encode(path, w, h, px):
    raw = bytearray()
    stride = w * 4
    for y in range(h):
        raw.append(0)
        raw += px[y * stride:(y + 1) * stride]

    def chunk(typ, body):
        return (struct.pack('>I', len(body)) + typ + body
                + struct.pack('>I', zlib.crc32(typ + body) & 0xffffffff))

    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
    png += chunk(b'IDAT', zlib.compress(bytes(raw), 9))
    png += chunk(b'IEND', b'')
    open(path, 'wb').write(png)


src, dst = sys.argv[1], sys.argv[2]
WHITE = int(sys.argv[3]) if len(sys.argv) > 3 else 245

w, h, nch, px = decode(src)
rgba = bytearray(w * h * 4)
for i in range(w * h):
    if nch >= 3:
        r, g, b = px[i * nch], px[i * nch + 1], px[i * nch + 2]
    else:
        r = g = b = px[i * nch]
    m = min(r, g, b)
    if m >= WHITE:
        a = 0
    elif m > WHITE - 30:
        a = int(255 * (WHITE - m) / 30)
    else:
        a = 255
    rgba[i * 4:i * 4 + 4] = bytes((r, g, b, a))

# 裁掉四周全透明的边，让 logo 紧贴内容边界，方便在布局里精确控制尺寸。
minx, miny, maxx, maxy = w, h, -1, -1
for y in range(h):
    for x in range(w):
        if rgba[(y * w + x) * 4 + 3] > 8:
            if x < minx:
                minx = x
            if x > maxx:
                maxx = x
            if y < miny:
                miny = y
            if y > maxy:
                maxy = y
cw, ch = maxx - minx + 1, maxy - miny + 1
crop = bytearray(cw * ch * 4)
for y in range(ch):
    s = ((y + miny) * w + minx) * 4
    crop[y * cw * 4:(y + 1) * cw * 4] = rgba[s:s + cw * 4]

encode(dst, cw, ch, bytes(crop))
opaque = sum(1 for i in range(cw * ch) if crop[i * 4 + 3] > 8)
print(f'{src} {w}x{h} -> {dst} {cw}x{ch}  不透明像素 {opaque} ({opaque * 100 // (cw * ch)}%)')
