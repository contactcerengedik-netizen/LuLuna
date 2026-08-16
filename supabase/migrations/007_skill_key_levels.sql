-- PHASE 7: Align student_skill_levels with skill_key architecture (prompt §6).
-- Safe to re-run.

-- skill_key: e.g. toplama, 5n1k, puzzle (independent of SkillArea aggregate)
alter table public.student_skill_levels
  add column if not exists skill_key text;

alter table public.student_skill_levels
  add column if not exists source text not null default 'teacherSet';

alter table public.student_skill_levels
  add column if not exists updated_at timestamptz not null default now();

-- Backfill skill_key from legacy skill area name when empty
update public.student_skill_levels
set skill_key = skill
where skill_key is null or skill_key = '';

-- Prefer unique (student_id, skill_key)
alter table public.student_skill_levels
  drop constraint if exists student_skill_levels_student_id_skill_key;

create unique index if not exists student_skill_levels_student_skill_key_uidx
  on public.student_skill_levels (student_id, skill_key);

-- Optional skills catalog (MVP reference)
create table if not exists public.skills (
  key text primary key,
  label text not null,
  area text not null,
  created_at timestamptz not null default now()
);

insert into public.skills (key, label, area) values
  ('sayi_tanima', 'Sayı tanıma', 'mathematics'),
  ('toplama', 'Toplama', 'mathematics'),
  ('cikarma', 'Çıkarma', 'mathematics'),
  ('5n1k', '5N1K', 'language'),
  ('zit_kavramlar', 'Zıt kavramlar', 'language'),
  ('puzzle', 'Puzzle', 'puzzle')
on conflict (key) do nothing;

-- activity_questions: reusable question bank rows (optional; payload still on activities)
create table if not exists public.activity_questions (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid references public.activities (id) on delete cascade,
  skill text not null,
  skill_key text,
  category text not null,
  difficulty text not null default 'easy',
  instruction text not null default '',
  question_text text not null,
  choices jsonb not null default '[]'::jsonb,
  correct_answer text not null,
  explanation text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.activity_questions enable row level security;

drop policy if exists "activity_questions_select" on public.activity_questions;
create policy "activity_questions_select" on public.activity_questions
  for select to authenticated using (true);

drop policy if exists "activity_questions_write_auth" on public.activity_questions;
create policy "activity_questions_write_auth" on public.activity_questions
  for all to authenticated
  using (true)
  with check (true);

-- published AI content readable by students (status = published)
drop policy if exists "ai_content_student_published" on public.ai_generated_content;
create policy "ai_content_student_published" on public.ai_generated_content
  for select to authenticated using (
    approved = true or status = 'published'
  );
