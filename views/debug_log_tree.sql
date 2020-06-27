CREATE OR REPLACE VIEW debug_log_tree AS
SELECT
    e.log_id,
    e.log_parent,
    e.app_id,
    e.page_id,
    e.user_id,
    e.flag,
    NULLIF(e.action_name, '-')                  AS action_name,
    LPAD(' ', (LEVEL - 1) * 4) || e.module_name AS module_name,
    e.module_line                               AS line,
    e.module_depth                              AS depth,
    e.arguments,
    e.message,
    e.contexts,
    e.scheduler_name,
    e.scheduler_id,
    e.session_db,
    e.session_apex,
    e.scn,
    e.timer,
    e.created_at
FROM debug_log e
CONNECT BY e.log_parent = PRIOR e.log_id
START WITH e.log_id     = bug.get_tree_id()
ORDER SIBLINGS BY e.log_id;