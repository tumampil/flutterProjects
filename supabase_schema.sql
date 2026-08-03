-- SUPABASE DATABASE SCHEMA
-- Run this SQL in your Supabase SQL Editor (https://app.supabase.com)

-- 1. PROFILE TABLE
-- Stores extra user information linked to the Auth system.
create table profile (
  id uuid references auth.users on delete cascade not null primary key,
  updated_at timestamp with time zone default now(),
  full_name text,
  avatar_url text
);

-- 2. POSTS TABLE
-- Stores blog/forum posts.
create table posts (
  id uuid default gen_random_uuid() primary key,
  author_id uuid references profile(id) on delete cascade not null,
  content text,
  image_urls text[] default '{}',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. COMMENTS TABLE
-- Stores comments on posts.
create table comments (
  id uuid default gen_random_uuid() primary key,
  post_id uuid references posts(id) on delete cascade not null,
  author_id uuid references profile(id) on delete cascade not null,
  content text,
  image_urls text[] default '{}',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. ROW LEVEL SECURITY (RLS)
-- This makes the database secure by default.
alter table profile enable row level security;
alter table posts enable row level security;
alter table comments enable row level security;

-- 5. POLICIES (Access Rules)

-- Profile: Anyone can see them, but users only edit their own.
create policy "Public profiles are viewable by everyone." on profile for select using (true);
create policy "Users can insert their own profile." on profile for insert with check (auth.uid() = id);
create policy "Users can update own profile." on profile for update using (auth.uid() = id);

-- Posts: Anyone can see them, but only authors can create/edit/delete.
create policy "Posts are viewable by everyone." on posts for select using (true);
create policy "Users can insert their own posts." on posts for insert with check (auth.uid() = author_id);
create policy "Users can update/delete own posts." on posts for all using (auth.uid() = author_id);

-- Comments: Anyone can see them, but only authors can create/edit/delete.
create policy "Comments are viewable by everyone." on comments for select using (true);
create policy "Users can insert their own comments." on comments for insert with check (auth.uid() = author_id);
create policy "Users can update/delete own comments." on comments for all using (auth.uid() = author_id);

-- 6. AUTOMATIC PROFILE CREATION
-- This function creates a row in the 'profile' table automatically when a user signs up.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profile (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;

-- Trigger to run the function above
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
