-- ============================================================
-- Luluna – Supabase şeması (v1)
-- Kullanım: Supabase Dashboard → SQL Editor → New query →
-- bu dosyanın tamamını yapıştır → Run.
-- Tekrar çalıştırmak güvenlidir (if not exists / or replace).
-- ============================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- 1) profiles — auth.users'a 1:1 uygulama profili (rol vs.)
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        text,
  display_name text,
  role         text check (role in ('parent', 'therapist')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles_own_select" on public.profiles;
create policy "profiles_own_select" on public.profiles
  for select to authenticated using (id = auth.uid());

drop policy if exists "profiles_own_insert" on public.profiles;
create policy "profiles_own_insert" on public.profiles
  for insert to authenticated with check (id = auth.uid());

drop policy if exists "profiles_own_update" on public.profiles;
create policy "profiles_own_update" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- ------------------------------------------------------------
-- 2) kvkk_consents — açık rıza kayıtları (yasal denetim izi)
-- ------------------------------------------------------------
create table if not exists public.kvkk_consents (
  user_id         uuid primary key references auth.users(id) on delete cascade,
  privacy_notice  boolean not null default false,
  data_processing boolean not null default false,
  health_data     boolean not null default false,
  mic_camera      boolean not null default false,
  consented_at    timestamptz
);

alter table public.kvkk_consents enable row level security;

drop policy if exists "kvkk_own_all" on public.kvkk_consents;
create policy "kvkk_own_all" on public.kvkk_consents
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ------------------------------------------------------------
-- 3) pairing_codes — veli davet kodu → terapist eşleşmesi
--    Kod bir "yetenek anahtarı"dır: bilen terapist claim edebilir.
-- ------------------------------------------------------------
create table if not exists public.pairing_codes (
  code         text primary key,
  parent_id    uuid not null references auth.users(id) on delete cascade,
  child_name   text not null,
  profile_json jsonb not null,
  parent_email text,
  claimed_by   uuid references auth.users(id) on delete set null,
  created_at   timestamptz not null default now()
);

alter table public.pairing_codes enable row level security;

-- Veli kendi kodlarını tam yönetir.
drop policy if exists "pairing_parent_all" on public.pairing_codes;
create policy "pairing_parent_all" on public.pairing_codes
  for all to authenticated using (parent_id = auth.uid()) with check (parent_id = auth.uid());

-- Terapist yalnızca daha önce kendisinin claim ettiği eşleşmeyi okuyabilir.
-- Davet kodu araması doğrudan SELECT ile değil, aşağıdaki SECURITY DEFINER
-- RPC üzerinden yapılır; böylece tablo taramasıyla çocuk profilleri sızmaz.
drop policy if exists "pairing_read_by_code" on public.pairing_codes;
drop policy if exists "pairing_therapist_select_claimed" on public.pairing_codes;
create policy "pairing_therapist_select_claimed" on public.pairing_codes
  for select to authenticated using (claimed_by = auth.uid());

-- Claim/release yalnızca RPC ile yapılır.
drop policy if exists "pairing_claim" on public.pairing_codes;

create or replace function public.claim_pairing_code(invite_code text)
returns table (
  code text,
  parent_id uuid,
  child_name text,
  profile_json jsonb,
  parent_email text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  caller uuid := auth.uid();
begin
  if caller is null then
    raise exception 'authentication_required';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = caller and p.role = 'therapist'
  ) then
    raise exception 'therapist_role_required';
  end if;

  return query
  update public.pairing_codes pc
  set claimed_by = caller
  where pc.code = upper(trim(invite_code))
    and (pc.claimed_by is null or pc.claimed_by = caller)
  returning
    pc.code,
    pc.parent_id,
    pc.child_name,
    pc.profile_json,
    pc.parent_email,
    pc.created_at;

  if not found then
    raise exception 'invalid_or_claimed_pairing_code';
  end if;
end;
$$;

create or replace function public.release_pairing_code(invite_code text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'authentication_required';
  end if;

  update public.pairing_codes
  set claimed_by = null
  where code = upper(trim(invite_code))
    and claimed_by = auth.uid();
end;
$$;

revoke all on function public.claim_pairing_code(text) from public;
revoke all on function public.release_pairing_code(text) from public;
grant execute on function public.claim_pairing_code(text) to authenticated;
grant execute on function public.release_pairing_code(text) to authenticated;

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller uuid := auth.uid();
begin
  if caller is null then
    raise exception 'authentication_required';
  end if;

  -- Uygulama tabloları FK cascade ile temizlenir; auth kullanıcısı da silinir.
  delete from auth.users where id = caller;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;

-- ------------------------------------------------------------
-- 4) assistant_logs — asistan olay akışı (rapor verisi)
-- ------------------------------------------------------------
create table if not exists public.assistant_logs (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  logged_at  timestamptz not null,
  type       text not null check (type in ('observation','intervention','praise','system')),
  message    text not null,
  created_at timestamptz not null default now()
);

create index if not exists assistant_logs_user_time
  on public.assistant_logs (user_id, logged_at desc);

alter table public.assistant_logs enable row level security;

-- Sahibi yazar ve okur.
drop policy if exists "logs_own_insert" on public.assistant_logs;
create policy "logs_own_insert" on public.assistant_logs
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "logs_own_select" on public.assistant_logs;
create policy "logs_own_select" on public.assistant_logs
  for select to authenticated using (user_id = auth.uid());

-- Eşleşmiş terapist, velinin loglarını okuyabilir.
drop policy if exists "logs_therapist_select" on public.assistant_logs;
create policy "logs_therapist_select" on public.assistant_logs
  for select to authenticated using (
    exists (
      select 1 from public.pairing_codes pc
      where pc.claimed_by = auth.uid()
        and pc.parent_id = assistant_logs.user_id
    )
  );

-- ------------------------------------------------------------
-- 5) therapist_rules — eşleşmiş terapistin çocuk için AI kuralları
-- ------------------------------------------------------------
create table if not exists public.therapist_rules (
  parent_id  uuid primary key references auth.users(id) on delete cascade,
  rules      jsonb not null default '[]'::jsonb,
  updated_by uuid not null references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now()
);

alter table public.therapist_rules enable row level security;

drop policy if exists "rules_parent_select" on public.therapist_rules;
create policy "rules_parent_select" on public.therapist_rules
  for select to authenticated using (parent_id = auth.uid());

drop policy if exists "rules_therapist_select" on public.therapist_rules;
create policy "rules_therapist_select" on public.therapist_rules
  for select to authenticated using (
    exists (
      select 1 from public.pairing_codes pc
      where pc.parent_id = therapist_rules.parent_id
        and pc.claimed_by = auth.uid()
    )
  );

drop policy if exists "rules_therapist_insert" on public.therapist_rules;
create policy "rules_therapist_insert" on public.therapist_rules
  for insert to authenticated with check (
    updated_by = auth.uid()
    and exists (
      select 1 from public.pairing_codes pc
      where pc.parent_id = therapist_rules.parent_id
        and pc.claimed_by = auth.uid()
    )
  );

drop policy if exists "rules_therapist_update" on public.therapist_rules;
create policy "rules_therapist_update" on public.therapist_rules
  for update to authenticated
  using (
    exists (
      select 1 from public.pairing_codes pc
      where pc.parent_id = therapist_rules.parent_id
        and pc.claimed_by = auth.uid()
    )
  )
  with check (
    updated_by = auth.uid()
    and exists (
      select 1 from public.pairing_codes pc
      where pc.parent_id = therapist_rules.parent_id
        and pc.claimed_by = auth.uid()
    )
  );
