-- ============================================================
-- 叩命 (KouMing) Supabase 数据库 Schema
-- 项目: ibffrwevphkkbcfgaift
-- 表结构设计 v1.1
-- 更新: 2026-05-14 补充显式 GRANT 语句（Supabase 10月30日起不再默认授权）
-- ============================================================

-- Enable UUID extension
create extension if not exists "pgcrypto";

-- ============================================================
-- 1. users — 用户表
-- ============================================================
create table if not exists public.users (
  id          uuid primary key default gen_random_uuid(),
  device_id   text unique,           -- 设备ID（匿名用户标识）
  created_at  timestamptz default now(),
  updated_at  timestamptz default now(),
  nickname    text,
  avatar_url  text,
  merit       integer default 0,     -- 功德值
  total_wishes integer default 0,   -- 累计许愿数
  total_lanterns integer default 0, -- 累计点灯数
  total_draws  integer default 0,   -- 累计抽签数
  merit_level  integer default 1,   -- 功德等级 1-6
  title       text default '虔诚信众',
  last_active  timestamptz default now()
);

-- 自动更新 updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger users_updated_at
  before update on public.users
  for each row execute function public.handle_updated_at();

-- RLS
alter table public.users enable row level security;
create policy "Users can view own profile" on public.users
  for select using (true);
create policy "Users can update own profile" on public.users
  for update using (true);
create policy "Users can insert own profile" on public.users
  for insert with check (true);

-- GRANT: Data API 访问权限
GRANT SELECT, INSERT, UPDATE ON public.users TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT ALL ON public.users TO service_role;

-- ============================================================
-- 2. wishes — 愿望表
-- ============================================================
create table if not exists public.wishes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references public.users(id) on delete cascade,
  text        text not null,
  category    text not null,        -- study / love / money / other
  status      text default 'active', -- active / fulfilled / expired
  merit_cost  integer default 0,
  read_count  integer default 0,    -- 被阅读次数（他人捞愿时）
  created_at  timestamptz default now(),
  fulfilled_at timestamptz,
  expire_at   timestamptz            -- 自动过期时间
);

alter table public.wishes enable row level security;
create policy "Anyone can view wishes" on public.wishes
  for select using (true);
create policy "Users can insert own wishes" on public.wishes
  for insert with check (auth.uid() = user_id or device_id is not null);
create policy "Users can update own wishes" on public.wishes
  for update using (auth.uid() = user_id);

-- GRANT: Data API 访问权限
GRANT SELECT, INSERT ON public.wishes TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.wishes TO authenticated;
GRANT ALL ON public.wishes TO service_role;

-- ============================================================
-- 3. lantern_records — 点灯记录表
-- ============================================================
create table if not exists public.lantern_records (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references public.users(id) on delete set null,
  device_id   text,
  wish_id     uuid references public.wishes(id) on delete set null,
  count       integer default 1,
  created_at  timestamptz default now()
);

alter table public.lantern_records enable row level security;
create policy "Anyone can view lantern records" on public.lantern_records
  for select using (true);
create policy "Anyone can insert lantern records" on public.lantern_records
  for insert with check (true);

-- GRANT: Data API 访问权限
GRANT SELECT, INSERT ON public.lantern_records TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.lantern_records TO authenticated;
GRANT ALL ON public.lantern_records TO service_role;

-- ============================================================
-- 4. fortune_slips — 卦象记录表
-- ============================================================
create table if not exists public.fortune_slips (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references public.users(id) on delete set null,
  device_id     text,
  hexagram_name text,                -- 卦名
  category      text,                -- study/love/money/other
  reading_text  text,               -- AI生成的解读
  advice_text   text,                -- 建议
  similar_count integer default 0,   -- 相似愿望数
  fulfill_rate  numeric default 0,   -- 还愿率
  is_free       boolean default false,
  paid          boolean default false,
  price         numeric default 0,
  created_at    timestamptz default now()
);

alter table public.fortune_slips enable row level security;
create policy "Anyone can view fortune slips" on public.fortune_slips
  for select using (true);
create policy "Anyone can insert fortune slips" on public.fortune_slips
  for insert with check (true);

-- GRANT: Data API 访问权限
GRANT SELECT, INSERT ON public.fortune_slips TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.fortune_slips TO authenticated;
GRANT ALL ON public.fortune_slips TO service_role;

