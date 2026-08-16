-- Learning goals (parent/therapist defined targets for a learner).
-- Local-first app still uses SharedPreferences; this table enables future sync.

create table if not exists public.learning_goals (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_by uuid not null references auth.users (id) on delete cascade,
  domain text not null,
  goal text not null,
  difficulty text not null default 'beginner',
  priority text not null default 'medium',
  environment text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_learning_goals_user
  on public.learning_goals (user_id, active, created_at desc);

alter table public.learning_goals enable row level security;

-- Learner / owner can read own goals.
create policy "learning_goals_select_own"
  on public.learning_goals for select
  using (auth.uid() = user_id or auth.uid() = created_by);

-- Parent/therapist creators can insert/update/delete their authored goals.
create policy "learning_goals_insert_creator"
  on public.learning_goals for insert
  with check (auth.uid() = created_by);

create policy "learning_goals_update_creator"
  on public.learning_goals for update
  using (auth.uid() = created_by);

create policy "learning_goals_delete_creator"
  on public.learning_goals for delete
  using (auth.uid() = created_by);

-- Therapist can read goals for learners linked via pairing (parent owns learner link).
create policy "learning_goals_select_therapist"
  on public.learning_goals for select
  using (
    exists (
      select 1
      from public.pairing_codes pc
      where pc.claimed_by = auth.uid()
        and pc.parent_id = learning_goals.created_by
    )
  );
