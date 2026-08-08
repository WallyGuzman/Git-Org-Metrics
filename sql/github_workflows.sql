ATTACH '' AS steampipe (TYPE postgres, SECRET sp_pg_secret);

SET preserve_insertion_order=false;

CREATE OR REPLACE TABLE ci_metrics.github_workflows AS
FROM POSTGRES_QUERY('steampipe', '
  with ci_repositories as materialized (
    select
      r.name_with_owner as repository_full_name
    from
      steampipe.github.github_search_repository r
    where
      r.query = ''org:duckdb''
      and r.owner_login = ''duckdb''
  )

  select
    w.repository_full_name,
    w.id as workflow_id,
    w.name as workflow_name
  from
    steampipe.github.github_workflow w
  where
    w.state = ''active''
    and w.repository_full_name in (
      select
        repository_full_name
      from
        ci_repositories
    )
');
