-- Faz 11: motor path takip sapma skoru
alter table public.attempt_answers
  add column if not exists deviation_score real;
