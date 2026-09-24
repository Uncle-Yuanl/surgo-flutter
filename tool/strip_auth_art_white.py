#!/usr/bin/env python3
"""把登录注册插画的不透明白底转为透明。

Figma 导出的位图自带纯白底（alpha 255），贴到暖白页面上会出现白方块；
设计稿里这些插画是直接融在底色上的。这里把接近白的像素 alpha 置 0，
并对边缘做一档柔化，避免出现硬锯齿。

只处理 assets/images/auth/*.png，原图先备份到 artifacts/figma_auth/。
用法: python3 tool/strip_auth_art_white.py
"""
import os
import shutil
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'assets/images/auth')
BAK = os.path.join(ROOT, 'artifacts/figma_auth/original_art')

# 亮度高于该值视为背景白；低于则保留。留出容差，因为导出有 253~255 的抖动。
WHITE = 250


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
    w, h, bitd, ct, comp, filt, inter = meta
    assert ct == 6 and bitd == 8 and inter == 0, (path, meta)
    raw = zlib.decompress(idat)
    stride = w * 4
    out = bytearray(h * stride)
    prev = bytearray(stride)
    p = 0
    for y in range(h):
        ft = raw[p]
        p += 1
        line = bytearray(raw[p:p + stride])
        p += stride
        if ft == 1:
            for i in range(4, stride):
                line[i] = (line[i] + line[i - 4]) & 0xff
        elif ft == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xff
        elif ft == 3:
            for i in range(stride):
                a = line[i - 4] if i >= 4 else 0
                line[i] = (line[i] + ((a + prev[i]) >> 1)) & 0xff
        elif ft == 4:
            for i in range(stride):
                a = line[i - 4] if i >= 4 else 0
                b = prev[i]
                c = prev[i - 4] if i >= 4 else 0
                pp = a + b - c
                pa, pb, pc = abs(pp - a), abs(pp - b), abs(pp - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xff
        out[y * stride:(y + 1) * stride] = line
        prev = line
    return w, h, out


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


os.makedirs(BAK, exist_ok=True)
for name in ['congrats', 'check_email', 'error', 'new_password']:
    path = os.path.join(SRC, name + '.png')
    if not os.path.exists(os.path.join(BAK, name + '.png')):
        shutil.copy2(path, os.path.join(BAK, name + '.png'))
    w, h, px = decode(path)
    cleared = 0
    for i in range(0, len(px), 4):
        r, g, b = px[i], px[i + 1], px[i + 2]
        m = min(r, g, b)
        if m >= WHITE:
            px[i + 3] = 0
            cleared += 1
        elif m > WHITE - 24:
            # 边缘过渡：越接近白越透明，消除锯齿。
            px[i + 3] = int(255 * (WHITE - m) / 24)
    encode(path, w, h, px)
    total = w * h
    print(f'{name:14s} {w}x{h}  透明像素 {cleared}/{total} ({cleared * 100 // total}%)')
