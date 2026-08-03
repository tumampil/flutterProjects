# Implementation Plan - Blog/Forum App (Job Assessment)

This plan outlines the steps to build a complete Blog/Forum application using Flutter, Provider, GoRouter, and Supabase. We will follow the existing project structure and ensure every file is thoroughly commented for learning purposes.

## Goals
- Build a functional Blog/Forum app with Authentication, Posts, Comments, and Profiles.
- Use Supabase for the backend (Auth, Database, Storage).
- Manage state with Provider and navigation with GoRouter.
- Provide a clear, commented codebase that acts as a learning guide.

## User Review Required

> [!IMPORTANT]
> You will need to set up your Supabase project. Please provide the **Project URL** and **Anon Key** from your Supabase dashboard (Settings -> API).
>
> Also, follow these manual steps in Supabase:
> 1.  **Disable Email Confirmation**: Go to Authentication -> Settings and disable "Confirm email".
> 2.  **Storage Buckets**: Create three public buckets: `avatars`, `post_images`, and `comment_images`.

## Supabase Database Schema (SQL)
Run the following SQL in your Supabase SQL Editor:

```sql
-- Profile table (stores user details)
create table profile (
  id uuid references auth.users not null primary key,
  updated_at timestamp with time zone,
  full_name text,
  avatar_url text
);

-- Posts table
create table posts (
  id uuid default gen_random_uuid() primary key,
  author_id uuid references profile(id) on delete cascade not null,
  content text,
  image_urls text[] default '{}',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Comments table
create table comments (
  id uuid default gen_random_uuid() primary key,
  post_id uuid references posts(id) on delete cascade not null,
  author_id uuid references profile(id) on delete cascade not null,
  content text,
  image_urls text[] default '{}',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Row Level Security (RLS)
alter table profile enable row level security;
alter table posts enable row level security;
alter table comments enable row level security;

-- Policies (Simplified for assessment)
create policy "Public profiles are viewable by everyone." on profile for select using (true);
create policy "Users can insert their own profile." on profile for insert with check (auth.uid() = id);
create policy "Users can update own profile." on profile for update using (auth.uid() = id);

create policy "Posts are viewable by everyone." on posts for select using (true);
create policy "Users can insert their own posts." on posts for insert with check (auth.uid() = author_id);
create policy "Users can update/delete own posts." on posts for all using (auth.uid() = author_id);

create policy "Comments are viewable by everyone." on comments for select using (true);
create policy "Users can insert their own comments." on comments for insert with check (auth.uid() = author_id);
create policy "Users can update/delete own comments." on comments for all using (auth.uid() = author_id);
```

## Proposed Changes

### 1. Project Initialization & Auth Setup
- **[MODIFY] [main.dart](file:///D:/development/flutterProjects/lib/main.dart)**: Initialize Supabase and wrap the app in multiple Providers (Auth, Post, Profile).
- **[NEW] [auth_service.dart](file:///D:/development/flutterProjects/lib/services/auth_service.dart)**: Handle Supabase Auth logic (Login, Register, Logout).
- **[NEW] [auth_provider.dart](file:///D:/development/flutterProjects/lib/provider/auth_provider.dart)**: Manage the user's auth state and session.

### 2. Authentication UI
- **[MODIFY] [login_page.dart](file:///D:/development/flutterProjects/lib/screens/login_page.dart)**: Create the login form.
- **[NEW] [register_page.dart](file:///D:/development/flutterProjects/lib/screens/register_page.dart)**: Create the registration form (Email & Password only).
- **[MODIFY] [app_router.dart](file:///D:/development/flutterProjects/lib/router/app_router.dart)**: Configure routes and add an Auth Guard.

### 3. Posts Module
- **[MODIFY] [post.dart](file:///D:/development/flutterProjects/lib/models/post.dart)**: Update the Post model to include author details and image URLs.
- **[NEW] [post_service.dart](file:///D:/development/flutterProjects/lib/services/post_service.dart)**: Handle Post CRUD operations with Supabase.
- **[MODIFY] [post_provider.dart](file:///D:/development/flutterProjects/lib/provider/post_provider.dart)**: Update to handle async data and pagination.
- **[MODIFY] [home_page.dart](file:///D:/development/flutterProjects/lib/screens/home_page.dart)**: Implement post listing, image previews, and pagination.
- **[NEW] [post_details_page.dart](file:///D:/development/flutterProjects/lib/screens/post_details_page.dart)**: View a single post and its comments.

### 4. Comments Module
- **[NEW] [comment.dart](file:///D:/development/flutterProjects/lib/models/comment.dart)**: Comment data model.
- **[NEW] [comment_service.dart](file:///D:/development/flutterProjects/lib/services/comment_service.dart)**: Handle Comment CRUD with Supabase.
- **[NEW] [comment_provider.dart](file:///D:/development/flutterProjects/lib/provider/comment_provider.dart)**: Manage comments for a specific post.

### 5. Profile Module
- **[NEW] [profile_page.dart](file:///D:/development/flutterProjects/lib/screens/profile_page.dart)**: User profile management (Name, Photo).
- **[NEW] [profile_provider.dart](file:///D:/development/flutterProjects/lib/provider/profile_provider.dart)**: Manage profile data updates.

## Verification Plan

### Automated Tests
- We will verify each feature by running the app and performing manual tests on each CRUD operation.

### Manual Verification
- **Auth**: Test Register -> Login -> Logout flow.
- **Posts**: Create a post with multiple images -> View in list -> Update -> Delete.
- **Comments**: Add comment to a post -> View -> Delete.
- **Profile**: Update name and upload profile picture.
- **Supabase**: Verify data and images are correctly stored in the dashboard.
