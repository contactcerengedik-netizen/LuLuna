#!/usr/bin/env python3
"""approved görselleri Storage'a (veya assets/) yükle + Flutter seed yaz.

  python tools/image_batch/upload_approved.py
  python tools/image_batch/upload_approved.py --assets-only

Supabase varsa: question-images/{skill}/{difficulty}/{id}.png
Yoksa: assets/curriculum/images/... kopyalanır.

Sonuç: assets/curriculum/questions.json (uygulama bunu okur).
"""

from __future__ import annotations

import argparse
import json
import shutil
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
MANIFEST = HERE / "manifest.json"
ASSETS_IMG = ROOT / "assets" / "curriculum" / "images"
ASSETS_JSON = ROOT / "assets" / "curriculum" / "questions.json"

# generate.py ile aynı env yükleyici
from generate import load_env  # noqa: E402


def upload_supabase(
    *,
    url: str,
    key: str,
    bucket: str,
    path: str,
    data: bytes,
    content_type: str = "image/png",
) -> str:
    endpoint = f"{url.rstrip('/')}/storage/v1/object/{bucket}/{path}"
    req = urllib.request.Request(
        endpoint,
        data=data,
        method="POST",
        headers={
            "Authorization": f"Bearer {key}",
            "apikey": key,
            "Content-Type": content_type,
            "x-upsert": "true",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            resp.read()
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Upload HTTP {e.code}: {err[:400]}") from e
    return f"{url.rstrip('/')}/storage/v1/object/public/{bucket}/{path}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--assets-only",
        action="store_true",
        help="Supabase atla; sadece assets/ altına kopyala",
    )
    args = ap.parse_args()

    items: list[dict] = json.loads(MANIFEST.read_text(encoding="utf-8"))
    approved = [e for e in items if e.get("status") == "approved"]
    if not approved:
        print("approved kayıt yok. manifest.json içinde status=approved yapın.")
        return 1

    env = load_env()
    supabase_url = (env.get("SUPABASE_URL") or "").strip()
    supabase_key = (
        env.get("SUPABASE_SERVICE_ROLE_KEY")
        or env.get("SUPABASE_ANON_KEY")
        or ""
    ).strip()
    use_sb = (
        not args.assets_only
        and bool(supabase_url)
        and bool(supabase_key)
    )

    seed: list[dict] = []
    for e in items:
        local = e.get("localPath")
        image_url = e.get("imageUrl")

        if e.get("status") == "approved" and local:
            src = HERE / local
            if not src.exists():
                print(f"UYARI: dosya yok {local}")
            else:
                rel = f"{e['skill']}/{e['difficulty']}/{e['id']}.png"
                if use_sb:
                    try:
                        image_url = upload_supabase(
                            url=supabase_url,
                            key=supabase_key,
                            bucket="question-images",
                            path=rel,
                            data=src.read_bytes(),
                        )
                        print(f"↑ {e['id']} → {image_url}")
                    except Exception as ex:  # noqa: BLE001
                        print(f"Supabase hata ({e['id']}): {ex} → assets")
                        use_sb_fallback = True
                    else:
                        use_sb_fallback = False
                else:
                    use_sb_fallback = True

                if not use_sb or use_sb_fallback:
                    dest = ASSETS_IMG / e["skill"] / e["difficulty"] / f"{e['id']}.png"
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(src, dest)
                    image_url = (
                        f"assets/curriculum/images/{e['skill']}/"
                        f"{e['difficulty']}/{e['id']}.png"
                    )
                    print(f"→ {image_url}")

                e["imageUrl"] = image_url

        # Flutter seed: onaylı + görselli kayıtlar
        if e.get("imageUrl") and e.get("status") in ("approved", "generated"):
            # generated henüz onaylanmadıysa seed'e alma — sadece approved
            pass
        if e.get("status") == "approved" and e.get("imageUrl"):
            seed.append(
                {
                    "id": e["id"],
                    "area": e.get("area", "mathematics"),
                    "skill": e["skill"],
                    "category": e["skill"],
                    "difficulty": e["difficulty"],
                    "instruction": e.get("instruction") or "",
                    "questionText": e.get("questionText") or "",
                    "answer": e.get("answer") or "",
                    "choices": e.get("choices") or [],
                    "imageUrl": e["imageUrl"],
                    "solutionImageUrl": e["imageUrl"],
                }
            )

    MANIFEST.write_text(
        json.dumps(items, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    ASSETS_JSON.parent.mkdir(parents=True, exist_ok=True)
    ASSETS_JSON.write_text(
        json.dumps(seed, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Seed: {ASSETS_JSON} ({len(seed)} soru)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
