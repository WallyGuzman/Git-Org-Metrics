INSTALL httpfs; -- Use OpenSSL for encryption
ATTACH 'data/ci_metrics.db' AS ci_metrics (ENCRYPTION_KEY getenv('DUCKDB_ENCRYPTION_KEY'));

ATTACH '' AS steampipe (TYPE postgres, SECRET sp_pg_secret);

CREATE OR REPLACE TABLE ci_metrics.github_repos AS
FROM POSTGRES_QUERY('steampipe', '
  select
    r.id as repo_id,
    r.name_with_owner as repository_full_name
  from
    steampipe.github.github_search_repository r
  where
    r.query = ''org:duckdb''
    and r.owner_login = ''duckdb''
');
