-- db
-- create database timesheet;

create table projects (id serial PRIMARY KEY, external_id text, name text unique not null);
-- insert into projects (name) select 'default';

create table tasks (
  id serial PRIMARY KEY, 
  external_id text,
  name text unique not null, 
  project_id bigint REFERENCES projects on DELETE CASCADE, 
  closed boolean not null default false, 
  start timestamp not null default now(), 
  finish timestamp, 
  elapsed interval not null default '0'
);

create table executions (
  id serial PRIMARY KEY, 
  task_id bigint REFERENCES tasks on DELETE CASCADE, 
  start timestamp, 
  finish timestamp, 
  elapsed interval
);