CREATE OR REPLACE VIEW p860_uploaders AS
SELECT
    u.uploader_id,
    u.target_table,
    u.target_page_id,
    u.pre_procedure,
    u.post_procedure,
    u.is_active,
    --
    p.page_name,
    p.region_name,
    p.auth_scheme,
    --
    apex.get_page_link(u.target_page_id) AS page_link,
    --
    NULL AS action,
    NULL AS action_link,
    --
    apex.get_developer_page_link(u.target_page_id, p.region_id) AS apex_,
    --
    p.mappings_check,
    p.region_check,
    p.region_check_link,
    p.err_table,
    p.err_table_link
FROM uploaders u
LEFT JOIN p860_uploaders_possible p
    ON p.uploader_id    = u.uploader_id
WHERE u.app_id          = sess.get_app_id()
UNION ALL
SELECT
    p.table_name        AS uploader_id,
    p.table_name        AS target_table,
    p.page_id           AS target_page_id,
    NULL                AS pre_procedure,
    NULL                AS post_procedure,
    NULL                AS is_active,
    --
    p.page_name,
    p.region_name,
    p.auth_scheme,
    --
    apex.get_page_link(p.page_id)                                   AS page_link,
    --
    apex.get_icon('fa-plus-square', 'Add record to Uploaders')      AS action,
    --
    CASE
        WHEN p.auth_scheme IS NOT NULL
            THEN apex.get_page_link (
                in_page_id      => sess.get_page_id(),
                in_names        => 'P860_CREATE_UPLOADER,P860_UPLOADER_ID,P860_TABLE_NAME',
                in_values       => 'Y,' || p.table_name || ',' || p.table_name
            )
        END AS action_link,
    --
    apex.get_developer_page_link(p.page_id, p.region_id)            AS apex_,
    --
    p.mappings_check,
    p.region_check,
    p.region_check_link,
    p.err_table,
    p.err_table_link
FROM p860_uploaders_possible p
WHERE p.uploader_id IS NULL;
