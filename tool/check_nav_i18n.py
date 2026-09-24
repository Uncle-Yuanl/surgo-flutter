#!/usr/bin/env python3
"""对答题卡弹窗要用到的每条文案跑一遍 i18n 查表（模拟 Translator._pick 的 en 方向）。"""
import json
import os
import re

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
d = json.load(open(os.path.join(root, 'assets/data/i18n.json'), encoding='utf-8'))
EN, EN_RE = d['SURGO_EN'], d['SURGO_EN_RE']


def js_to_py(pattern):
    return pattern


def pick_en(s):
    key = s.strip()
    if key in EN:
        return EN[key], 'exact'
    for pat, rep, flags in EN_RE:
        try:
            rx = re.compile(js_to_py(pat))
        except re.error:
            continue
        if rx.search(key):
            py_rep = re.sub(r'\$(\d+)', r'\\\1', rep)
            return rx.sub(py_rep, key), 'regex ' + pat
    return None, 'MISS'


for s in ['题号导航', '已作答', '未作答', '交卷', '答题卡', 'Questions 1-14', '第 1-14 题']:
    print(repr(s), '->', pick_en(s))
