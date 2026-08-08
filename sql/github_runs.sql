ATTACH '' AS steampipe (TYPE postgres, SECRET sp_pg_secret);

SET preserve_insertion_order=false;

CREATE OR REPLACE TABLE ci_metrics.github_runs AS
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
  )

  select
    wr.repository_full_name,
    wr.workflow_id,
    wr.id as run_id,
    wr.event,
    wr.conclusion as run_conclusion,
    wr.status as run_status,
    wr.run_number,
    wr.created_at as run_created_at,
    wr.run_started_at,
    wr.updated_at as run_updated_at
  from
    steampipe.github.github_actions_repository_workflow_run wr
  where
    wr.created_at > now() - interval ''7 days''
    and status not in (''waiting'', ''pending'', ''requested'', ''queued'', ''in_progress'', ''neutral'')
    and (repository_full_name, workflow_id) in (
      select
        repository_full_name,
        workflow_id
      from
        ci_workflows
    )
');
