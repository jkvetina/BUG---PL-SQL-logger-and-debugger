CREATE OR REPLACE PACKAGE BODY git.ctx_ut AS

    PROCEDURE before_all AS
    BEGIN
        NULL;
    END;



    PROCEDURE after_all AS
    BEGIN
        ROLLBACK;
    EXCEPTION
    WHEN PROGRAM_ERROR THEN
        NULL;
    END;



    PROCEDURE before_each AS
    BEGIN
        NULL;
    END;



    PROCEDURE after_each AS
    BEGIN
        ROLLBACK;
    END;



    PROCEDURE set_context AS
        curr_value      contexts.payload%TYPE;
    BEGIN
        FOR c IN (
            SELECT 'TEST' AS name, '1'  AS value FROM DUAL-- UNION ALL
            --SELECT 'TEST' AS name, NULL AS value FROM DUAL
        ) LOOP
            -- make sure current value is empty
            curr_value := SYS_CONTEXT(ctx.app_namespace, c.name);
            --
            ut.expect(curr_value).to_be_null();

            -- set new value and verify
            ctx.set_context (
                in_name     => c.name,
                in_value    => c.value
            );
            --
            curr_value := SYS_CONTEXT(ctx.app_namespace, c.name);
            --
            ut.expect(curr_value).to_equal(c.value);
            --
            curr_value := ctx.get_context(c.name);  -- get_context test
            --
            ut.expect(curr_value).to_equal(c.value);
        END LOOP;
    END;



    PROCEDURE set_context#user_id AS
        exp_user_id     contexts.user_id%TYPE := 'TEST_USER';
        curr_user_id    contexts.user_id%TYPE;
        new_user_id     contexts.user_id%TYPE := 'ANOTHER_USER';
    BEGIN
        -- make sure we have set some user
        ctx.set_user_id(exp_user_id);
        curr_user_id := ctx.get_user_id();
        --
        ut.expect(curr_user_id).to_equal(exp_user_id);  -- get_user_id test

        -- try to change user_id thru regular set_context
        BEGIN
            ctx.set_context (
                in_name     => ctx.app_user_id,
                in_value    => new_user_id
            );
            ut.fail('NO_EXCEPTION_RAISED');
        EXCEPTION
        WHEN OTHERS THEN
            -- exception expected
            IF SQLCODE != -20000 THEN
                ut.fail('WRONG_EXCEPTION_RAISED');
            END IF;
        END;

        -- check that user_id was not modified
        curr_user_id := SYS_CONTEXT(ctx.app_namespace, ctx.app_user_id);
        --
        ut.expect(curr_user_id).to_equal(exp_user_id);
    END;



    PROCEDURE save_contexts AS
        curr_user_id    CONSTANT contexts.user_id%TYPE  := 'TESTER__';
        --curr_app_id     CONSTANT contexts.app_id%TYPE   := 0;
        --
        test_string     CONSTANT VARCHAR2(30)   := 'TODAY';
        test_number     CONSTANT VARCHAR2(30)   := 3.1415;
        test_date       CONSTANT DATE           := SYSDATE;
        test_extra      CONSTANT VARCHAR2(30)   := 'EXTRA';
        --
        curr_payload    contexts.payload%TYPE;
        curr_timestamp  contexts.updated_at%TYPE;
        upd_payload     contexts.payload%TYPE;
        upd_timestamp   contexts.updated_at%TYPE;
        exp_payload     contexts.payload%TYPE;
    BEGIN
        -- clear contexts and set user
        ctx.init(curr_user_id);

        -- set some contexts
        ctx.set_context('STRING',   test_string);
        ctx.set_context('NUMBER',   test_number);
        ctx.set_context('DATE',     test_date);

        -- delete records for user
        DELETE FROM contexts t
        WHERE t.user_id = curr_user_id;
        --
        COMMIT;

        -- test insert
        ctx.save_contexts();
        --
        exp_payload := ctx.get_payload();
        --
        SELECT t.payload, t.updated_at
        INTO curr_payload, curr_timestamp
        FROM contexts t
        WHERE t.user_id = curr_user_id;
        --
        ut.expect(curr_payload).to_equal(exp_payload);

        -- alter contexts
        ctx.set_context('DATE',     test_date + 1/24);  -- change existing context
        ctx.set_context('EXTRA',    test_extra);        -- add one more

        -- test update
        ctx.save_contexts();
        --
        SELECT t.payload, t.updated_at
        INTO upd_payload, upd_timestamp
        FROM contexts t
        WHERE t.user_id = curr_user_id;
        --
        ut.expect(upd_payload).to_equal(ctx.get_payload());
        --
        ut.expect(upd_timestamp).to_be_greater_than(curr_timestamp);    -- check timestamp
        --
        curr_payload := ctx.get_payload();
        --
        ut.expect(curr_payload).not_to_equal(exp_payload);
        --
        ut.expect(curr_payload).to_equal(upd_payload);

        -- check session_db
        --
        -- @TODO;
        --
    END;



    PROCEDURE load_contexts AS
        curr_user_id    CONSTANT contexts.user_id%TYPE  := 'TESTER__';
        --curr_app_id     CONSTANT contexts.app_id%TYPE   := 0;
        --
        test_string     CONSTANT VARCHAR2(30)   := 'TODAY';
        test_number     CONSTANT VARCHAR2(30)   := 3.1415;
        test_date       CONSTANT DATE           := SYSDATE;
        test_extra      CONSTANT VARCHAR2(30)   := 'EXTRA';
        --
        count_contexts  PLS_INTEGER;
        r_expected      SYS_REFCURSOR;
        r_current       SYS_REFCURSOR;
    BEGIN
        -- clear contexts and set user
        ctx.init(curr_user_id);

        -- set some contexts
        ctx.set_context('STRING',   test_string);
        ctx.set_context('NUMBER',   test_number);
        ctx.set_context('DATE',     test_date);

        -- delete records for user
        DELETE FROM contexts t
        WHERE t.user_id = curr_user_id;
        --
        COMMIT;

        -- update table
        ctx.save_contexts();

        -- clear current contexts
        ctx.init();

        -- check number of contexts, zero is expected
        SELECT COUNT(*) INTO count_contexts
        FROM session_context s
        WHERE s.namespace = ctx.app_namespace;
        --
        ut.expect(count_contexts).to_equal(0);

        -- load contexts for current user
        ctx.load_contexts (
            in_user_id => curr_user_id
        );

        -- check contexts
        OPEN r_expected FOR
            SELECT ctx.app_user_id  AS name,    curr_user_id                                AS value FROM DUAL UNION ALL
            SELECT 'STRING'         AS name,    test_string                                 AS value FROM DUAL UNION ALL
            SELECT 'NUMBER'         AS name,    TO_CHAR(test_number)                        AS value FROM DUAL UNION ALL
            SELECT 'DATE'           AS name,    TO_CHAR(test_date, ctx.format_date_time)    AS value FROM DUAL
            ORDER BY 1;
        --
        OPEN r_current FOR
            SELECT s.attribute AS name, s.value
            FROM session_context s
            WHERE s.namespace = ctx.app_namespace
            ORDER BY 1;
        --
        ut.expect(r_current).to_equal(r_expected);
    END;



    PROCEDURE init AS
        old_value       contexts.payload%TYPE;
        new_value       contexts.payload%TYPE;
        --
        exp_user_id     contexts.user_id%TYPE := 'TEST_USER';
        curr_user_id    contexts.user_id%TYPE;
        --
        count_contexts  PLS_INTEGER;
    BEGIN
        -- set any context for negative test
        ctx.set_context('NEGATIVE_TEST', 'TRUE');
        ctx.init();

        -- check number of contexts, zero is expected
        SELECT COUNT(*) INTO count_contexts
        FROM session_context s
        WHERE s.namespace = ctx.app_namespace;
        --
        ut.expect(count_contexts).to_equal(0);

        -- check client identifier
        --
        -- @TODO:
        --

        -- check app info module and action
        --
        -- @TODO:
        --

        -- check user_id if passed
        ctx.init(exp_user_id);
        --
        curr_user_id := ctx.get_user_id();
        --
        ut.expect(curr_user_id).to_equal(exp_user_id);
    END;

END;
/