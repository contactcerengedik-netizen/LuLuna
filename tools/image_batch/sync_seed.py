#!/usr/bin/env python3
"""Manifest → assets/curriculum/questions.json (Flutter seed).

Onaysız kayıtlar da soru metni için seed'e girer; imageUrl yalnızca doluysa yazılır.
Runtime: imageUrl varsa Gemini çağrılmaz.

  python tools/image_batch/sync_seed.py
"""

from __future__ import annotations

import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
MANIFEST = HERE / "manifest.json"
ASSETS_JSON = ROOT / "assets" / "curriculum" / "questions.json"


def main() -> None:
    items = json.loads(MANIFEST.read_text(encoding="utf-8"))
    seed = []
    for e in items:
        # Puzzle vb. ekstra alanlar app EducationQuestion oturumuna girmeyebilir;
        # matematik + dil öncelikli.
        if e.get("area") not in ("mathematics", "language"):
            continue
        seed.append(
            {
                "id": e["id"],
                "area": e["area"],
                "skill": e["skill"],
                "category": e["skill"],
                "difficulty": e["difficulty"],
                "instruction": e.get("instruction") or "",
                "questionText": e.get("questionText") or "",
                "correctAnswer": e.get("answer") or "",
                "choices": e.get("choices") or [],
                "imageUrl": e.get("imageUrl"),
                "solutionImageUrl": e.get("imageUrl"),
                "status": e.get("status"),
            }
        )
    ASSETS_JSON.parent.mkdir(parents=True, exist_ok=True)
    ASSETS_JSON.write_text(
        json.dumps(seed, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    with_img = sum(1 for s in seed if s.get("imageUrl"))
    print(f"Seed: {ASSETS_JSON} ({len(seed)} soru, {with_img} görselli)")


if __name__ == "__main__":
    main()
