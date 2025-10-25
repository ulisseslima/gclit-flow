-- db
-- TODO auto update support
-- create database timesheet;

create table projects (id serial PRIMARY KEY, external_id text, name text unique not null);
insert into projects (name) select 'default';

create table tasks (
  id serial PRIMARY KEY, 
  external_id text,
  name text unique not null, 
  project_id bigint REFERENCES projects on DELETE CASCADE, 
  closed boolean not null default false, 
  start timestamp not null default now(), 
  finish timestamp, 
  elapsed interval not null default '0',
  repo varchar
);

create table executions (
  id serial PRIMARY KEY, 
  task_id bigint REFERENCES tasks on DELETE CASCADE, 
  start timestamp, 
  finish timestamp, 
  elapsed interval
);

create table comments (
  id serial PRIMARY KEY, 
  task_id bigint REFERENCES tasks on DELETE CASCADE, 
  stamp timestamp not null default now(), 
  content text
);

-- to activate debug: set client_min_messages to 'debug';
CREATE OR REPLACE FUNCTION similar_task(task_ varchar)
RETURNS TEXT AS $f$
DECLARE
  _result record;
BEGIN
  select 
    task.id,
    task.name,
    similarity(name, task_) similarity
  from tasks task 
  join executions e on e.task_id=task.id 
  where similarity(name, task_) > 0
  group by task.id 
  order by
    similarity desc,
    max(e.id) desc
  limit 1
  into _result;

  raise debug 'last: %', _result;
  RETURN _result.id||'|'||_result.name||'|'||_result.similarity;
END;
$f$ LANGUAGE plpgsql;

-- https://stackoverflow.com/questions/1839319/calculate-working-hours-between-2-dates-in-postgresql
CREATE OR REPLACE FUNCTION f_worktime_1day(_start timestamp, _end timestamp, _working_hours integer)
  RETURNS interval
  LANGUAGE sql IMMUTABLE AS
$func$  -- _start & _end within one calendar day! - you may want to check ...
SELECT CASE WHEN extract(ISODOW from _start) < 6 THEN (
   SELECT COALESCE(upper(h) - lower(h), '0')
   FROM  (
      SELECT tsrange '[2000-1-1 00:00, 2000-1-1 08:00)' -- hours hard coded
           * tsrange( '2000-1-1'::date + _start::time
                    , '2000-1-1'::date + _end::time ) AS h
      ) sub
   ) ELSE '0' END
$func$;

CREATE OR REPLACE FUNCTION f_worktime(_start timestamp, _end timestamp, _working_hours integer, OUT work_time interval)
LANGUAGE plpgsql IMMUTABLE AS
$func$
BEGIN
   CASE _end::date - _start::date  -- spanning how many days?
   WHEN 0 THEN                     -- all in one calendar day
      work_time := f_worktime_1day(_start, _end);
   WHEN 1 THEN                     -- wrap around midnight once
      work_time := f_worktime_1day(_start, NULL)
                +  f_worktime_1day(_end::date, _end);
   ELSE                            -- multiple days
      work_time := f_worktime_1day(_start, NULL)
                +  f_worktime_1day(_end::date, _end)
                + (SELECT count(*) * _working_hours*interval '01:00'
                   FROM   generate_series(_start::date + 1
                                        , _end::date   - 1, '1 day') AS t
                   WHERE  extract(ISODOW from t) < 6);
   END CASE;
END
$func$;

CREATE OR REPLACE FUNCTION f_worktime(_start timestamp, _end timestamp, OUT work_time interval)
LANGUAGE plpgsql IMMUTABLE AS
$func$
BEGIN
  work_time := f_worktime(_start, _end, 8);
END
$func$;

CREATE OR REPLACE FUNCTION f_worktime(_start timestamp, _end timestamp, OUT work_time interval)
LANGUAGE plpgsql IMMUTABLE AS
$func$
BEGIN
   CASE _end::date - _start::date  -- spanning how many days?
   WHEN 0 THEN                     -- all in one calendar day
      work_time := f_worktime_1day(_start, _end);
   WHEN 1 THEN                     -- wrap around midnight once
      work_time := f_worktime_1day(_start, NULL)
                +  f_worktime_1day(_end::date, _end);
   ELSE                            -- multiple days
      work_time := f_worktime_1day(_start, NULL)
                +  f_worktime_1day(_end::date, _end)
                + (SELECT count(*) * interval '08:00'
                   FROM   generate_series(_start::date + 1
                                        , _end::date   - 1, '1 day') AS t
                   WHERE  extract(ISODOW from t) < 6);
   END CASE;
END
$func$;