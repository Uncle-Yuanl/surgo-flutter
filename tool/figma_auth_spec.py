#!/usr/bin/env python3
"""从 Figma 节点树里抽出 13 个登录注册页的结构（文案 / 字号 / 颜色 / 位置 / 圆角）。

只读 artifacts/figma_auth/page5.json，输出一份便于照着写 Dart 的清单。
用法: python3 tool/figma_auth_spec.py [frame_name_substring]
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = json.load(open(os.path.join(ROOT, 'artifacts/figma_auth/page5.json'), encoding='utf-8'))
PAGE = DATA['nodes']['40:106']['document']


def hexof(paints):
    for p in paints or []:
        if p.get('type') == 'SOLID' and p.get('visible', True):
            c = p['color']
            a = p.get('opacity', c.get('a', 1))
            r, g, b = (round(c[k] * 255) for k in ('r', 'g', 'b'))
            return f'#{r:02x}{g:02x}{b:02x}' + ('' if a >= .999 else f'@{a:.2f}')
    return None


def walk(node, origin, depth, out):
    bb = node.get('absoluteBoundingBox') or {}
    x = round(bb.get('x', 0) - origin[0]) if bb else 0
    y = round(bb.get('y', 0) - origin[1]) if bb else 0
    w, h = round(bb.get('width', 0)), round(bb.get('height', 0))
    kind = node['type']
    bits = [f'{"  " * depth}{kind} "{node.get("name", "")}"', f'@{x},{y} {w}x{h}']
    if kind == 'TEXT':
        st = node.get('style', {})
        bits.append(f'text={node.get("characters", "")!r}')
        bits.append(f'font={st.get("fontFamily")} {st.get("fontWeight")} {st.get("fontSize")}')
        if st.get('lineHeightPx'):
            bits.append(f'lh={round(st["lineHeightPx"], 1)}')
        if st.get('textAlignHorizontal'):
            bits.append(f'align={st["textAlignHorizontal"]}')
    fill = hexof(node.get('fills'))
    if fill:
        bits.append(f'fill={fill}')
    stroke = hexof(node.get('strokes'))
    if stroke:
        bits.append(f'stroke={stroke}/{node.get("strokeWeight")}')
    if node.get('cornerRadius'):
        bits.append(f'r={node["cornerRadius"]}')
    elif node.get('rectangleCornerRadii'):
        bits.append(f'r={node["rectangleCornerRadii"]}')
    out.append('  '.join(bits))
    for kid in node.get('children', []) or []:
        walk(kid, origin, depth + 1, out)


want = sys.argv[1] if len(sys.argv) > 1 else None
for frame in PAGE.get('children', []):
    name = frame.get('name', '')
    if want and want.lower() not in name.lower():
        continue
    bb = frame.get('absoluteBoundingBox') or {}
    origin = (bb.get('x', 0), bb.get('y', 0))
    print('=' * 70)
    print(f'FRAME {frame["id"]}  "{name}"  {round(bb.get("width", 0))}x{round(bb.get("height", 0))}')
    out = []
    for kid in frame.get('children', []) or []:
        walk(kid, origin, 1, out)
    print('\n'.join(out))
