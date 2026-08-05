INSTALL httpfs; -- Use OpenSSL for encryption
ATTACH 'data/ci_metrics.db' AS ci_metrics (ENCRYPTION_KEY getenv('DUCKDB_ENCRYPTION_KEY'));

ATTACH '' AS steampipe (TYPE postgres, SECRET sp_pg_secret);

CREATE OR REPLACE TABLE ci_metrics.github_jobs AS
FROM POSTGRES_QUERY('steampipe', '
  with ci_repositories as materialized (
    select
      r.name_with_owner as repository_full_name
    from
      steampipe.github.github_search_repository r
    where
      r.query = ''org:duckdb''
      and r.owner_login = ''duckdb''
  ),

  ci_workflows as materialized (
    select
      w.repository_full_name,
      w.id as workflow_id
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
  ),

  ci_runs as materialized (
    select
      r.repository_full_name,
      r.id as run_id
    from
      steampipe.github.github_actions_repository_workflow_run r
    where
      r.created_at > now() - interval ''1 day''
      and status not in (''waiting'', ''pending'', ''requested'', ''queued'', ''in_progress'', ''neutral'')
      and (r.repository_full_name, r.workflow_id) in (
        select
          repository_full_name,
          workflow_id
        from
          ci_workflows
      )
  )

  select
    j.repository_full_name,
    j.run_id,
    j.id as job_id,
    j.labels,
    j.created_at as job_created_at,
    j.started_at as job_started_at,
    j.completed_at as job_completed_at,
    j.run_attempt,
    j.runner_id,
    j.runner_name
  from
    steampipe.github.github_actions_repository_workflow_job j
  where
    j.created_at > now() - interval ''1 day''
    and (repository_full_name, run_id) in (
      select
        repository_full_name,
        run_id
      from
        ci_runs
    )
');
