#!/usr/bin/env python3
"""generated kayıtlar için review.html üret (yalnızca görüntüleme).

  python tools/image_batch/build_review.py
  # tarayıcıda tools/image_batch/review.html aç
"""

from __future__ import annotations

import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
MANIFEST = HERE / "manifest.json"
OUT_HTML = HERE / "review.html"


def main() -> None:
    items = json.loads(MANIFEST.read_text(encoding="utf-8"))
    generated = [
        e
        for e in items
        if e.get("status") in ("generated", "approved", "rejected")
    ]
    cards = []
    for e in generated:
        path = e.get("localPath") or ""
        img = (
            f'<img src="{path}" alt="{e["id"]}" loading="lazy" />'
            if path
            else '<div class="missing">görsel yok</div>'
        )
        cards.append(
            f"""
<article class="card" data-status="{e.get('status')}">
  <div class="meta">
    <code class="id">{e['id']}</code>
    <span class="badge">{e.get('status')}</span>
    <p class="skill">{e.get('skill')} / {e.get('difficulty')}</p>
    <p class="q">{_esc(e.get('questionText') or '')}</p>
    <p class="prompt"><small>{_esc((e.get('imagePrompt') or '')[:280])}…</small></p>
  </div>
  <div class="img">{img}</div>
</article>"""
        )

    html = f"""<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <title>LuLuna görsel inceleme</title>
  <style>
    body {{ font-family: system-ui, sans-serif; margin: 24px; background: #f4f6f8; color: #1a1a1a; }}
    h1 {{ font-size: 1.4rem; }}
    .hint {{ color: #555; margin-bottom: 1.5rem; }}
    .grid {{ display: grid; gap: 16px; }}
    .card {{ display: grid; grid-template-columns: 1fr 320px; gap: 16px; background: #fff;
             border: 1px solid #dde2e8; border-radius: 12px; padding: 16px; }}
    .id {{ font-size: 0.95rem; background: #eef2f6; padding: 4px 8px; border-radius: 6px; }}
    .badge {{ margin-left: 8px; font-size: 0.8rem; text-transform: uppercase; color: #0b5; }}
    .card[data-status="rejected"] .badge {{ color: #c33; }}
    .card[data-status="approved"] .badge {{ color: #06c; }}
    img {{ width: 100%; border-radius: 8px; background: #eee; }}
    .missing {{ height: 180px; display:grid; place-items:center; background:#eee; border-radius:8px; }}
    @media (max-width: 800px) {{ .card {{ grid-template-columns: 1fr; }} }}
  </style>
</head>
<body>
  <h1>LuLuna — toplu görsel inceleme</h1>
  <p class="hint">
    Onay/red için <code>manifest.json</code> içinde ilgili kaydın
    <code>status</code> alanını <code>approved</code> veya <code>rejected</code> yapın.
    Reddedilenleri yeniden üretmek: <code>python generate.py --regenerate-rejected</code>
  </p>
  <p>{len(generated)} kayıt gösteriliyor (generated / approved / rejected).</p>
  <div class="grid">
    {''.join(cards) if cards else '<p>Henüz generated kayıt yok. Önce generate.py çalıştırın.</p>'}
  </div>
</body>
</html>
"""
    OUT_HTML.write_text(html, encoding="utf-8")
    print(f"Yazıldı: {OUT_HTML} ({len(generated)} kart)")


def _esc(s: str) -> str:
    return (
        s.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


if __name__ == "__main__":
    main()
