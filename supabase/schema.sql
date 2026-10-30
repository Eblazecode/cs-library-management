-- NEXTLIB starter schema. Review and apply in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text not null,
  category text not null default 'Computer Science',
  isbn text unique,
  copies_total integer not null default 1 check (copies_total >= 0),
  copies_available integer not null default 1 check (copies_available >= 0 and copies_available <= copies_total),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.books enable row level security;

-- Starter policy for authenticated staff. Configure Supabase Auth and staff roles
-- before production use. Do not enable anonymous write access.
create policy "Authenticated staff can read books"
  on public.books for select to authenticated using (true);

create policy "Authenticated staff can add books"
  on public.books for insert to authenticated with check (true);

create policy "Authenticated staff can update books"
  on public.books for update to authenticated using (true) with check (true);
