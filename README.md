# LuLuna

Özel eğitim destekli öğrenme platformu (Flutter + Riverpod + Supabase).

- **Öğrenci / Veli / Öğretmen** rolleri
- Matematik, Türkçe, puzzle (+ mevcut: çizgi, boyama, günlük yaşam — MVP sonrası backlog)
- AI içerik pipeline (mock-first), ödev, raporlar
- **Demo Mode:** Supabase anahtarı yoksa yerel demo (`student@demo.com` / `teacher@demo.com`, şifre `demo1234`)

## Çalıştırma

```bash
flutter pub get
flutter run
# veya emülatör:
flutter emulators --launch Luluna
flutter run -d emulator-5554
```

Opsiyonel config: `--dart-define-from-file=config/gemini.json` (şablon: `.env.example`)

## Mimari

```
lib/
  app/           # tema, router, ortak widget
  core/          # env, test hesapları
  data/          # modeller, repository, servisler
  features/      # auth, student, teacher, mathematics, …
```

UI → Riverpod → Repository → Service → Supabase / AI / Mock

## Geliştirme fazları (prompt v2)

1. Foundation — tamam (temizlik + auth + demo + modeller)
2. Core UI — tamam
3. Education Engine — tamam
4. Puzzle — tamam
5. AI Pipeline — tamam
6. Analytics & Reports — tamam
7. Supabase Backend — tamam
8. Ortak Altyapı (Kavram + görsel + Dialogue) — tamam (v3)
9. Türkçe genişletme — tamam (v3)
10. Dört işlem (çarpma/bölme/kesir) — tamam (v3)
11. Motor beceri (PathTracing + glyph) — tamam (v3)
12. Görsel/yaratıcı (Canvas + eşleştirme) — tamam (v3)
13. Bilişsel (örüntü + veri okuma) — tamam (v3)
14. Hafıza–dikkat (MemoryEngine) — tamam (v3)
15. Konuşma & sosyal (STT + Dialogue) — tamam (v3)
16. Günlük yaşam (Routine + AAC) — tamam (v3)
17. Entegrasyon & öğretmen paneli (15 alan) — tamam (v3)

## Supabase

Migrations (sırayla uygula):

- `004_education_roles.sql` — roller
- `005_education_schema_draft.sql` — taslak tablolar
- `006_education_backend.sql` — RLS + attempts/assignments/AI/reports
- `007_skill_key_levels.sql` — `skill_key` / `source` + skills kataloğu
- `008_concept_engine.sql` — kavram motoru tabloları
- `009_path_tracing_deviation.sql` — `attempt_answers.deviation_score`

Demo ↔ bulut: `Env.hasSupabase` false → `InMemoryEducationRepository`; true → `FallbackEducationRepository(Supabase…, demo)`. Anahtarlar `.env.example` / `config/gemini.json`.