-- ============================================================
-- 5. wish_capsules — 愿望胶囊表
-- ============================================================
create table if not exists public.wish_capsules (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references public.users(id) on delete cascade,
  device_id   text,
  wish_id     uuid references public.wishes(id) on delete set null,
  unlock_date timestamptz not null,
  letter_text text,
  fulfilled   boolean default false,
  created_at  timestamptz default now(),
  fulfilled_at timestamptz
);

alter table public.wish_capsules enable row level security;
create policy "Anyone can view capsules" on public.wish_capsules
  for select using (true);
create policy "Users can insert capsules" on public.wish_capsules
  for insert with check (true);

-- GRANT: Data API 访问权限
GRANT SELECT, INSERT ON public.wish_capsules TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.wish_capsules TO authenticated;
GRANT ALL ON public.wish_capsules TO service_role;

-- ============================================================
-- 6. merit_logs — 功德日志（防刷）
-- ============================================================
create table if not exists public.merit_logs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references public.users(id) on delete cascade,
  action      text not null,          -- light_lantern / throw_wish / draw_fate / fulfill
  amount      integer not null,
  reason      text,
  created_at  timestamptz default now()
);

alter table public.merit_logs enable row level security;
create policy "Users can view own merit logs" on public.merit_logs
  for select using (true);
create policy "Anyone can insert merit logs" on public.merit_logs
  for insert with check (true);

-- GRANT: Data API 访问权限
GRANT SELECT, INSERT ON public.merit_logs TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.merit_logs TO authenticated;
GRANT ALL ON public.merit_logs TO service_role;

-- ============================================================
-- 7. payments — 支付记录表
-- ============================================================
create table if not exists public.payments (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid references public.users(id) on delete set null,
  device_id       text,
  product_type    text not null,      -- fortune / fate_draw / fulfillment
  amount          numeric not null,   -- 单位：元
  currency        text default 'CNY',
  stripe_payment_id text,
  status          text default 'pending', -- pending / completed / failed / refunded
  created_at      timestamptz default now(),
  completed_at    timestamptz
);

alter table public.payments enable row level security;
create policy "Users can view own payments" on public.payments
  for select using (true);
create policy "Anyone can insert payments" on public.payments
  for insert with check (true);

-- GRANT: Data API 访问权限
GRANT SELECT, INSERT ON public.payments TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.payments TO authenticated;
GRANT ALL ON public.payments TO service_role;

-- ============================================================
-- 8. global_stats — 全局统计（只读，供前台显示）
-- ============================================================
create table if not exists public.global_stats (
  id          integer primary key default 1 check (id = 1),
  total_wishes integer default 0,
  total_lanterns integer default 0,
  total_fulfillments integer default 0,
  updated_at  timestamptz default now()
);

alter table public.global_stats enable row level security;
create policy "Anyone can view global stats" on public.global_stats
  for select using (true);

-- GRANT: Data API 访问权限（global_stats 为只读统计表）
GRANT SELECT ON public.global_stats TO anon;
GRANT SELECT ON public.global_stats TO authenticated;
GRANT ALL ON public.global_stats TO service_role;

-- 初始化全局统计
insert into public.global_stats (id, total_wishes, total_lanterns, total_fulfillments)
values (1, 0, 0, 0)
on conflict (id) do nothing;

-- ============================================================
-- 统计触发器（自动更新 counts）
-- ============================================================
create or replace function public.increment_wish_count()
returns trigger as $$
begin
  update public.global_stats set
    total_wishes = total_wishes + 1,
    updated_at = now()
  where id = 1;
  update public.users set
    total_wishes = total_wishes + 1,
    last_active = now()
  where id = new.user_id;
  return new;
end;
$$ language plpgsql trigger;

create trigger after_wish_insert
  after insert on public.wishes
  for each row execute function public.increment_wish_count();

create or replace function public.increment_lantern_count()
returns trigger as $$
begin
  update public.global_stats set
    total_lanterns = total_lanterns + new.count,
    updated_at = now()
  where id = 1;
  return new;
end;
$$ language plpgsql trigger;

create trigger after_lantern_insert
  after insert on public.lantern_records
  for each row execute function public.increment_lantern_count();

create or replace function public.increment_fulfillment_count()
returns trigger as $$
begin
  update public.global_stats set
    total_fulfillments = total_fulfillments + 1,
    updated_at = now()
  where id = 1;
  return new;
end;
$$ language plpgsql trigger;

create trigger after_fulfillment
  after update on public.wish_capsules
  for each row when (new.fulfilled = true and old.fulfilled = false)
  execute function public.increment_fulfillment_count();
