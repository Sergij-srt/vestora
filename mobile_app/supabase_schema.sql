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
  using (auth.uid() = id);

create policy "Users can insert own profile" 
  on public.profiles for insert 
  with check (auth.uid() = id);

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
  using (auth.uid() = user_id);

create policy "Users can delete own clothes" 
  on public.clothing_items for delete 
  using (auth.uid() = user_id);

-- Indexes for lightning-fast queries
create index if not exists idx_clothing_items_user_id on public.clothing_items(user_id);
create index if not exists idx_clothing_items_category on public.clothing_items(category);
create index if not exists idx_clothing_items_season on public.clothing_items(season);

-- 4. Outfits & Capsule Combinations Table
create table if not exists public.outfits (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  aesthetic_vibe text,
  is_favorite boolean default false,
  comfort_score int default 95,
  item_ids text[] default array[]::text[],
  created_at timestamptz default timezone('utc'::text, now()) not null
);

alter table public.outfits enable row level security;

create policy "Users can manage own outfits" 
  on public.outfits for all 
  using (auth.uid() = user_id);

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
  using (auth.uid() = user_id);

-- 6. Storage Bucket for Wardrobe Images
insert into storage.buckets (id, name, public)
values ('vestora-wardrobe', 'vestora-wardrobe', true)
on conflict (id) do nothing;

create policy "Public can view wardrobe photos"
  on storage.objects for select
  using (bucket_id = 'vestora-wardrobe');

create policy "Authenticated users can upload wardrobe photos"
  on storage.objects for insert
  with check (bucket_id = 'vestora-wardrobe' and auth.role() = 'authenticated');
