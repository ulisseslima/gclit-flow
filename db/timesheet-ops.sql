-- play
WITH open_execution AS (
  select * from executions where task_id = 1 AND finish is null
) INSERT INTO executions
  (task_id, start) 
   SELECT 1, now() 
   WHERE NOT EXISTS (SELECT * FROM open_execution)
   RETURNING *
;

-- pause
WITH execution AS (
 UPDATE executions 
 SET finish = now(), elapsed = (now() - start)
 WHERE task_id = 1 AND finish is null
 RETURNING *
) update tasks set elapsed = elapsed + (select elapsed from execution)
  where id = 1
  returning *
;

-- total elapsed
select sum(elapsed) from executions where task_id = 1;

-- new task
WITH existing_task AS (
  select * from tasks 
  where name = 'tre' and project_id = 1
) INSERT INTO tasks
  (name, project_id) 
   SELECT 'tre', 1 
   WHERE NOT EXISTS (SELECT * FROM existing_task)
   RETURNING *
;

-- deliver task
update tasks set closed = true where id = 4;