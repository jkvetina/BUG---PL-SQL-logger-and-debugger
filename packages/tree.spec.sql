CREATE OR REPLACE PACKAGE tree AS

    /**
     * This package is part of the Lumberjack project under MIT licence.
     * https://github.com/jkvetina/#lumberjack
     *
     * Copyright (c) Jan Kvetina, 2020
     *
     *                                                      (R)
     *                      ---                  ---
     *                    #@@@@@@              &@@@@@@
     *                    @@@@@@@@     .@      @@@@@@@@
     *          -----      @@@@@@    @@@@@@,   @@@@@@@      -----
     *       &@@@@@@@@@@@    @@@   &@@@@@@@@@.  @@@@   .@@@@@@@@@@@#
     *           @@@@@@@@@@@   @  @@@@@@@@@@@@@  @   @@@@@@@@@@@
     *             \@@@@@@@@@@   @@@@@@@@@@@@@@@   @@@@@@@@@@
     *               @@@@@@@@@   @@@@@@@@@@@@@@@  &@@@@@@@@
     *                 @@@@@@@(  @@@@@@@@@@@@@@@  @@@@@@@@
     *                  @@@@@@(  @@@@@@@@@@@@@@,  @@@@@@@
     *                  .@@@@@,   @@@@@@@@@@@@@   @@@@@@
     *                   @@@@@@  *@@@@@@@@@@@@@   @@@@@@
     *                   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
     *                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
     *                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@
     *                     .@@@@@@@@@@@@@@@@@@@@@@@@@
     *                       .@@@@@@@@@@@@@@@@@@@@@
     *                            jankvetina.cz
     *                               -------
     *
     */



    -- error log table name and max age fo records
    table_name              CONSTANT VARCHAR2(30)       := 'LOGS';  -- used in purge_old
    table_rows_max_age      CONSTANT PLS_INTEGER        := 14;      -- max logs age in days

    -- view which holds all DML errors
    view_dml_errors         CONSTANT VARCHAR2(30)       := 'LOGS_DML_ERRORS';
    view_logs_modules       CONSTANT VARCHAR2(30)       := 'LOGS_MODULES';

    -- flags
    flag_module             CONSTANT logs.flag%TYPE     := 'M';     -- start of any module (procedure/function)
    flag_action             CONSTANT logs.flag%TYPE     := 'A';     -- actions to distinguish different parts of code in longer modules
    flag_debug              CONSTANT logs.flag%TYPE     := 'D';     -- debug
    flag_info               CONSTANT logs.flag%TYPE     := 'I';     -- info (extended debug)
    flag_result             CONSTANT logs.flag%TYPE     := 'R';     -- result of procedure for debugging purposes
    flag_warning            CONSTANT logs.flag%TYPE     := 'W';     -- warning
    flag_error              CONSTANT logs.flag%TYPE     := 'E';     -- error
    flag_longops            CONSTANT logs.flag%TYPE     := 'L';     -- longops row
    flag_scheduler          CONSTANT logs.flag%TYPE     := 'S';     -- scheduler run planned
    flag_session            CONSTANT logs.flag%TYPE     := 'X';     -- SESS package calls (so you can ignore them)
    --
    flag_apex_page          CONSTANT logs.flag%TYPE     := 'P';     -- page visited/requested
    flag_apex_form          CONSTANT logs.flag%TYPE     := 'F';     -- form submitted
    flag_trigger            CONSTANT logs.flag%TYPE     := 'G';     -- called from trigger

    -- specify maximum length for trim
    length_action           CONSTANT PLS_INTEGER        := 48;      -- logs.action%TYPE
    length_arguments        CONSTANT PLS_INTEGER        := 1000;    -- logs.arguments%TYPE
    length_message          CONSTANT PLS_INTEGER        := 4000;    -- logs.message%TYPE
    length_contexts         CONSTANT PLS_INTEGER        := 1000;    -- logs.contexts%TYPE

    -- append callstack for these flags; % for all
    track_callstack         CONSTANT VARCHAR2(30)       := flag_error || flag_warning || flag_module || flag_result || flag_session;

    -- arguments separator
    splitter                CONSTANT CHAR               := '|';

    -- splitters for payload
    splitter_values         CONSTANT CHAR               := '=';
    splitter_rows           CONSTANT CHAR               := '|';
    splitter_package        CONSTANT CHAR               := '.';

    -- action is mandatory, so we need default value
    empty_action            CONSTANT CHAR               := '-';
    empty_user              CONSTANT CHAR               := '-';

    -- code for app exception
    app_exception_code      CONSTANT PLS_INTEGER        := -20000;
    app_exception           EXCEPTION;
    --
    PRAGMA EXCEPTION_INIT(app_exception, app_exception_code);

    -- owner of DML error tables
    dml_tables_owner        CONSTANT VARCHAR2(30)       := 'DEV';
    dml_tables_postfix      CONSTANT VARCHAR2(30)       := '_E$';

    -- arrays to specify adhoc requests
    TYPE arr_log_setup      IS VARRAY(100) OF logs_setup%ROWTYPE;

    -- list/array of log_id
    TYPE arr_logs_log_id IS
        TABLE OF logs.log_id%TYPE
        INDEX BY PLS_INTEGER;

    --
    curr_page_log_id        logs.log_id%TYPE;
    curr_page_stamp         logs.created_at%TYPE;





    -- ### Introduction
    --
    -- Best way to start is with [`logs`](./tables-logs) table.
    --





    -- ### Basic functionality
    --

    --
    -- Main function called at the very start of every app module (procedure, function)
    --
    FUNCTION log_module (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- ^
    --
    PROCEDURE log_module (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    -- Main function used as marker in longer modules; make sure to call `log_module` first
    --
    FUNCTION log_action (
        in_action       logs.action_name%TYPE,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- ^
    --
    PROCEDURE log_action (
        in_action       logs.action_name%TYPE,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    -- Store record in log with `D` flag
    --
    FUNCTION log_debug (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- ^
    --
    PROCEDURE log_debug (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    -- Store record in log with `R` flag
    --
    FUNCTION log_result (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- ^
    --
    PROCEDURE log_result (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    -- Store record in log with `W` flag; pass `action_name`
    --
    FUNCTION log_warning (
        in_action       logs.action_name%TYPE   := NULL,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- ^
    --
    PROCEDURE log_warning (
        in_action       logs.action_name%TYPE   := NULL,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    -- Store record in log with `E` flag; pass `action_name`
    --
    FUNCTION log_error (
        in_action       logs.action_name%TYPE   := NULL,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- ^
    --
    PROCEDURE log_error (
        in_action       logs.action_name%TYPE   := NULL,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    );



    --
    -- Log error and `RAISE` app exception `action_name|log_id`; pass `error_name` for user in action
    --
    PROCEDURE raise_error (
        in_action       logs.action_name%TYPE  := NULL,
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL,
        --
        in_rollback     BOOLEAN                 := FALSE,
        in_to_apex      BOOLEAN                 := FALSE
    );



    --
    -- Send error message to APEX; call `raise_error` first
    --
    PROCEDURE raise_to_apex (
        in_message          logs.message%TYPE
    );





    -- ### Tracking time and progress of long operations
    --

    --
    -- Calculate human readable difference within two timestamps
    --
    FUNCTION get_timestamp_diff (
        in_start        TIMESTAMP,
        in_end          TIMESTAMP       := NULL
    )
    RETURN logs.timer%TYPE;



    --
    -- Update `logs.timer` for current/requested record
    --
    PROCEDURE update_timer (
        in_log_id           logs.log_id%TYPE    := NULL
    );



    --
    -- Update `logs.message` for triggers so we can have module line with results
    --
    PROCEDURE update_trigger (
        in_log_id               logs.log_id%TYPE,
        in_rows_inserted        NUMBER              := NULL,
        in_rows_updated         NUMBER              := NULL,
        in_rows_deleted         NUMBER              := NULL,
        in_last_rowid           VARCHAR2            := NULL
    );



    --
    -- Update/track progress for LONGOPS
    --
    PROCEDURE log_progress (
        in_progress         NUMBER              := NULL  -- in percent (0-1)
    );





    -- ### Linking scheduler to correct `user_id` and `log_id`
    --

    --
    -- Log scheduler call and link its logs to this `log_id`
    --
    FUNCTION log_scheduler (
        in_log_id           logs.log_id%TYPE
    )
    RETURN logs.log_id%TYPE;



    --
    -- ^
    --
    PROCEDURE log_scheduler (
        in_log_id           logs.log_id%TYPE
    );



    --
    -- Create and start one time scheduler
    --
    PROCEDURE start_scheduler (
        in_job_name     VARCHAR2,
        in_statement    VARCHAR2        := NULL,
        in_comments     VARCHAR2        := NULL,
        in_priority     PLS_INTEGER     := NULL
    );





    -- ### Logging large objects
    --

    --
    -- Attach `BLOB` to current/requested `log_id`
    --
    PROCEDURE attach_blob (
        in_payload          logs_lobs.payload_blob%TYPE,
        in_lob_name         logs_lobs.lob_name%TYPE         := NULL,
        in_log_id           logs_lobs.log_id%TYPE           := NULL
    );



    --
    -- Attach `CLOB` to current/requested `log_id`
    --
    PROCEDURE attach_clob (
        in_payload          logs_lobs.payload_clob%TYPE,
        in_lob_name         logs_lobs.lob_name%TYPE         := NULL,
        in_log_id           logs_lobs.log_id%TYPE           := NULL
    );



    --
    -- Attach `XML` to current/requested `log_id`
    --
    PROCEDURE attach_xml (
        in_payload          logs_lobs.payload_xml%TYPE,
        in_lob_name         logs_lobs.lob_name%TYPE         := NULL,
        in_log_id           logs_lobs.log_id%TYPE           := NULL
    );



    --
    -- Attach `JSON` to current/requested `log_id`
    --
    PROCEDURE attach_json (
        in_payload          logs_lobs.payload_json%TYPE,
        in_lob_name         logs_lobs.lob_name%TYPE         := NULL,
        in_log_id           logs_lobs.log_id%TYPE           := NULL
    );





    -- ### Procedures related to DML error handling
    --

    --
    -- Creates `MERGE` query for selected `_E$` table and row
    --
    FUNCTION get_dml_query (
        in_log_id           logs.log_id%TYPE,
        in_table_name       logs.module_name%TYPE,
        in_table_rowid      VARCHAR2,
        in_action           CHAR  -- [I|U|D]
    )
    RETURN logs_lobs.payload_clob%TYPE;



    --
    -- Maps existing `DML` errors to proper row in `logs` table
    --
    PROCEDURE process_dml_error (
        in_log_id           logs.log_id%TYPE,
        in_error_table      VARCHAR2,   -- remove references to logs_dml_errors view
        in_table_name       VARCHAR2,   -- because it can get invalidated too often
        in_table_rowid      VARCHAR2,
        in_action           VARCHAR2
    );



    --
    -- Drop `DML` error tables matching filter
    --
    PROCEDURE drop_dml_tables (
        in_table_like       logs.module_name%TYPE
    );



    --
    -- Recreates `DML` error tables matching filter
    --
    PROCEDURE create_dml_tables (
        in_table_like       logs.module_name%TYPE
    );



    --
    -- Merge all `DML` error tables (`_E$`) into single view
    --
    PROCEDURE create_dml_errors_view;





    -- ### Logging environment variables
    --

    --
    -- Log requested `SYS_CONTEXT` values
    --
    PROCEDURE log_context (
        in_namespace        logs.arguments%TYPE     := '%',
        in_filter           logs.arguments%TYPE     := '%'
    );



    --
    -- Log session `NLS` parameters
    --
    PROCEDURE log_nls (
        in_filter           logs.arguments%TYPE     := '%'
    );



    --
    -- Log `USERENV` values
    --
    PROCEDURE log_userenv (
        in_filter           logs.arguments%TYPE     := '%'
    );



    --
    -- Log `CGI_ENV` values (when called from web/APEX)
    --
    PROCEDURE log_cgi (
        in_filter           logs.arguments%TYPE     := '%'
    );



    --
    -- Log business event
    --
    FUNCTION log_event (
        in_event_id         logs_events.event_id%TYPE,
        in_event_value      logs_events.event_value%TYPE    := NULL
    )
    RETURN logs_events.log_id%TYPE;



    --
    -- Log business event
    --
    PROCEDURE log_event (
        in_event_id         logs_events.event_id%TYPE,
        in_event_value      logs_events.event_value%TYPE    := NULL
    );





    -- ### Working with tree
    --

    --
    -- Returns last `log_id` for any flag
    --
    FUNCTION get_log_id
    RETURN logs.log_id%TYPE;



    --
    -- Returns last `log_id` for `E` flag
    --
    FUNCTION get_error_id
    RETURN logs.log_id%TYPE;



    --
    -- Finds and returns root `log_id` for passed `log_id`
    --
    FUNCTION get_root_id (
        in_log_id       logs.log_id%TYPE        := NULL
    )
    RETURN logs.log_id%TYPE;



    --
    -- Returns `log_id` used by `LOGS_TREE` view
    --
    FUNCTION get_tree_id
    RETURN logs.log_id%TYPE;



    --
    -- Set `log_id` for `LOGS_TREE` view
    --
    PROCEDURE set_tree_id (
        in_log_id       logs.log_id%TYPE
    );





    -- ### Call stack parsers
    --

    --
    -- Returns procedure name which called this function with possible offset
    --
    FUNCTION get_caller_name (
        in_offset           PLS_INTEGER     := 0,
        in_skip_this        BOOLEAN         := TRUE,
        in_attach_line      BOOLEAN         := FALSE
    )
    RETURN logs.module_name%TYPE;



    --
    -- Return detailed info about caller
    --
    PROCEDURE get_caller__ (
        in_log_id               logs.log_id%TYPE        := NULL,
        in_parent_id            logs.log_parent%TYPE    := NULL,
        in_flag                 logs.flag%TYPE          := NULL,
        out_module_name     OUT logs.module_name%TYPE,
        out_module_line     OUT logs.module_line%TYPE,
        out_parent_id       OUT logs.log_parent%TYPE
    )
    ACCESSIBLE BY (
        PACKAGE tree,
        PACKAGE tree_ut
    );



    --
    -- Returns clean call stack
    --
    FUNCTION get_call_stack
    RETURN logs.message%TYPE;



    --
    -- Returns error stack
    --
    FUNCTION get_error_stack
    RETURN logs.message%TYPE;





    -- ### Others
    --

    --
    -- Returns arguments merged into one string
    --
    FUNCTION get_arguments (
        in_arg1         logs.arguments%TYPE     := NULL,
        in_arg2         logs.arguments%TYPE     := NULL,
        in_arg3         logs.arguments%TYPE     := NULL,
        in_arg4         logs.arguments%TYPE     := NULL,
        in_arg5         logs.arguments%TYPE     := NULL,
        in_arg6         logs.arguments%TYPE     := NULL,
        in_arg7         logs.arguments%TYPE     := NULL,
        in_arg8         logs.arguments%TYPE     := NULL
    )
    RETURN logs.arguments%TYPE;



    --
    -- Update `DBMS_SESSION` and `DBMS_APPLICATION_INFO` with current module and action
    --
    PROCEDURE set_session (
        in_module_name      logs.module_name%TYPE,
        in_action_name      logs.action_name%TYPE
    );



    --
    -- Internal function which creates records in logs table; returns assigned `log_id`
    --
    FUNCTION log__ (
        in_action_name      logs.action_name%TYPE,
        in_flag             logs.flag%TYPE,
        in_arguments        logs.arguments%TYPE     := NULL,
        in_message          logs.message%TYPE       := NULL,
        in_parent_id        logs.log_parent%TYPE    := NULL
    )
    RETURN logs.log_id%TYPE
    ACCESSIBLE BY (
        PACKAGE tree,
        PACKAGE tree_ut
    );



    --
    -- Check if we log current record or not
    --
    FUNCTION is_listed (
        in_list         arr_log_setup,
        in_row          logs%ROWTYPE
    )
    RETURN BOOLEAN;



    --
    -- Reload settings and clear callstack maps
    --
    PROCEDURE init;





    -- ### Purging
    --

    --
    -- Purge old records from `logs` table
    --
    PROCEDURE purge_old (
        in_age          PLS_INTEGER := NULL
    );



    --
    -- Delete logs (children only)
    --
    PROCEDURE delete_children (
        in_log_id           logs.log_id%TYPE
    );



    --
    -- Delete logs (parent and children)
    --
    PROCEDURE delete_tree (
        in_log_id           logs.log_id%TYPE
    );

END;
/
