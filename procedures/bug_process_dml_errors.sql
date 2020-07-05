CREATE OR REPLACE PROCEDURE bug_process_dml_errors (
    in_table_like   VARCHAR2 := '%'
) AS
    --
    -- keep this procedure separated from BUG package
    -- because DEBUG_LOG_DML_ERRORS view can be invalidated too often
    --
BEGIN
    FOR c IN (
        SELECT
            d.log_id, d.table_name, d.table_rowid, d.action,
            bug.dml_tables_owner || '.' || d.table_name || bug.dml_tables_postfix AS error_table
        FROM debug_log_dml d
        JOIN debug_log e
            ON e.log_id     = d.log_id
        WHERE d.table_name  LIKE NVL(UPPER(in_table_like), '%')
    ) LOOP
        bug.process_dml_error (
            in_log_id           => c.log_id,
            in_error_table      => c.error_table,
            in_table_name       => c.table_name,
            in_table_rowid      => c.table_rowid,
            in_action           => c.action
        );
    END LOOP;
END;
/