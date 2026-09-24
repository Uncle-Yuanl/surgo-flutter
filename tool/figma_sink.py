#!/usr/bin/env python3
"""接收 Preview 页内 POST 过来的 Figma 预览图（本机 CLI 无法直连外网）。

用法: python3 tool/figma_sink.py --port 9101 --out artifacts/figma_auth
页面侧: fetch('http://127.0.0.1:9101/put?name=40_363.png', {method:'POST', body: bytes})
"""
import argparse
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

OUT = None


class Handler(BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS, GET')

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    def do_GET(self):
        self.send_response(200)
        self._cors()
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'ok')

    def do_POST(self):
        q = parse_qs(urlparse(self.path).query)
        name = (q.get('name') or ['unnamed.bin'])[0]
        name = os.path.basename(name)
        length = int(self.headers.get('Content-Length') or 0)
        body = self.rfile.read(length)
        path = os.path.join(OUT, name)
        with open(path, 'wb') as f:
            f.write(body)
        self.send_response(200)
        self._cors()
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(f'{name} {len(body)}'.encode())
        print(f'wrote {name} {len(body)} bytes', flush=True)

    def log_message(self, *a):
        pass


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--port', type=int, default=9101)
    ap.add_argument('--out', required=True)
    args = ap.parse_args()
    OUT = os.path.abspath(args.out)
    os.makedirs(OUT, exist_ok=True)
    print(f'sink on {args.port} -> {OUT}', flush=True)
    ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()
