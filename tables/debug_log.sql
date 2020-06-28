--DROP TABLE debug_log_lobs PURGE;
--DROP TABLE debug_log_tracking PURGE;
--DROP TABLE debug_log PURGE;
CREATE TABLE debug_log (
    log_id              NUMBER          NOT NULL,   -- NUMBER GENERATED BY DEFAULT AS IDENTITY NOT NULL
    log_parent          NUMBER,                     -- DONT PUT FK ON IT TO AVOID DEADLOCKS
    --
    app_id              NUMBER(4),
    page_id             NUMBER(6),
    user_id             VARCHAR2(30)    NOT NULL,
    flag                CHAR(1)         NOT NULL,
    --
    action_name         VARCHAR2(32)    NOT NULL,   -- 32 chars, DBMS_APPLICATION_INFO limit
    module_name         VARCHAR2(64)    NOT NULL,   -- 48 chars, DBMS_APPLICATION_INFO limit
    module_line         NUMBER(8)       NOT NULL,
    module_depth        NUMBER(4)       NOT NULL,
    --
    arguments           VARCHAR2(1000),
    message             VARCHAR2(4000),
    contexts            VARCHAR2(1000),
    --
    session_apex        NUMBER,
    session_db          NUMBER,
    scn                 NUMBER,
    --
    timer               VARCHAR2(15),
    created_at          TIMESTAMP       NOT NULL,
    --
    CONSTRAINT pk_debug_log PRIMARY KEY (log_id)
    --
    -- NO MORE CONSTRAINTS TO KEEP THIS AS FAST AS POSSIBLE
    --
)
PARTITION BY RANGE (created_at)
INTERVAL (NUMTODSINTERVAL(1, 'DAY')) (
    PARTITION P00 VALUES LESS THAN (TIMESTAMP '2020-01-01 00:00:00')
);
--
COMMENT ON TABLE  debug_log                  IS 'Various messages raised in application; daily partitions';
--
COMMENT ON COLUMN debug_log.log_id           IS 'Error ID generated from sequence LOG_ID';
COMMENT ON COLUMN debug_log.log_parent       IS 'Parent error to easily create tree; dont use FK to avoid deadlocks';
--
COMMENT ON COLUMN debug_log.module_name      IS 'Module name (procedure or function name)';
COMMENT ON COLUMN debug_log.module_line      IS 'Line in the module';
COMMENT ON COLUMN debug_log.module_depth     IS 'Depth of module in callstack';
--
COMMENT ON COLUMN debug_log.action_name      IS 'Action name to distinguish position in module or warning and error names';
COMMENT ON COLUMN debug_log.flag             IS 'Type of error listed in ERR package specification; FK missing for performance reasons';
--
COMMENT ON COLUMN debug_log.user_id          IS 'User ID';
COMMENT ON COLUMN debug_log.app_id           IS 'APEX Application ID';
COMMENT ON COLUMN debug_log.page_id          IS 'APEX Application PAGE ID';
--
COMMENT ON COLUMN debug_log.arguments        IS 'Arguments passed to module';
COMMENT ON COLUMN debug_log.message          IS 'Formatted call stack, error stack or query with DML error';
COMMENT ON COLUMN debug_log.contexts         IS 'Your APP contexts in time of creating log record';
--
COMMENT ON COLUMN debug_log.session_apex     IS 'APEX session ID';
COMMENT ON COLUMN debug_log.session_db       IS 'Database session ID';
COMMENT ON COLUMN debug_log.scn              IS 'System change number';
--
COMMENT ON COLUMN debug_log.timer            IS 'Timer for current row in seconds';
COMMENT ON COLUMN debug_log.created_at       IS 'Timestamp of creation';

