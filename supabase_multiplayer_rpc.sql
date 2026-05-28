-- Atomic multiplayer RPCs for VoidGuess matches.
-- Run this in Supabase SQL editor after adding matches.players and host_player_id.

create extension if not exists pgcrypto;

create or replace function public.join_match(
  p_code text,
  p_player_name text,
  p_rank_index integer
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_player_id text := gen_random_uuid()::text;
  v_joined boolean := false;
begin
  update public.matches
  set players = players || jsonb_build_array(
    jsonb_build_object(
      'id', v_player_id,
      'name', p_player_name,
      'rankIndex', p_rank_index,
      'ready', false,
      'results', '[]'::jsonb
    )
  )
  where code = p_code
    and status = 'waiting'
    and jsonb_typeof(players) = 'array'
    and jsonb_array_length(players) < 4
  returning true into v_joined;

  if v_joined then
    return v_player_id;
  end if;

  return null;
end;
$$;

create or replace function public.set_player_ready(
  p_code text,
  p_player_id text,
  p_ready boolean
)
returns void
language sql
security definer
set search_path = public
as $$
  update public.matches as m
  set players = (
    select jsonb_agg(
      case
        when player.value ->> 'id' = p_player_id then
          jsonb_set(player.value, '{ready}', to_jsonb(p_ready), true)
        else player.value
      end
      order by player.ordinality
    )
    from jsonb_array_elements(m.players) with ordinality as player(value, ordinality)
  )
  where m.code = p_code
    and exists (
      select 1
      from jsonb_array_elements(m.players) as player(value)
      where player.value ->> 'id' = p_player_id
    );
$$;

create or replace function public.set_match_game(
  p_code text,
  p_game_key text
)
returns void
language sql
security definer
set search_path = public
as $$
  update public.matches as m
  set
    game_key = p_game_key,
    players = (
      select jsonb_agg(
        jsonb_set(player.value, '{ready}', 'false'::jsonb, true)
        order by player.ordinality
      )
      from jsonb_array_elements(m.players) with ordinality as player(value, ordinality)
    )
  where m.code = p_code
    and m.status = 'waiting';
$$;

create or replace function public.submit_player_result(
  p_code text,
  p_player_id text,
  p_round_index integer,
  p_result jsonb
)
returns void
language sql
security definer
set search_path = public
as $$
  update public.matches as m
  set players = (
    select jsonb_agg(
      case
        when player.value ->> 'id' = p_player_id then
          jsonb_set(
            player.value,
            '{results}',
            coalesce(player.value -> 'results', '[]'::jsonb) || p_result,
            true
          )
        else player.value
      end
      order by player.ordinality
    )
    from jsonb_array_elements(m.players) with ordinality as player(value, ordinality)
  )
  where m.code = p_code
    and exists (
      select 1
      from jsonb_array_elements(m.players) as player(value)
      where player.value ->> 'id' = p_player_id
        and not exists (
          select 1
          from jsonb_array_elements(coalesce(player.value -> 'results', '[]'::jsonb)) as result(value)
          where (result.value ->> 'roundIndex')::integer = p_round_index
        )
    );
$$;
