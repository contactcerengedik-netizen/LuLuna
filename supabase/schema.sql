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

-- Terapist: kodu bildiği sürece satırı okuyabilir (kod tahmin edilemez).
drop policy if exists "pairing_read_by_code" on public.pairing_codes;
create policy "pairing_read_by_code" on public.pairing_codes
  for select to authenticated using (true);

-- Terapist: boş kodu kendine claim edebilir.
drop policy if exists "pairing_claim" on public.pairing_codes;
create policy "pairing_claim" on public.pairing_codes
  for update to authenticated
  using (claimed_by is null or claimed_by = auth.uid())
  with check (claimed_by = auth.uid());

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
