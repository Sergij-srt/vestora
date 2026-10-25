-- ==============================================================================
-- VESTORA · Supabase PostgreSQL Schema with Row Level Security (RLS)
-- Run this in your Supabase Project: SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. Enable UUID Extension
create extension if not exists "uuid-ossp";

-- 2. User Profiles Table (Synced with Supabase Auth)
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  email text,
  full_name text,
  avatar_url text,
  location text default 'Київ, Україна',
  preferred_style text default 'Quiet Luxury',
  currency text default 'UAH (₴)',
  size_system text default 'EUR / International',
  streak_days int default 14,
  created_at timestamptz default timezone('utc'::text, now()) not null,
  updated_at timestamptz default timezone('utc'::text, now()) not null
);

-- Enable RLS on profiles
alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can delete own profile"
  on public.profiles for delete
  using (auth.uid() = id);

-- 3. Clothing Items Table
create table if not exists public.clothing_items (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  brand text not null,
  category text not null,
  season text not null,
  color text not null,
  price numeric(12, 2) default 0.00,
  currency text default 'UAH',
  image_url text not null,
  gallery_images text[] default array[]::text[],
  source_url text,
  store_name text,
  fabric_composition text,
  size text,
  country_of_origin text,
  care_instructions text,
  label_photo_url text,
  receipt_photo_url text,
  wear_count int default 0,
  purchase_date timestamptz default timezone('utc'::text, now()),
  notes text,
  updated_at timestamptz default timezone('utc'::text, now()) not null
);

-- Enable RLS on clothing_items
alter table public.clothing_items enable row level security;

create policy "Users can view own clothes"
  on public.clothing_items for select
  using (auth.uid() = user_id);

create policy "Users can insert own clothes"
  on public.clothing_items for insert
  with check (auth.uid() = user_id);

create policy "Users can update own clothes"
  on public.clothing_items for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own clothes"
  on public.clothing_items for delete
  using (auth.uid() = user_id);

-- Indexes for lightning-fast queries
create index if not exists idx_clothing_items_user_id on public.clothing_items(user_id);
create index if not exists idx_clothing_items_category on public.clothing_items(category);
create index if not exists idx_clothing_items_season on public.clothing_items(season);

-- 4. Outfits & Planned Capsule Combinations Table
create table if not exists public.outfits (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  planned_date date,
  occasion text,
  weather_temp int,
  weather_condition text,
  aesthetic_vibe text,
  is_favorite boolean default false,
  is_worn boolean default false,
  comfort_score int default 95,
  item_ids text[] default array[]::text[],
  notes text,
  created_at timestamptz default timezone('utc'::text, now()) not null,
  updated_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.outfits enable row level security;

create policy "Users can manage own outfits"
  on public.outfits for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists idx_outfits_user_id on public.outfits(user_id);

-- 5. Wear Logs Table (For Cost-Per-Wear & Streaks)
create table if not exists public.wear_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  item_id text references public.clothing_items(id) on delete cascade not null,
  worn_on date default current_date not null,
  created_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.wear_logs enable row level security;

create policy "Users can manage own wear logs"
  on public.wear_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists idx_wear_logs_user_id on public.wear_logs(user_id);

-- 6. Storage Bucket for Wardrobe Images (Per-User Folder Isolation + 5 MB / Image MIME Guardrails)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'vestora-wardrobe',
  'vestora-wardrobe',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Public can view wardrobe photos"
  on storage.objects for select
  using (bucket_id = 'vestora-wardrobe');

create policy "Authenticated users can upload own wardrobe photos"
  on storage.objects for insert
  with check (
    bucket_id = 'vestora-wardrobe'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Authenticated users can update own wardrobe photos"
  on storage.objects for update
  using (
    bucket_id = 'vestora-wardrobe'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'vestora-wardrobe'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Authenticated users can delete own wardrobe photos"
  on storage.objects for delete
  using (
    bucket_id = 'vestora-wardrobe'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 7. Self-Service Account Deletion RPC (App Store Guideline 5.1.1(v) & Google Play Compliance)
create or replace function public.delete_own_user()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_own_user() from public, anon;
grant execute on function public.delete_own_user() to authenticated;
