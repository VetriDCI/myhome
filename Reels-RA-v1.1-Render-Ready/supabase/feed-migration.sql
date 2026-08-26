-- Base schema for Reels RA v1.1
-- Run this FIRST in Supabase SQL Editor, then run feed-migration.sql after.

-- 1. Profiles table (extends Supabase auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text,
  avatar_url text,
  bio text,
  followers_count int not null default 0,
  created_at timestamptz not null default now()
);

-- 2. Reels table
create table if not exists public.reels (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles(id) on delete cascade,
  caption text,
  video_url text not null,
  thumbnail_url text,
  status text not null default 'published',
  like_count int not null default 0,
  comment_count int not null default 0,
  created_at timestamptz not null default now()
);

-- Explicit FK name used by frontend query (reels_creator_id_fkey is default Postgres name, this ensures it)
alter table public.reels
  drop constraint if exists reels_creator_id_fkey,
  add constraint reels_creator_id_fkey foreign key (creator_id) references public.profiles(id) on delete cascade;

-- 3. Reel likes
create table if not exists public.reel_likes (
  reel_id uuid not null references public.reels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (reel_id, user_id)
);

-- 4. Reel comments
create table if not exists public.reel_comments (
  id uuid primary key default gen_random_uuid(),
  reel_id uuid not null references public.reels(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

alter table public.reel_comments
  drop constraint if exists reel_comments_user_id_fkey,
  add constraint reel_comments_user_id_fkey foreign key (user_id) references public.profiles(id) on delete cascade;

-- 5. Follows
create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id)
);

-- 6. Enable Row Level Security
alter table public.profiles enable row level security;
alter table public.reels enable row level security;
alter table public.reel_likes enable row level security;
alter table public.reel_comments enable row level security;
alter table public.follows enable row level security;

-- 7. Basic policies (adjust later as needed)
create policy "profiles are viewable by everyone" on public.profiles for select using (true);
create policy "users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

create policy "published reels are viewable by everyone" on public.reels for select using (status = 'published');
create policy "users can insert own reels" on public.reels for insert with check (auth.uid() = creator_id);
create policy "users can update own reels" on public.reels for update using (auth.uid() = creator_id);
create policy "users can delete own reels" on public.reels for delete using (auth.uid() = creator_id);

create policy "likes are viewable by everyone" on public.reel_likes for select using (true);
create policy "users can like as themselves" on public.reel_likes for insert with check (auth.uid() = user_id);
create policy "users can unlike own like" on public.reel_likes for delete using (auth.uid() = user_id);

create policy "comments are viewable by everyone" on public.reel_comments for select using (true);
create policy "users can comment as themselves" on public.reel_comments for insert with check (auth.uid() = user_id);

create policy "follows are viewable by everyone" on public.follows for select using (true);
create policy "users can follow as themselves" on public.follows for insert with check (auth.uid() = follower_id);
create policy "users can unfollow own follow" on public.follows for delete using (auth.uid() = follower_id);