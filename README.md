# ERR

Purpose of this package is to track all errors (and debug messages) in application as a tree
so you can quickly analyze what happend. It has automatic scope recognition, simple arguments passing
and many interesting features.

## Quick overview

All you need to do is add [err.log_module](./packages/err.spec.sql#log_module) calls to beginning of your every procedure.
There is a view [logs_check_missing_calls](./views/logs_check_missing_calls.sql) which will help you to track missing occurrences.

### Track module in tree

```sql
PROCEDURE your_procedure AS
BEGIN
    err.log_module();

    -- your code
    NULL;
END;
```

### Track module with arguments and timer

```sql
PROCEDURE your_procedure (
    in_argument1    VARCHAR2,
    in_argument2    NUMBER,
    in_argument3    DATE
) AS
BEGIN
    err.log_module(in_argument1, in_argument2, in_argument3);

    -- your code
    NULL;

    err.update_timer();
END;
```

### Track debugging info and possible warning

```sql
PROCEDURE your_procedure AS
BEGIN
    err.log_module();
    err.log_debug('I AM GOING TO DO SOMETHING');

    -- your code
    NULL;

    -- log result
    err.log_result('RESULT');

    -- log warning if needed
    IF TRUE THEN
        err.log_warning('THIS IS NOT GOOD');
    END IF;
END;
```

### Track app errors

```sql
PROCEDURE your_procedure AS
BEGIN
    err.log_module();

    -- your code
    NULL;

    -- log error if needed
    IF TRUE THEN
        err.log_error('THIS IS REALLY BAD');
    END IF;
END;
```

### Track app errors and raise exception

```sql
PROCEDURE your_procedure AS
BEGIN
    err.log_module();

    -- your code
    NULL;
EXCEPTION
WHEN OTHERS THEN
    err.raise_error();
END;
```

<br />

## LOGS table

Main table [LOGS](./tables/logs.sql) with daily partitions.

Context A, B, C columns are controlled by CTX package.

| ID | Column name                    | Data type        | NN | PK | Comment |
| -: | :----------------------------- | :--------------- | -- | -- | :------ |
|  1 | LOG_ID                         | NUMBER           | Y | Y | Error ID generated from sequence LOG_ID |
|  2 | LOG_PARENT                     | NUMBER           | N | N | Parent error to easily create tree; dont use FK to avoid deadlocks |
|  3 | APP_ID                         | NUMBER(4)        | N | N | APEX Application ID |
|  4 | PAGE_ID                        | NUMBER(6)        | N | N | APEX Application PAGE ID |
|  5 | USER_ID                        | VARCHAR2(30)     | Y | N | User ID |
|  6 | FLAG                           | CHAR(1)          | Y | N | Type of error listed in ERR package specification; FK missing for performance reasons |
|  7 | ACTION_NAME                    | VARCHAR2(32)     | Y | N | Action name to distinguish position in module or warning and error names |
|  8 | MODULE_NAME                    | VARCHAR2(64)     | Y | N | Module name (procedure or function name) |
|  9 | MODULE_LINE                    | NUMBER(8)        | Y | N | Line in the module |
| 10 | MODULE_DEPTH                   | NUMBER(4)        | Y | N | Depth of module in callstack |
| 11 | ARGUMENTS                      | VARCHAR2(2000)   | N | N | Arguments passed to module |
| 12 | MESSAGE                        | VARCHAR2(4000)   | N | N | Formatted call stack, error stack or query with DML error |
| 13 | CONTEXT_A                      | VARCHAR2(30)     | N | N | Your APP context; use more descriptive name |
| 14 | CONTEXT_B                      | VARCHAR2(30)     | N | N | Your APP context |
| 15 | CONTEXT_C                      | VARCHAR2(30)     | N | N | Your APP context |
| 16 | SCHEDULER_NAME                 | VARCHAR2(30)     | N | N | Scheduler name when log was initiated from DBMS_SCHEDULER |
| 17 | SCHEDULER_ID                   | NUMBER           | N | N | Scheduler ID to track down details |
| 18 | SESSION_DB                     | NUMBER           | N | N | Database session ID |
| 19 | SESSION_APEX                   | NUMBER           | N | N | APEX session ID |
| 20 | SCN                            | NUMBER           | N | N | System change number |
| 21 | TIMER                          | VARCHAR2(15)     | N | N | Timer for current row in seconds |
| 22 | CREATED_AT                     | TIMESTAMP        | Y | N | Timestamp of creation |

### Available flags

You can change these flags and add more in [ERR](./packages/err.spec.sql) package.

|  Flag | Function    | Description |
| ----: | :---------- | :---------- |
|     M | [LOG_MODULE](./packages/err.spec.sql)  | Module (procedure or function) called by user or inner module
|     A | [LOG_ACTION](./packages/err.spec.sql)  | Actions to distinguish different parts of code in longer modules
|     D | [LOG_DEBUG](./packages/err.spec.sql)   | Debug info |
|     R | [LOG_RESULT](./packages/err.spec.sql)  | Result of your calculation or query |
|     W | [LOG_WARNING](./packages/err.spec.sql) | Warning with optional action_name |
|     E | [LOG_ERROR](./packages/err.spec.sql)   | Error with optional action_name |
|     Q | [LOG_QUERY](./packages/err.spec.sql)   | Query with binded values recovered from DML error |

### Adjust tracking

You can adjust tracking for specific users, flags and/or modules by using blacklisted or whitelisted records
in [LOGS_TRACKING](./tables/logs_tracking.sql) table. Whitelisted row (TRACK=Y) precedes blacklisted (TRACK=N) row and you can use "%" as LIKE feature.

| ID | Column name                    | Data type        | NN | PK | Comment |
| -: | :----------------------------- | :--------------- | -- | -- | :------ |
|  1 | USER_ID                        | VARCHAR2(30)     | Y | Y | User ID; % for any user |
|  2 | MODULE_NAME                    | VARCHAR2(30)     | Y | Y | Module name; % for any module |
|  3 | FLAG                           | CHAR(1)          | Y | Y | Flag used in logs_log; % for any flag |
|  4 | TRACK                          | CHAR(1)          | Y | N | Y = track; N = dont track; Y > N |

