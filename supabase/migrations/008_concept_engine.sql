-- Faz 8: Kavram motoru tabloları (prompt v3 §2.1)

create table if not exists public.concepts (
  id text primary key,
  name text not null,
  category text not null default 'other',
  image_prompt_seed text not null default '',
  related_skills jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.concept_assignments (
  id uuid primary key default gen_random_uuid(),
  concept_id text not null references public.concepts (id),
  student_id uuid not null references public.students (id) on delete cascade,
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'draft',
  consistency_group_id text,
  created_at timestamptz not null default now()
);

create table if not exists public.concept_module_outputs (
  id uuid primary key default gen_random_uuid(),
  concept_assignment_id uuid not null
    references public.concept_assignments (id) on delete cascade,
  module text not null,
  generated_content_id text,
  status text not null default 'pending',
  preview_title text,
  preview_body text,
  image_seed text,
  created_at timestamptz not null default now()
);

alter table public.concepts enable row level security;
alter table public.concept_assignments enable row level security;
alter table public.concept_module_outputs enable row level security;

drop policy if exists "concepts_read_auth" on public.concepts;
create policy "concepts_read_auth" on public.concepts
  for select to authenticated using (true);

drop policy if exists "concept_assignments_teacher" on public.concept_assignments;
create policy "concept_assignments_teacher" on public.concept_assignments
  for all to authenticated
  using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());

drop policy if exists "concept_outputs_via_assignment" on public.concept_module_outputs;
create policy "concept_outputs_via_assignment" on public.concept_module_outputs
  for all to authenticated using (
    exists (
      select 1 from public.concept_assignments a
      where a.id = concept_module_outputs.concept_assignment_id
        and a.teacher_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.concept_assignments a
      where a.id = concept_module_outputs.concept_assignment_id
        and a.teacher_id = auth.uid()
    )
  );
