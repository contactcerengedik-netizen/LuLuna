#!/usr/bin/env python3
"""LuLuna — Gemini görsel/metin CORS proxy (yalnızca yerel geliştirme).

Chrome'dan Gemini API'ye doğrudan istek CORS yüzünden düşer.
Bu proxy anahtarı config/gemini.json'dan okur, istemciye CORS açar.

Kullanım:
  python tools/gemini_cors_proxy.py
  # http://127.0.0.1:8791
"""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HOST = "127.0.0.1"
PORT = 8791
ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "config" / "gemini.json"
IMAGE_MODEL = "gemini-3.1-flash-image"
TEXT_MODEL_DEFAULT = "gemini-3.5-flash"


def load_key() -> tuple[str, str]:
    data = json.loads(CONFIG.read_text(encoding="utf-8"))
    key = (data.get("GEMINI_API_KEY") or "").strip()
    if not key:
        key = (data.get("OPENAI_API_KEY") or "").strip()
        if not (key.startswith("AQ.") or key.startswith("AIza")):
            key = ""
    model = (data.get("GEMINI_MODEL") or TEXT_MODEL_DEFAULT).strip()
    if not key:
        raise SystemExit(f"GEMINI_API_KEY yok: {CONFIG}")
    return key, model


API_KEY, TEXT_MODEL = load_key()


def gemini_generate_content(model: str, body: dict) -> dict:
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{model}:generateContent"
    )
    raw = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=raw,
        headers={
            "Content-Type": "application/json",
            "x-goog-api-key": API_KEY,
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read().decode("utf-8"))


def extract_image_data_url(payload: dict) -> str | None:
    parts = (
        payload.get("candidates", [{}])[0]
        .get("content", {})
        .get("parts", [])
    )
    for part in parts:
        inline = part.get("inlineData") or part.get("inline_data")
        if not inline:
            continue
        b64 = inline.get("data")
        mime = inline.get("mimeType") or inline.get("mime_type") or "image/png"
        if b64:
            return f"data:{mime};base64,{b64}"
    return None


class Handler(BaseHTTPRequestHandler):
    def _cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _json(self, code: int, obj: dict) -> None:
        data = json.dumps(obj).encode("utf-8")
        self.send_response(code)
        self._cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_OPTIONS(self) -> None:  # noqa: N802
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        if self.path.startswith("/health"):
            self._json(200, {"ok": True, "imageModel": IMAGE_MODEL})
            return
        self._json(404, {"error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length) if length else b"{}"
        try:
            body = json.loads(raw.decode("utf-8") or "{}")
        except json.JSONDecodeError:
            self._json(400, {"error": "invalid json"})
            return

        try:
            if self.path.startswith("/v1/generate-image"):
                prompt = (body.get("prompt") or "").strip()
                if not prompt:
                    self._json(400, {"error": "prompt required"})
                    return
                model = body.get("model") or IMAGE_MODEL
                print(f"[proxy] IMAGE model={model} prompt_len={len(prompt)}")
                payload = gemini_generate_content(
                    model,
                    {
                        "contents": [
                            {"role": "user", "parts": [{"text": prompt}]}
                        ],
                        "generationConfig": {
                            "responseModalities": ["TEXT", "IMAGE"],
                        },
                    },
                )
                preview = json.dumps(payload)[:200]
                print(f"[proxy] IMAGE response prefix: {preview}")
                data_url = extract_image_data_url(payload)
                if not data_url:
                    self._json(
                        502,
                        {
                            "error": "no image in response",
                            "preview": preview,
                        },
                    )
                    return
                self._json(200, {"dataUrl": data_url, "model": model})
                return

            if self.path.startswith("/v1/generate-json"):
                prompt = (body.get("prompt") or "").strip()
                model = body.get("model") or TEXT_MODEL
                print(f"[proxy] JSON model={model} prompt_len={len(prompt)}")
                payload = gemini_generate_content(
                    model,
                    {
                        "contents": [
                            {"role": "user", "parts": [{"text": prompt}]}
                        ],
                        "generationConfig": {
                            "temperature": 0.85,
                            "responseMimeType": "application/json",
                        },
                    },
                )
                parts = (
                    payload.get("candidates", [{}])[0]
                    .get("content", {})
                    .get("parts", [])
                )
                text = "".join(
                    p.get("text", "") for p in parts if isinstance(p, dict)
                )
                print(f"[proxy] JSON text prefix: {text[:200]}")
                self._json(200, {"text": text, "model": model})
                return

            self._json(404, {"error": "not found"})
        except urllib.error.HTTPError as e:
            err = e.read().decode("utf-8", errors="replace")[:500]
            print(f"[proxy] HTTPError {e.code}: {err}")
            self._json(e.code, {"error": err})
        except Exception as e:  # noqa: BLE001
            print(f"[proxy] ERROR: {e}")
            self._json(500, {"error": str(e)})

    def log_message(self, fmt: str, *args) -> None:
        print(f"[proxy] {self.address_string()} - {fmt % args}")


if __name__ == "__main__":
    print(f"Gemini CORS proxy -> http://{HOST}:{PORT}")
    print(f"Config: {CONFIG}")
    print(f"Text model: {TEXT_MODEL} | Image model: {IMAGE_MODEL}")
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
