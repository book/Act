
\c act

INSERT INTO users
    (
        login,
        passwd,
        salutation,
        first_name,
        last_name,
        nick_name,
        pseudonymous,
        country,
        town,
        web_page,
        pm_group,
        pm_group_url,
        email,
        email_hide,
        timezone
    )
VALUES
    (
        'demo',
        '{CRYPT}$2a$12$Zy4mKVTd3/W3wcJ1Fid7e.O/7z.kGFxscytuDcSQb4nuiW67j3hnC', -- demo
        1,
        'Demo',
        'User',
        'demos',
        true,
        'Netherlands',
        'Amsterdam',
        'https://example.com',
        'Amsterdam.pm',
        null,
        'demo@example.com',
        true,
        'Europe/Amsterdam'
    );
