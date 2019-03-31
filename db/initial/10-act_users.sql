
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
        '{SSHA}QB9ZznyvO/ytdu1+pqUoW7DlXD/M2YlQ', -- demo
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
