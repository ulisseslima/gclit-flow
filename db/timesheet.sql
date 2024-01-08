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