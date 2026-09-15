-- TF3 (Traffic Fighter 3: Next Generation) shared leaderboard schema, v2
-- (contracts/leaderboard-api.md): every submitted shift is a row in `shifts`;
-- the board shows one entry per email (that player's best shift) plus every
-- anonymous shift, numbered in arrival order. Clients never touch the table:
-- the anon role only gets the two RPCs at the bottom.
-- Apply once in the Supabase SQL editor (Dashboard -> SQL -> New query -> Run).
-- Idempotent: safe to re-run. Retires the v1 `scores` table and functions.

-- v1 objects: a different return type means the function must be dropped.
drop function if exists public.rank_for_score(integer);
drop function if exists public.top_scores(integer);
drop table if exists public.scores;

create sequence if not exists public.anonymous_seq;

create table if not exists public.shifts (
  id            bigint generated always as identity primary key,
  submission_id uuid    not null unique,
  created_at    timestamptz not null default now(),
  email         text,                 -- null = anonymous; never leaves the server
  first_name    text,
  last_initial  text,
  anon_no       integer,              -- set by trigger for anonymous shifts
  score         integer not null,
  correct       integer not null default 0,
  wrong         integer not null default 0,
  missed        integer not null default 0,
  empty         integer not null default 0,
  duration_sec  integer not null,
  client        text    not null default 'unknown',
  constraint shifts_identity_check check (
    (email is null and first_name is null and last_initial is null)
    or (email is not null and first_name is not null and last_initial is not null)),
  constraint shifts_email_check check (email is null or (
    char_length(email) <= 254 and email = lower(btrim(email))
    and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[A-Za-z]{2,}$')),
  constraint shifts_first_name_check check (first_name is null or
    (char_length(first_name) between 1 and 12 and first_name ~ '^[A-Za-z]+$')),
  constraint shifts_last_initial_check check (last_initial is null or last_initial ~ '^[A-Z]$'),
  constraint shifts_score_check    check (score between -5000 and 50000),
  constraint shifts_correct_check  check (correct >= 0),
  constraint shifts_wrong_check    check (wrong >= 0),
  constraint shifts_missed_check   check (missed >= 0),
  constraint shifts_empty_check    check (empty >= 0),
  constraint shifts_duration_check check (duration_sec between 10 and 600)
);

create index if not exists shifts_score_desc_idx on public.shifts (score desc, created_at asc);
create index if not exists shifts_email_idx on public.shifts (email);

-- Anonymous shifts are numbered in arrival order ("anonymous 07"); named ones are not.
create or replace function public.number_anonymous_shift()
returns trigger
language plpgsql
as $$
begin
  if new.email is null then
    new.anon_no := nextval('public.anonymous_seq');
  else
    new.anon_no := null;
  end if;
  return new;
end
$$;

drop trigger if exists shifts_number_anonymous on public.shifts;
create trigger shifts_number_anonymous
  before insert on public.shifts
  for each row execute function public.number_anonymous_shift();

-- The table is private. RLS with no policies closes the door even if a grant
-- slips through; the RPCs below run as their owner.
alter table public.shifts enable row level security;
revoke all on table public.shifts from anon, authenticated;
revoke all on sequence public.anonymous_seq from anon, authenticated;

-- One entry per player: the best shift of each email, and each anonymous shift.
-- Internal: not granted to clients.
create or replace function public.board_entries()
returns table (entry_key text, display_name text, score integer, created_at timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select distinct on (coalesce(s.email, 'anon:' || s.id::text))
         coalesce(s.email, 'anon:' || s.id::text) as entry_key,
         case when s.email is null
              then 'anonymous ' || lpad(s.anon_no::text, 2, '0')
              else s.first_name || ' ' || s.last_initial || '.'
         end as display_name,
         s.score,
         s.created_at
  from public.shifts s
  order by coalesce(s.email, 'anon:' || s.id::text), s.score desc, s.created_at asc;
$$;
revoke all on function public.board_entries() from public, anon, authenticated;

-- Ties share the better rank, the same rule submit_shifts uses.
create or replace function public.top_scores(p_limit integer default 20)
returns table (rank integer, name text, score integer)
language sql
stable
security definer
set search_path = public
as $$
  select rank() over (order by b.score desc)::integer as rank,
         b.display_name as name,
         b.score
  from public.board_entries() b
  order by b.score desc, b.created_at asc
  limit least(greatest(coalesce(p_limit, 20), 1), 100);
$$;

-- Inserts a batch (at most 50) and answers with one receipt per shift: the
-- player's rank, board name, and the score that rank is for (a returning
-- player's best). A resend of an already-stored submission_id inserts nothing
-- and still gets its receipt, so lost answers never duplicate rows. Any row
-- that fails a CHECK fails the whole batch (HTTP 400), which the client drops.
create or replace function public.submit_shifts(p_shifts jsonb)
returns table (submission_id uuid, rank integer, name text, best_score integer)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
begin
  if jsonb_typeof(p_shifts) <> 'array' or jsonb_array_length(p_shifts) > 50 then
    raise exception 'p_shifts must be an array of at most 50 shifts' using errcode = '22023';
  end if;

  insert into public.shifts (submission_id, email, first_name, last_initial,
                             score, correct, wrong, missed, empty, duration_sec, client)
  select (s->>'submission_id')::uuid,
         nullif(lower(btrim(s->>'email')), ''),
         nullif(btrim(s->>'first_name'), ''),
         nullif(upper(btrim(s->>'last_initial')), ''),
         (s->>'score')::integer,
         coalesce((s->>'correct')::integer, 0),
         coalesce((s->>'wrong')::integer, 0),
         coalesce((s->>'missed')::integer, 0),
         coalesce((s->>'empty')::integer, 0),
         (s->>'duration_sec')::integer,
         coalesce(nullif(btrim(s->>'client'), ''), 'unknown')
  from jsonb_array_elements(p_shifts) s
  on conflict (submission_id) do nothing;

  return query
  with wanted as (
    select (w.value->>'submission_id')::uuid as sid, w.ordinality
    from jsonb_array_elements(p_shifts) with ordinality w
  ),
  board as (
    select * from public.board_entries()
  )
  select sh.submission_id,
         (1 + (select count(*) from board o where o.score > b.score))::integer,
         b.display_name,
         b.score
  from wanted
  join public.shifts sh on sh.submission_id = wanted.sid
  join board b on b.entry_key = coalesce(sh.email, 'anon:' || sh.id::text)
  order by wanted.ordinality;
end
$$;

grant usage on schema public to anon;
grant execute on function public.top_scores(integer) to anon;
grant execute on function public.submit_shifts(jsonb) to anon;
