-- Education platform schema draft (PHASE 1).
-- Apply after profiles role expansion (004).

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  birth_date date,
  preferences jsonb not null default '{}'::jsonb,
  accessibility jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.student_skill_levels (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete cascade,
  skill text not null,
  tier text not null default 'easy',
  mastery_percent real not null default 0,
  unique (student_id, skill)
);

create table if not exists public.teacher_student (
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  primary key (teacher_id, student_id)
);

create table if not exists public.activities (
  id uuid primary key default gen_random_uuid(),
  skill text not null,
  category text not null,
  title text not null,
  difficulty text not null default 'easy',
  payload jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles (id),
  approved boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.activity_attempts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete cascade,
  activity_id uuid references public.activities (id) on delete set null,
  skill text not null,
  difficulty text not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  correct_count int not null default 0,
  wrong_count int not null default 0,
  attempt_count int not null default 1,
  score real,
  duration_ms int
);

alter table public.students enable row level security;
alter table public.student_skill_levels enable row level security;
alter table public.teacher_student enable row level security;
alter table public.activities enable row level security;
alter table public.activity_attempts enable row level security;
