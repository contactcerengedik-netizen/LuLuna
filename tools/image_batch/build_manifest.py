#!/usr/bin/env python3
"""Müfredat soru manifest'i — her skill+difficulty için ≥10 kayıt.

Kullanım:
  python tools/image_batch/build_manifest.py
  python tools/image_batch/build_manifest.py --merge   # mevcut status/localPath koru
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "manifest.json"

STYLE = (
    "Special education illustration for young children. "
    "Simple flat background, high contrast, few objects only. "
    "No decorative clutter, no text overlays, no extra people. "
    "Friendly realistic-but-simple educational worksheet style. "
)

DIFFS = ("easy", "medium", "hard")

MATH_MVP = (
    "number_recognition",
    "addition",
    "subtraction",
    "multiplication",
    "division",
    "fractions",
)

LANG_MVP = (
    "five_w1h",
    "concepts",
    "antonyms",
    "synonyms",
    "homophones",
    "alphabetical",
    "word_ordering",
)

# Ek müfredat alanları (görsel anahat)
EXTRA = (
    ("puzzle", "easy", "4 parçalı basit hayvan puzzle taslağı"),
    ("puzzle", "medium", "9 parçalı ev puzzle taslağı"),
    ("puzzle", "hard", "16 parçalı park puzzle taslağı"),
    ("coloring", "easy", "Kalın kenarlı elma boyama anahattı"),
    ("coloring", "medium", "Kalın kenarlı kedi boyama anahattı"),
    ("coloring", "hard", "Kalın kenarlı bahçe boyama anahattı"),
    ("tracing", "easy", "Düz çizgi nokta birleştirme"),
    ("tracing", "medium", "Eğri çizgi nokta birleştirme"),
    ("tracing", "hard", "Harf şekli nokta birleştirme"),
    ("matching", "easy", "Renk eşleştirme kartları"),
    ("matching", "medium", "Şekil eşleştirme kartları"),
    ("matching", "hard", "Kavram eşleştirme kartları"),
    ("pattern", "easy", "ABAB renk örüntüsü"),
    ("pattern", "medium", "ABBABB şekil örüntüsü"),
    ("pattern", "hard", "ABCABC nesne örüntüsü"),
    ("memory", "easy", "2x2 hafıza kartları"),
    ("memory", "medium", "3x2 hafıza kartları"),
    ("memory", "hard", "4x3 hafıza kartları"),
)


def _entry(
    *,
    id: str,
    skill: str,
    difficulty: str,
    question_text: str,
    image_prompt: str,
    area: str,
    instruction: str = "",
    answer: str = "",
    choices: list[str] | None = None,
) -> dict:
    return {
        "id": id,
        "area": area,
        "skill": skill,
        "difficulty": difficulty,
        "instruction": instruction,
        "questionText": question_text,
        "answer": answer,
        "choices": choices or [],
        "imagePrompt": f"{STYLE}{image_prompt}",
        "status": "pending",
        "localPath": None,
        "imageUrl": None,
    }


def math_questions() -> list[dict]:
    out: list[dict] = []
    objects = [
        ("elma", "kırmızı elma"),
        ("top", "renkli top"),
        ("kalem", "sarı kalem"),
        ("kitap", "mavi kitap"),
        ("balık", "turuncu balık"),
        ("yıldız", "sarı yıldız"),
        ("çiçek", "pembe çiçek"),
        ("araba", "yeşil araba"),
        ("kuş", "mavi kuş"),
        ("karpuz", "dilim karpuz"),
    ]

    for diff in DIFFS:
        for i in range(10):
            n = {"easy": i + 1, "medium": i + 5, "hard": i + 12}[diff]
            obj, label = objects[i]
            out.append(
                _entry(
                    id=f"math_number_recognition_{diff}_{i+1:02d}",
                    skill="number_recognition",
                    difficulty=diff,
                    area="mathematics",
                    instruction="Görsele bak, kaç tane var?",
                    question_text=f"Kaç {obj} var?",
                    answer=str(n),
                    choices=[str(n), str(max(0, n - 1)), str(n + 1), str(n + 2)],
                    image_prompt=(
                        f"Exactly {n} clear {label}s on a plain table, "
                        f"countable, evenly spaced, nothing else."
                    ),
                )
            )

        for i in range(10):
            a = {"easy": 1 + (i % 5), "medium": 3 + (i % 6), "hard": 5 + (i % 8)}[diff]
            b = {"easy": 1 + ((i * 3) % 5), "medium": 2 + (i % 5), "hard": 3 + (i % 6)}[
                diff
            ]
            obj, label = objects[i]
            out.append(
                _entry(
                    id=f"math_addition_{diff}_{i+1:02d}",
                    skill="addition",
                    difficulty=diff,
                    area="mathematics",
                    instruction="Görsele bak, toplamı bul.",
                    question_text=f"Masada {a} {obj} var. {b} {obj} daha geliyor. Toplam kaç {obj} olur?",
                    answer=str(a + b),
                    choices=[str(a + b), str(a), str(b), str(a + b + 1)],
                    image_prompt=(
                        f"Left group of exactly {a} {label}s and right group of "
                        f"exactly {b} {label}s on a plain table, clearly separated, "
                        f"total countable items {a + b}, nothing else."
                    ),
                )
            )

        for i in range(10):
            start = {"easy": 4 + (i % 5), "medium": 8 + (i % 6), "hard": 12 + (i % 8)}[
                diff
            ]
            take = {"easy": 1 + (i % 2), "medium": 2 + (i % 3), "hard": 3 + (i % 4)}[
                diff
            ]
            take = min(take, start - 1)
            obj, label = objects[i]
            out.append(
                _entry(
                    id=f"math_subtraction_{diff}_{i+1:02d}",
                    skill="subtraction",
                    difficulty=diff,
                    area="mathematics",
                    instruction="Problemi oku ve görsele bak.",
                    question_text=f"{start} {obj} vardı. {take} tanesi gitti. Kaç {obj} kaldı?",
                    answer=str(start - take),
                    choices=[
                        str(start - take),
                        str(start),
                        str(take),
                        str(start - take + 1),
                    ],
                    image_prompt=(
                        f"Exactly {start - take} remaining {label}s on a plain table; "
                        f"{take} {label}s shown faded or crossed out separately; "
                        f"no extra objects."
                    ),
                )
            )

        for i in range(10):
            a = {"easy": 2 + (i % 3), "medium": 3 + (i % 4), "hard": 4 + (i % 5)}[diff]
            b = {"easy": 2 + (i % 3), "medium": 3 + (i % 3), "hard": 4 + (i % 4)}[diff]
            obj, label = objects[i]
            out.append(
                _entry(
                    id=f"math_multiplication_{diff}_{i+1:02d}",
                    skill="multiplication",
                    difficulty=diff,
                    area="mathematics",
                    instruction="Grupları say, çarpımı bul.",
                    question_text=f"{a} grup {obj} var. Her grupta {b} tane. Toplam kaç?",
                    answer=str(a * b),
                    choices=[str(a * b), str(a + b), str(a), str(b)],
                    image_prompt=(
                        f"Exactly {a} separate groups, each group has exactly {b} "
                        f"{label}s, plain background, clear spacing."
                    ),
                )
            )

        for i in range(10):
            b = {"easy": 2, "medium": 3 + (i % 2), "hard": 4 + (i % 2)}[diff]
            q = {"easy": 2 + (i % 4), "medium": 3 + (i % 4), "hard": 4 + (i % 5)}[diff]
            total = b * q
            obj, label = objects[i]
            out.append(
                _entry(
                    id=f"math_division_{diff}_{i+1:02d}",
                    skill="division",
                    difficulty=diff,
                    area="mathematics",
                    instruction="Eşit paylaş.",
                    question_text=f"{total} {obj} {b} kutuya eşit paylaşılıyor. Her kutuda kaç?",
                    answer=str(q),
                    choices=[str(q), str(b), str(total), str(q + 1)],
                    image_prompt=(
                        f"Exactly {b} identical boxes, each containing exactly {q} "
                        f"{label}s, plain background, equal sharing."
                    ),
                )
            )

        for i in range(10):
            filled = {"easy": 1 + (i % 3), "medium": 2 + (i % 3), "hard": 3 + (i % 4)}[
                diff
            ]
            whole = {"easy": 4, "medium": 6, "hard": 8}[diff]
            filled = min(filled, whole - 1)
            out.append(
                _entry(
                    id=f"math_fractions_{diff}_{i+1:02d}",
                    skill="fractions",
                    difficulty=diff,
                    area="mathematics",
                    instruction="Boyanan parçayı bul.",
                    question_text=f"{whole} eşit parçadan {filled} tanesi boyalı. Hangisi doğru?",
                    answer=f"{filled}/{whole}",
                    choices=[
                        f"{filled}/{whole}",
                        f"{filled}/{whole + 1}",
                        f"1/{whole}",
                        f"{whole}/{filled}",
                    ],
                    image_prompt=(
                        f"A simple circle or bar divided into exactly {whole} equal "
                        f"parts; exactly {filled} parts filled with solid color; "
                        f"plain white background, no text."
                    ),
                )
            )
    return out


def lang_questions() -> list[dict]:
    out: list[dict] = []

    concepts = {
        "easy": [
            ("Hangisi BÜYÜK?", "büyük top", "küçük top yanında büyük top"),
            ("Hangisi UZUN?", "uzun ip", "kısa ip yanında uzun ip"),
            ("Hangisi KÜÇÜK?", "küçük fare", "büyük fil yanında küçük fare"),
            ("Hangisi KISA?", "kısa kalem", "uzun cetvel yanında kısa kalem"),
            ("Hangisi YÜKSEK?", "yüksek dağ", "alçak tepe yanında yüksek dağ"),
            ("Hangisi ALÇAK?", "alçak masa", "yüksek sandalye yanında alçak masa"),
            ("Hangisi GENİŞ?", "geniş yol", "dar sokak yanında geniş yol"),
            ("Hangisi DAR?", "dar kapı", "geniş kapı yanında dar kapı"),
            ("Hangisi HIZLI?", "hızlı araba", "yavaş kaplumbağa yanında hızlı araba"),
            ("Hangisi YAVAŞ?", "yavaş salyangoz", "hızlı tren yanında yavaş salyangoz"),
        ],
        "medium": [
            ("Hangisi AĞIR?", "ağır çanta", "hafif tüy yanında ağır çanta"),
            ("Hangisi DOLU?", "dolu bardak", "boş bardak yanında dolu bardak"),
            ("Hangisi HAFİF?", "hafif balon", "ağır taş yanında hafif balon"),
            ("Hangisi BOŞ?", "boş kutu", "dolu kutu yanında boş kutu"),
            ("Hangisi SICAK?", "sıcak çorba", "soğuk dondurma yanında sıcak çorba"),
            ("Hangisi SOĞUK?", "soğuk buz", "sıcak çay yanında soğuk buz"),
            ("Hangisi YAŞ?", "yaş havlu", "kuru havlu yanında yaş havlu"),
            ("Hangisi KURU?", "kuru yaprak", "yaş yaprak yanında kuru yaprak"),
            ("Hangisi TEMİZ?", "temiz tabak", "kirli ayakkabı yanında temiz tabak"),
            ("Hangisi KİRLİ?", "kirli elbise", "temiz gömlek yanında kirli elbise"),
        ],
        "hard": [
            ("Hangisi ESKİ?", "eski kitap", "yeni kitap yanında eski kitap"),
            ("Hangisi YENİ?", "yeni ayakkabı", "eski ayakkabı yanında yeni ayakkabı"),
            ("Hangisi AÇIK?", "açık pencere", "kapalı pencere yanında açık pencere"),
            ("Hangisi KAPALI?", "kapalı kutu", "açık kutu yanında kapalı kutu"),
            ("Hangisi SERT?", "sert taş", "yumuşak yastık yanında sert taş"),
            ("Hangisi YUMUŞAK?", "yumuşak battaniye", "sert tahta yanında yumuşak battaniye"),
            ("Hangisi PARLAK?", "parlak lamba", "sönük lamba yanında parlak lamba"),
            ("Hangisi MAT?", "mat kutu", "parlak kutu yanında mat kutu"),
            ("Hangisi DOLU?", "dolu sepet", "boş sepet yanında dolu sepet"),
            ("Hangisi BOŞ?", "boş kavanoz", "dolu kavanoz yanında boş kavanoz"),
        ],
    }

    for diff in DIFFS:
        for i, (q, ans, scene) in enumerate(concepts[diff], start=1):
            out.append(
                _entry(
                    id=f"lang_concepts_{diff}_{i:02d}",
                    skill="concepts",
                    difficulty=diff,
                    area="language",
                    instruction="Doğru kavramı seç.",
                    question_text=q,
                    answer=ans,
                    image_prompt=f"Show clearly: {scene}. Only two objects, plain background.",
                )
            )

    antonyms = [
        ("büyük", "küçük"),
        ("uzun", "kısa"),
        ("sıcak", "soğuk"),
        ("hızlı", "yavaş"),
        ("açık", "kapalı"),
        ("dolu", "boş"),
        ("ağır", "hafif"),
        ("yeni", "eski"),
        ("temiz", "kirli"),
        ("yüksek", "alçak"),
    ]
    for diff in DIFFS:
        for i, (a, b) in enumerate(antonyms, start=1):
            out.append(
                _entry(
                    id=f"lang_antonyms_{diff}_{i:02d}",
                    skill="antonyms",
                    difficulty=diff,
                    area="language",
                    instruction="Zıt anlamı bul.",
                    question_text=f"“{a}” sözcüğünün zıtı nedir?",
                    answer=b,
                    image_prompt=(
                        f"Two labeled scenes: one shows concept '{a}', the other '{b}', "
                        f"clear contrast, plain background, no text in image."
                    ),
                )
            )

    synonyms = [
        ("mutlu", "sevinçli"),
        ("hızlı", "çabuk"),
        ("büyük", "kocaman"),
        ("küçük", "minik"),
        ("güzel", "hoş"),
        ("zor", "güç"),
        ("kolay", "basit"),
        ("akıllı", "zeki"),
        ("sessiz", "sakin"),
        ("parlak", "ışıklı"),
    ]
    for diff in DIFFS:
        for i, (a, b) in enumerate(synonyms, start=1):
            out.append(
                _entry(
                    id=f"lang_synonyms_{diff}_{i:02d}",
                    skill="synonyms",
                    difficulty=diff,
                    area="language",
                    instruction="Yakın anlamlıyı bul.",
                    question_text=f"“{a}” ile yakın anlamlı hangisi?",
                    answer=b,
                    image_prompt=(
                        f"Simple illustration conveying '{a}' / '{b}' mood, "
                        f"one clear scene, plain background."
                    ),
                )
            )

    homophones = [
        ("kar", "kar yağışı sahnesi"),
        ("kardeş", "iki kardeş"),
        ("gül", "çiçek gül"),
        ("yaz", "yaz mevsimi plaj"),
        ("çay", "çay fincanı"),
        ("göz", "göz çizimi sade"),
        ("dal", "ağaç dalı"),
        ("yüz", "yüzme havuzu"),
        ("kaç", "kaçmak koşan çocuk silueti"),
        ("aç", "açılan kapı"),
    ]
    for diff in DIFFS:
        for i, (word, scene) in enumerate(homophones, start=1):
            out.append(
                _entry(
                    id=f"lang_homophones_{diff}_{i:02d}",
                    skill="homophones",
                    difficulty=diff,
                    area="language",
                    instruction="Doğru anlamı seç.",
                    question_text=f"“{word}” burada hangi anlama geliyor?",
                    answer=word,
                    image_prompt=f"Illustrate: {scene}. Plain background, single clear meaning.",
                )
            )

    alpha = list("ABCDEFGHIJ")
    for diff in DIFFS:
        for i, letter in enumerate(alpha, start=1):
            out.append(
                _entry(
                    id=f"lang_alphabetical_{diff}_{i:02d}",
                    skill="alphabetical",
                    difficulty=diff,
                    area="language",
                    instruction="Harfi bul.",
                    question_text=f"Hangisi “{letter}” harfi?",
                    answer=letter,
                    image_prompt=(
                        f"Large clear uppercase letter {letter} centered, "
                        f"simple sans style, plain pastel background, no other letters."
                    ),
                )
            )

    five = [
        ("Kim parkta top oynuyor?", "çocuk parkta top oynuyor"),
        ("Ne yiyor?", "çocuk elma yiyor"),
        ("Nerede oturuyor?", "çocuk bankta oturuyor"),
        ("Ne zaman uyuyor?", "çocuk gece yatakta uyuyor"),
        ("Nasıl gidiyor?", "çocuk bisikletle gidiyor"),
        ("Neden gülüyor?", "çocuk hediye alınca gülüyor"),
        ("Kim kitabı okuyor?", "kız kitap okuyor"),
        ("Ne taşıyor?", "çocuk su şişesi taşıyor"),
        ("Nerede koşuyor?", "çocuk bahçede koşuyor"),
        ("Ne zaman yemek yiyor?", "aile masada akşam yemeği"),
    ]
    for diff in DIFFS:
        for i, (q, scene) in enumerate(five, start=1):
            out.append(
                _entry(
                    id=f"lang_five_w1h_{diff}_{i:02d}",
                    skill="five_w1h",
                    difficulty=diff,
                    area="language",
                    instruction="Soruyu görsele bakarak cevapla.",
                    question_text=q,
                    answer="",
                    image_prompt=f"Clear scene: {scene}. Few objects, plain background.",
                )
            )

    words = [
        ("Ben okula gidiyorum", "çocuk okul çantasıyla yürüyor"),
        ("Kedi süt içiyor", "kedi kaseden süt içiyor"),
        ("Top yuvarlanıyor", "top çimenlikte yuvarlanıyor"),
        ("Güneş parlıyor", "güneşli gökyüzü sade"),
        ("Kuş uçuyor", "tek kuş gökyüzünde"),
        ("Çiçek açıyor", "tek çiçek saksıda"),
        ("Araba geliyor", "tek araba yolda"),
        ("Köpek koşuyor", "köpek parkta koşuyor"),
        ("Bebek gülüyor", "bebek gülümsüyor"),
        ("Anne yemek yapıyor", "mutfakta sade yemek sahnesi"),
    ]
    for diff in DIFFS:
        for i, (sentence, scene) in enumerate(words, start=1):
            out.append(
                _entry(
                    id=f"lang_word_ordering_{diff}_{i:02d}",
                    skill="word_ordering",
                    difficulty=diff,
                    area="language",
                    instruction="Kelimeleri doğru sıraya koy.",
                    question_text=sentence,
                    answer=sentence,
                    image_prompt=f"Scene matching sentence: {scene}. Plain background.",
                )
            )

    return out


def extra_questions() -> list[dict]:
    out: list[dict] = []
    # Her ekstra skill için difficulty başına 10 varyasyon
    for skill, base_diff, base_prompt in EXTRA:
        for diff in DIFFS:
            for i in range(1, 11):
                out.append(
                    _entry(
                        id=f"{skill}_{diff}_{i:02d}",
                        skill=skill,
                        difficulty=diff,
                        area=skill,
                        instruction=f"{skill} etkinliği",
                        question_text=f"{skill} — {diff} örnek {i}",
                        image_prompt=f"{base_prompt}. Variation {i}, consistent style.",
                    )
                )
    return out


def validate(items: list[dict]) -> None:
    from collections import Counter

    c = Counter((e["skill"], e["difficulty"]) for e in items)
    bad = [k for k, n in c.items() if n < 10]
    if bad:
        raise SystemExit(f"Eksik skill+difficulty (<10): {bad[:20]}")
    print(f"OK: {len(items)} kayit, {len(c)} skill+difficulty grubu (>=10)")


def merge_preserve(old: list[dict], new: list[dict]) -> list[dict]:
    by_id = {e["id"]: e for e in old}
    merged = []
    for e in new:
        prev = by_id.get(e["id"])
        if prev:
            e = {
                **e,
                "status": prev.get("status", e["status"]),
                "localPath": prev.get("localPath"),
                "imageUrl": prev.get("imageUrl"),
                "imagePrompt": prev.get("imagePrompt", e["imagePrompt"]),
            }
        merged.append(e)
    return merged


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--merge", action="store_true")
    args = ap.parse_args()

    items = math_questions() + lang_questions() + extra_questions()
    validate(items)

    if args.merge and OUT.exists():
        old = json.loads(OUT.read_text(encoding="utf-8"))
        items = merge_preserve(old, items)
        print("Mevcut status/localPath birleştirildi.")

    OUT.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Yazıldı: {OUT}")


if __name__ == "__main__":
    main()
