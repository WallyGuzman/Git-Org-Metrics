.PHONY: all bootstrap run_steampipe run_feeds clean

-include .env
export

all: bootstrap run_steampipe run_feeds clean

bootstrap:
	time uv run duckdb < sql/duckdb_bootstrap.sql

run_steampipe:
	steampipe service start --database-listen local --database-port 5432 > /dev/null &

run_feeds:
	# These run as separate queries, but they will reuse the steampipe cache to avoid hitting rate limits
	time uv run duckdb < sql/github_repos.sql
	time uv run duckdb < sql/github_workflows.sql
	time uv run duckdb < sql/github_runs.sql
	time uv run duckdb < sql/github_jobs.sql

clean:
	steampipe service stop --force
