INSTALL httpfs; -- Use OpenSSL for encryption
ATTACH 'data/ci_metrics.db' AS ci_metrics (ENCRYPTION_KEY getenv('DUCKDB_ENCRYPTION_KEY'));

CREATE OR REPLACE PERSISTENT SECRET sp_pg_secret (
    TYPE postgres,
    HOST '127.0.0.1',
    PORT 5432,
    DATABASE 'steampipe',
    USER 'steampipe',
    PASSWORD GETENV('STEAMPIPE_DATABASE_PASSWORD')
);
