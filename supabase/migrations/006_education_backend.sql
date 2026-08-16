-- PHASE 8: Education backend schema (tables + RLS).
-- Builds on 004 (roles) and 005 (draft tables). Safe to re-run.

-- ------------------------------------------------------------
-- Ensure core tables from 005 exist
-- ------------------------------------------------------------
create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  birth_date date,
  preferences jsonb not null default '{}'::jsonb,
  accessibility jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists students_profile_id_uidx
  on public.students (profile_id);

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

create table if not exists public.parent_student (
  parent_id uuid not null references public.profiles (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  primary key (parent_id, student_id)
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

-- Session-level attempt summary (005 name kept)
create table if not exists public.activity_attempts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete cascade,
  activity_id uuid references public.activities (id) on delete set null,
  skill text not null,
  category text,
  difficulty text not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  correct_count int not null default 0,
  wrong_count int not null default 0,
  attempt_count int not null default 1,
  score real,
  duration_ms int
);

alter table public.activity_attempts
  add column if not exists category text;

-- Per-question answers (analytics)
create table if not exists public.attempt_answers (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete cascade,
  session_id uuid references public.activity_attempts (id) on delete set null,
  skill text not null,
  category text not null,
  difficulty text not null,
  question_id text not null,
  given_answer text not null default '',
  correct boolean not null default false,
  attempted_at timestamptz not null default now(),
  duration_ms int
);

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  skill text not null,
  category text not null,
  difficulty text not null default 'easy',
  question_count int not null default 10,
  due_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.assignment_students (
  assignment_id uuid not null references public.assignments (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  status text not null default 'assigned',
  completed_at timestamptz,
  primary key (assignment_id, student_id)
);

create table if not exists public.ai_generated_content (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  skill text not null,
  category text not null,
  difficulty text not null default 'easy',
  status text not null default 'draft',
  payload jsonb not null default '{}'::jsonb,
  image_url text,
  approved boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.teacher_reports (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  title text not null default 'Öğrenci raporu',
  body text not null default '',
  metrics jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- RLS
-- ------------------------------------------------------------
alter table public.students enable row level security;
alter table public.student_skill_levels enable row level security;
alter table public.teacher_student enable row level security;
alter table public.parent_student enable row level security;
alter table public.activities enable row level security;
alter table public.activity_attempts enable row level security;
alter table public.attempt_answers enable row level security;
alter table public.assignments enable row level security;
alter table public.assignment_students enable row level security;
alter table public.ai_generated_content enable row level security;
alter table public.teacher_reports enable row level security;

-- students: own profile OR linked teacher/parent
drop policy if exists "students_select_own_or_linked" on public.students;
create policy "students_select_own_or_linked" on public.students
  for select to authenticated using (
    profile_id = auth.uid()
    or exists (
      select 1 from public.teacher_student ts
      where ts.student_id = students.id and ts.teacher_id = auth.uid()
    )
    or exists (
      select 1 from public.parent_student ps
      where ps.student_id = students.id and ps.parent_id = auth.uid()
    )
  );

drop policy if exists "students_insert_own" on public.students;
create policy "students_insert_own" on public.students
  for insert to authenticated with check (profile_id = auth.uid());

drop policy if exists "students_update_own_or_teacher" on public.students;
create policy "students_update_own_or_teacher" on public.students
  for update to authenticated using (
    profile_id = auth.uid()
    or exists (
      select 1 from public.teacher_student ts
      where ts.student_id = students.id and ts.teacher_id = auth.uid()
    )
  );

-- skill levels
drop policy if exists "skill_levels_select_linked" on public.student_skill_levels;
create policy "skill_levels_select_linked" on public.student_skill_levels
  for select to authenticated using (
    exists (
      select 1 from public.students s
      where s.id = student_skill_levels.student_id
        and (
          s.profile_id = auth.uid()
          or exists (
            select 1 from public.teacher_student ts
            where ts.student_id = s.id and ts.teacher_id = auth.uid()
          )
        )
    )
  );

drop policy if exists "skill_levels_write_linked" on public.student_skill_levels;
create policy "skill_levels_write_linked" on public.student_skill_levels
  for all to authenticated using (
    exists (
      select 1 from public.students s
      where s.id = student_skill_levels.student_id
        and (
          s.profile_id = auth.uid()
          or exists (
            select 1 from public.teacher_student ts
            where ts.student_id = s.id and ts.teacher_id = auth.uid()
          )
        )
    )
  )
  with check (
    exists (
      select 1 from public.students s
      where s.id = student_skill_levels.student_id
        and (
          s.profile_id = auth.uid()
          or exists (
            select 1 from public.teacher_student ts
            where ts.student_id = s.id and ts.teacher_id = auth.uid()
          )
        )
    )
  );

-- teacher_student
drop policy if exists "teacher_student_teacher" on public.teacher_student;
create policy "teacher_student_teacher" on public.teacher_student
  for all to authenticated
  using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());

drop policy if exists "parent_student_parent" on public.parent_student;
create policy "parent_student_parent" on public.parent_student
  for all to authenticated
  using (parent_id = auth.uid())
  with check (parent_id = auth.uid());

-- activities: approved visible to all auth; writers own rows
drop policy if exists "activities_select" on public.activities;
create policy "activities_select" on public.activities
  for select to authenticated using (
    approved = true or created_by = auth.uid()
  );

drop policy if exists "activities_write_own" on public.activities;
create policy "activities_write_own" on public.activities
  for all to authenticated
  using (created_by = auth.uid())
  with check (created_by = auth.uid());

-- attempts / answers: student own or their teacher
drop policy if exists "attempts_select_linked" on public.activity_attempts;
create policy "attempts_select_linked" on public.activity_attempts
  for select to authenticated using (
    exists (
      select 1 from public.students s
      where s.id = activity_attempts.student_id
        and (
          s.profile_id = auth.uid()
          or exists (
            select 1 from public.teacher_student ts
            where ts.student_id = s.id and ts.teacher_id = auth.uid()
          )
        )
    )
  );

drop policy if exists "attempts_insert_own_student" on public.activity_attempts;
create policy "attempts_insert_own_student" on public.activity_attempts
  for insert to authenticated with check (
    exists (
      select 1 from public.students s
      where s.id = activity_attempts.student_id and s.profile_id = auth.uid()
    )
  );

drop policy if exists "answers_select_linked" on public.attempt_answers;
create policy "answers_select_linked" on public.attempt_answers
  for select to authenticated using (
    exists (
      select 1 from public.students s
      where s.id = attempt_answers.student_id
        and (
          s.profile_id = auth.uid()
          or exists (
            select 1 from public.teacher_student ts
            where ts.student_id = s.id and ts.teacher_id = auth.uid()
          )
        )
    )
  );

drop policy if exists "answers_insert_own_student" on public.attempt_answers;
create policy "answers_insert_own_student" on public.attempt_answers
  for insert to authenticated with check (
    exists (
      select 1 from public.students s
      where s.id = attempt_answers.student_id and s.profile_id = auth.uid()
    )
  );

-- assignments
drop policy if exists "assignments_teacher" on public.assignments;
create policy "assignments_teacher" on public.assignments
  for all to authenticated
  using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());

drop policy if exists "assignment_students_select" on public.assignment_students;
create policy "assignment_students_select" on public.assignment_students
  for select to authenticated using (
    exists (
      select 1 from public.assignments a
      where a.id = assignment_students.assignment_id and a.teacher_id = auth.uid()
    )
    or exists (
      select 1 from public.students s
      where s.id = assignment_students.student_id and s.profile_id = auth.uid()
    )
  );

-- AI content
drop policy if exists "ai_content_teacher" on public.ai_generated_content;
create policy "ai_content_teacher" on public.ai_generated_content
  for all to authenticated
  using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());

drop policy if exists "ai_content_student_approved" on public.ai_generated_content;
create policy "ai_content_student_approved" on public.ai_generated_content
  for select to authenticated using (approved = true);

-- teacher reports
drop policy if exists "teacher_reports_own" on public.teacher_reports;
create policy "teacher_reports_own" on public.teacher_reports
  for all to authenticated
  using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());
