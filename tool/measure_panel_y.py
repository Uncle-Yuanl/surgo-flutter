#!/usr/bin/env python3
"""测量欢迎页面板（#fcf8f5 圆角白块）顶边在每一帧的 y 位置。

用来证明「从下往上升」的动效真的在播放：顶边应从画面底部逐帧上移到终位。

用法: python3 tool/measure_panel_y.py <帧目录>
"""
import os
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


# 面板底色 #fcf8f5：判定一行是否几乎整宽都是该色。
TARGET = (0xfc, 0xf8, 0xf5)
TOL = 6

d = sys.argv[1]
for name in sorted(os.listdir(d)):
    if not name.endswith('.png'):
        continue
    path = os.path.join(d, name)
    w, h, nch, px = decode(path)
    top = None
    for y in range(h):
        hit = 0
        for x in range(0, w, 4):
            i = (y * w + x) * nch
            if (abs(px[i] - TARGET[0]) <= TOL and abs(px[i + 1] - TARGET[1]) <= TOL
                    and abs(px[i + 2] - TARGET[2]) <= TOL):
                hit += 1
        if hit > (w // 4) * 0.88:
            top = y
            break
    print(f'{name}  面板顶边 y={top if top is not None else "未检出"}')
