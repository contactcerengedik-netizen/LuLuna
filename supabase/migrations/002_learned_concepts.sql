-- Additive: learned_concepts + concept_interactions
-- Mevcut tabloları silmez. SQL Editor'de çalıştırın.

create table if not exists public.learned_concepts (
  id                 text primary key,
  user_id            uuid not null references auth.users(id) on delete cascade,
  concept_type       text not null default 'object',
  concept_key        text not null,
  display_name       text not null,
  category           text not null default '',
  first_seen_at      timestamptz not null,
  last_seen_at       timestamptz not null,
  times_seen         int not null default 1,
  times_asked        int not null default 0,
  correct_answers    int not null default 0,
  incorrect_answers  int not null default 0,
  mastery_score      double precision not null default 0,
  environments_seen  jsonb not null default '[]'::jsonb,
  voice_attempts     int not null default 0,
  last_reviewed_at   timestamptz,
  next_review_at     timestamptz,
  updated_at         timestamptz not null default now(),
  unique (user_id, concept_key)
);

create index if not exists learned_concepts_user_last
  on public.learned_concepts (user_id, last_seen_at desc);

create index if not exists learned_concepts_user_review
  on public.learned_concepts (user_id, next_review_at);

alter table public.learned_concepts enable row level security;

drop policy if exists "learned_concepts_own_all" on public.learned_concepts;
create policy "learned_concepts_own_all" on public.learned_concepts
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Eşleşmiş terapist okuyabilir (veli parent_id üzerinden).
drop policy if exists "learned_concepts_therapist_select" on public.learned_concepts;
create policy "learned_concepts_therapist_select" on public.learned_concepts
  for select to authenticated using (
    exists (
      select 1 from public.pairing_codes pc
      where pc.claimed_by = auth.uid()
        and pc.parent_id = learned_concepts.user_id
    )
  );

create table if not exists public.concept_interactions (
  id                bigint generated always as identity primary key,
  user_id           uuid not null references auth.users(id) on delete cascade,
  concept_key       text not null,
  interaction_type  text not null,
  correct           boolean,
  environment       text,
  created_at        timestamptz not null default now()
);

create index if not exists concept_interactions_user_time
  on public.concept_interactions (user_id, created_at desc);

alter table public.concept_interactions enable row level security;

drop policy if exists "concept_interactions_own_all" on public.concept_interactions;
create policy "concept_interactions_own_all" on public.concept_interactions
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
