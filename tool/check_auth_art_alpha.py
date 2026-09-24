#!/usr/bin/env python3
"""检查登录注册插画四角像素：判断白底是图片自带，还是页面底色透出。

只读 assets/images/auth/*.png，不修改任何文件。
"""
import os
import sys
import zlib
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read_png_rgba(path):
    data = open(path, 'rb').read()
    pos, idat, meta = 8, b'', None
    while pos < len(data):
        ln = struct.unpack('>I', data[pos:pos + 4])[0]
        typ = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + ln]
        if typ == b'IHDR':
            w, h, bitd, ct, comp, filt, inter = struct.unpack('>IIBBBBB', body)
            meta = (w, h, bitd, ct, inter)
        elif typ == b'IDAT':
            idat += body
        elif typ == b'IEND':
            break
        pos += 12 + ln
    w, h, bitd, ct, inter = meta
    if ct != 6 or bitd != 8 or inter != 0:
        return None, meta
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
    return bytes(out), meta


for name in ['congrats', 'check_email', 'error', 'new_password']:
    path = os.path.join(ROOT, 'assets/images/auth', name + '.png')
    px, meta = read_png_rgba(path)
    w, h = meta[0], meta[1]
    if px is None:
        print(name, 'unsupported format', meta)
        continue
    def at(x, y):
        i = (y * w + x) * 4
        return tuple(px[i:i + 4])
    corners = {'TL': at(2, 2), 'TR': at(w - 3, 2), 'BL': at(2, h - 3), 'C': at(w // 2, 2)}
    print(f'{name:14s} {w}x{h}', {k: v for k, v in corners.items()})
