#!/usr/bin/env python3
"""Manifest'teki pending (veya rejected) kayıtlar için Gemini görsel üretimi.

Kullanım:
  python tools/image_batch/generate.py
  python tools/image_batch/generate.py --delay-ms 2500
  python tools/image_batch/generate.py --regenerate-rejected
  python tools/image_batch/generate.py --limit 5

Anahtar: tools/image_batch/.env veya config/gemini.json → GEMINI_API_KEY
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
MANIFEST = HERE / "manifest.json"
OUTPUT = HERE / "output"
IMAGE_MODEL = "gemini-3.1-flash-image"


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    for path in (HERE / ".env", ROOT / ".env", ROOT / "config" / "gemini.json"):
        if not path.exists():
            continue
        if path.suffix == ".json":
            data = json.loads(path.read_text(encoding="utf-8"))
            for k, v in data.items():
                if isinstance(v, str) and v.strip():
                    env.setdefault(k, v.strip())
        else:
            for line in path.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                env.setdefault(k.strip(), v.strip().strip('"').strip("'"))
    # OS env wins
    for k in ("GEMINI_API_KEY", "SUPABASE_URL", "SUPABASE_ANON_KEY", "SUPABASE_SERVICE_ROLE_KEY"):
        if os.environ.get(k):
            env[k] = os.environ[k]
    return env


def is_quota(err: str, code: int | None) -> bool:
    s = (err or "").lower()
    if code == 429:
        return True
    return "resource_exhausted" in s or "quota" in s or "rate limit" in s


def generate_image(api_key: str, prompt: str) -> bytes:
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{IMAGE_MODEL}:generateContent"
    )
    body = {
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {"responseModalities": ["TEXT", "IMAGE"]},
    }
    raw = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=raw,
        headers={
            "Content-Type": "application/json",
            "x-goog-api-key": api_key,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {e.code}: {err[:800]}") from e

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
        if b64:
            return base64.b64decode(b64)
    raise RuntimeError(f"Görsel yok: {json.dumps(payload)[:300]}")


def save_manifest(items: list[dict]) -> None:
    MANIFEST.write_text(
        json.dumps(items, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--delay-ms", type=int, default=2000)
    ap.add_argument("--regenerate-rejected", action="store_true")
    ap.add_argument("--limit", type=int, default=0, help="0 = sınırsız")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not MANIFEST.exists():
        print("manifest yok — önce: python tools/image_batch/build_manifest.py")
        return 1

    env = load_env()
    api_key = env.get("GEMINI_API_KEY", "").strip()
    if not api_key and not args.dry_run:
        print("GEMINI_API_KEY yok (.env veya config/gemini.json)")
        return 1

    items: list[dict] = json.loads(MANIFEST.read_text(encoding="utf-8"))
    want = {"pending"}
    if args.regenerate_rejected:
        want.add("rejected")

    todo = [e for e in items if e.get("status") in want]
    if args.limit > 0:
        todo = todo[: args.limit]

    print(f"Üretilecek: {len(todo)} / toplam {len(items)}")
    if args.dry_run:
        for e in todo[:10]:
            print(f"  - {e['id']}")
        if len(todo) > 10:
            print(f"  … +{len(todo) - 10}")
        return 0

    done = 0
    for e in todo:
        eid = e["id"]
        skill = e["skill"]
        diff = e["difficulty"]
        dest_dir = OUTPUT / skill / diff
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest = dest_dir / f"{eid}.png"
        prompt = e.get("imagePrompt") or e.get("questionText") or eid

        print(f"→ {eid}")
        try:
            png = generate_image(api_key, prompt)
            dest.write_bytes(png)
            e["status"] = "generated"
            e["localPath"] = str(dest.relative_to(HERE)).replace("\\", "/")
            # rejected yeniden üretildiyse onay bekler
            save_manifest(items)
            done += 1
            print(f"  kaydedildi {e['localPath']}")
        except Exception as ex:  # noqa: BLE001
            msg = str(ex)
            code = None
            if msg.startswith("HTTP "):
                try:
                    code = int(msg.split()[1].rstrip(":"))
                except (IndexError, ValueError):
                    code = None
            if is_quota(msg, code):
                # pending bırak, düzgün çık
                if e.get("status") == "rejected":
                    e["status"] = "rejected"
                else:
                    e["status"] = "pending"
                save_manifest(items)
                left = sum(1 for x in items if x.get("status") in want)
                print(
                    f"\nKOTA: üretim durdu. "
                    f"{done} yeni görsel, {left} kayıt kaldı. "
                    f"Daha sonra aynı komutu tekrar çalıştırın."
                )
                return 2
            print(f"  HATA (atlanıyor): {msg[:200]}")
            e["status"] = "pending"
            save_manifest(items)

        if args.delay_ms > 0:
            time.sleep(args.delay_ms / 1000.0)

    left = sum(1 for x in items if x.get("status") in ("pending", "rejected"))
    print(f"\nBitti. Yeni: {done}. Kalan pending/rejected: {left}")
    print("İnceleme: python tools/image_batch/build_review.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
