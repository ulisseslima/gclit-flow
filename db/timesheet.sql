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