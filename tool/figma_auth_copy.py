#!/usr/bin/env python3
"""只列出 13 个页面的可见文案 + 按钮 + 输入框，忽略 mockup 键盘与状态栏图层。

用法: python3 tool/figma_auth_copy.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = json.load(open(os.path.join(ROOT, 'artifacts/figma_auth/page5.json'), encoding='utf-8'))
PAGE = DATA['nodes']['40:106']['document']

# 设计稿里贴了 iOS 键盘与状态栏的 mockup 图层，不属于要实现的界面。
SKIP = ('Alphanumberic', 'Numberic', 'iPhone X - 11', 'Status Bar', 'Home Indicator',
        'Keyboard', 'StatusBar')


def texts(node, acc, skip_depth=False):
    name = node.get('name', '')
    if any(s.lower() in name.lower() for s in SKIP):
        return
    if node['type'] == 'TEXT':
        ch = (node.get('characters') or '').strip()
        if ch:
            bb = node.get('absoluteBoundingBox') or {}
            st = node.get('style', {})
            acc.append((round(bb.get('y', 0)), ch, st.get('fontSize'), st.get('fontWeight')))
    for kid in node.get('children') or []:
        texts(kid, acc)


for frame in PAGE.get('children', []):
    bb = frame.get('absoluteBoundingBox') or {}
    acc = []
    for kid in frame.get('children') or []:
        texts(kid, acc)
    acc.sort(key=lambda t: t[0])
    print('=' * 64)
    print(f'{frame["id"]}  "{frame.get("name")}"')
    seen = set()
    for _, ch, size, weight in acc:
        key = (ch, size)
        if key in seen:
            continue
        seen.add(key)
        print(f'   {size}/{weight}  {ch!r}')
