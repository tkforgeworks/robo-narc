-- TF3 (Traffic Fighter 3: Next Generation) shared leaderboard schema (contracts/leaderboard-api.md).
-- Apply once in the Supabase SQL editor (Dashboard -> SQL -> New query -> Run).
-- Idempotent: safe to re-run.

create table if not exists public.scores (
  id            bigint generated always as identity primary key,
  created_at    timestamptz not null default now(),
  name          text    not null,
  score         integer not null,
  correct       integer not null default 0,
  wrong         integer not null default 0,
  missed        integer not null default 0,
  empty         integer not null default 0,
  duration_sec  integer not null,
  client        text    not null default 'unknown',
  constraint scores_name_check     check (char_length(name) between 1 and 12 and name ~ '^[A-Za-z]+$'),
  constraint scores_score_check    check (score between -5000 and 50000),
  constraint scores_correct_check  check (correct >= 0),
  constraint scores_wrong_check    check (wrong >= 0),
  constraint scores_missed_check   check (missed >= 0),
  constraint scores_empty_check    check (empty >= 0),
  constraint scores_duration_check check (duration_sec between 10 and 600)
);

create index if not exists scores_score_desc_idx
  on public.scores (score desc, created_at asc);

alter table public.scores enable row level security;

drop policy if exists select_all on public.scores;
create policy select_all on public.scores
  for select to anon using (true);

drop policy if exists insert_valid on public.scores;
create policy insert_valid on public.scores
  for insert to anon with check (true);

-- No update or delete policies: rows are append-only for the anon role.

create or replace function public.rank_for_score(p_score integer)
returns integer
language sql
stable
security invoker
as $$
  select 1 + count(*)::integer from public.scores where score > p_score;
$$;

create or replace function public.top_scores(p_limit integer default 20)
returns table (rank integer, name text, score integer)
language sql
stable
security invoker
as $$
  select row_number() over (order by score desc, created_at asc)::integer as rank,
         name,
         score
  from public.scores
  order by score desc, created_at asc
  limit least(p_limit, 100);
$$;

grant usage on schema public to anon;
grant select, insert on public.scores to anon;
grant execute on function public.rank_for_score(integer) to anon;
grant execute on function public.top_scores(integer) to anon;
