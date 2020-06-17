-- db
-- create database if not exists timesheet;

create table projects (id serial, external_id text, name text unique not null);
create table executions (id serial, task_id bigint, start timestamp, finish timestamp, elapsed interval);
create table tasks (
  id serial, 
  external_id text,
  name text unique not null, 
  project_id bigint, 
  closed boolean not null default false, 
  start timestamp not null default now(), 
  finish timestamp, 
  elapsed interval not null default '0'
);