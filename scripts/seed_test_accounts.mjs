#!/usr/bin/env node
/**
 * Supabase'te demo veli + terapist hesaplarını oluşturur.
 *
 *   node scripts/seed_test_accounts.mjs
 *
 * Dashboard → Authentication → Providers → Email → "Confirm email" kapalı
 * olmalı; aksi halde giriş için e-posta onayı gerekir.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const configPath = path.join(__dirname, '..', 'config', 'gemini.json');

if (!fs.existsSync(configPath)) {
  console.error('config/gemini.json bulunamadı.');
  process.exit(1);
}

const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
const url = String(config.SUPABASE_URL || '').replace(/\/$/, '');
const key = config.SUPABASE_ANON_KEY;
if (!url || !key) {
  console.error('SUPABASE_URL / SUPABASE_ANON_KEY eksik.');
  process.exit(1);
}

const accounts = [
  {
    email: 'veli@luluna.app',
    password: 'veli12',
    data: { display_name: 'Demo Veli' },
  },
  {
    email: 'terapi@luluna.app',
    password: 'terapi',
    data: { display_name: 'Demo Terapist' },
  },
];

async function signup(account) {
  const res = await fetch(`${url}/auth/v1/signup`, {
    method: 'POST',
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(account),
  });
  const body = await res.json().catch(() => ({}));
  return { status: res.status, body };
}

async function signIn(account) {
  const res = await fetch(`${url}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email: account.email,
      password: account.password,
    }),
  });
  const body = await res.json().catch(() => ({}));
  return { status: res.status, body };
}

for (const account of accounts) {
  const created = await signup(account);
  if (created.status === 200 || created.status === 201) {
    const id = created.body.user?.id?.slice(0, 8) ?? '?';
    console.log(`OK ${account.email} created (id=${id})`);
    continue;
  }

  const msg = created.body.msg || created.body.error_description || '';
  if (/already|registered|exists/i.test(msg) || created.status === 422) {
    const login = await signIn(account);
    if (login.status === 200) {
      console.log(`OK ${account.email} already exists — login works`);
    } else {
      console.log(
        `WARN ${account.email} exists but login failed: ` +
          `${login.status} ${login.body.msg || login.body.error_description || ''}`,
      );
    }
    continue;
  }

  console.log(`FAIL ${account.email}: ${created.status} ${msg}`);
}

console.log('\nDemo accounts:');
console.log('  Parent    → veli@luluna.app / veli12');
console.log('  Therapist → terapi@luluna.app / terapi');
