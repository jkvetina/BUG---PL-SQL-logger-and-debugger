--DROP TABLE logs_lobs     PURGE;
--DROP TABLE logs_setup    PURGE;
--DROP TABLE logs          PURGE;
CREATE TABLE logs (
    log_id              INTEGER        NOT NULL,    -- NUMBER GENERATED BY DEFAULT AS IDENTITY NOT NULL
    log_parent          INTEGER,                    -- DONT PUT FK ON IT TO AVOID DEADLOCKS
    --
    app_id              NUMBER(4)       NOT NULL,
    page_id             NUMBER(6),
    user_id             VARCHAR2(30)    NOT NULL,
    flag                CHAR(1)         NOT NULL,
    --
    action_name         VARCHAR2(32)    NOT NULL,   -- 32 chars, DBMS_APPLICATION_INFO limit
    module_name         VARCHAR2(64)    NOT NULL,   -- 48 chars, DBMS_APPLICATION_INFO limit
    module_line         NUMBER(8)       NOT NULL,
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
    CONSTRAINT pk_logs PRIMARY KEY (log_id)
    --
    -- NO MORE CONSTRAINTS TO KEEP THIS AS FAST AS POSSIBLE
    --
)
PARTITION BY RANGE (created_at)
INTERVAL (NUMTODSINTERVAL(1, 'DAY')) (
    PARTITION P00 VALUES LESS THAN (TIMESTAMP '2020-01-01 00:00:00')
);
--
COMMENT ON TABLE  logs                  IS 'Various messages raised in application; daily partitions';
--
COMMENT ON COLUMN logs.log_id           IS 'Log ID generated from `LOG_ID` sequence';
COMMENT ON COLUMN logs.log_parent       IS 'Parent log record; dont use FK to avoid deadlocks';
--
COMMENT ON COLUMN logs.user_id          IS 'User ID';
COMMENT ON COLUMN logs.app_id           IS 'APEX Application ID';
COMMENT ON COLUMN logs.page_id          IS 'APEX Application PAGE ID';
COMMENT ON COLUMN logs.flag             IS 'Type of error listed in `bug` package specification; FK missing for performance reasons';
--
COMMENT ON COLUMN logs.action_name      IS 'Action name to distinguish position in module or use it as warning/error names';
COMMENT ON COLUMN logs.module_name      IS 'Module name (procedure or function name)';
COMMENT ON COLUMN logs.module_line      IS 'Line in the module';
--
COMMENT ON COLUMN logs.arguments        IS 'Arguments passed to module';
COMMENT ON COLUMN logs.message          IS 'Formatted call stack, error stack or query with DML error';
COMMENT ON COLUMN logs.contexts         IS 'Your APP contexts in time of creating log record';
--
COMMENT ON COLUMN logs.session_apex     IS 'APEX session ID';
COMMENT ON COLUMN logs.session_db       IS 'Database session ID';
COMMENT ON COLUMN logs.scn              IS 'System change number';
--
COMMENT ON COLUMN logs.timer            IS 'Timer for current row in seconds';
COMMENT ON COLUMN logs.created_at       IS 'Timestamp of creation';
