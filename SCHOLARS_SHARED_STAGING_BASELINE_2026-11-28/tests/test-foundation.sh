#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
packet=$PWD
pg_bin=${PG_BIN:-$(pg_config --bindir)}
scratch=$(mktemp -d /tmp/scholars-foundation.XXXXXX)
socket="$scratch/socket"
initializer="$scratch/00_initialization.sql"
cleanup() {
  "$pg_bin/pg_ctl" -D "$scratch/data" -m immediate -w stop >/dev/null 2>&1 || true
  rm -rf -- "$scratch"
}
trap cleanup EXIT

mkdir "$socket"
"$pg_bin/initdb" -D "$scratch/data" --no-locale --encoding=UTF8 --auth=trust --username=postgres > "$scratch/initdb.log"
"$pg_bin/pg_ctl" -D "$scratch/data" -l "$scratch/server.log" \
  -o "-c listen_addresses='' -c unix_socket_directories='$socket'" -w start >/dev/null

sql() {
  local database=$1
  shift
  env -u PGHOSTADDR -u PGSERVICE -u PGOPTIONS "$pg_bin/psql" -X -qAt \
    -h "$socket" -p 5432 -U postgres -d "$database" -v ON_ERROR_STOP=1 "$@"
}

sql postgres <<'SQL'
create role anon;
create role authenticated;
create role service_role bypassrls;
create role supabase_auth_admin;
SQL

# Keep the production-facing endpoint guard intact. Adapt only a temporary
# copy to the private socket once the original file's refusal is tested.
sed "s|db\.aqhktriwaglvvrchxmtd\.supabase\.co|$socket|g" 00_initialization.sql > "$initializer"
ln -s "$packet/pinned-pr-sql" "$scratch/pinned-pr-sql"

init() {
  sql "$1" -v target_ref=aqhktriwaglvvrchxmtd \
    -v schema_only_baseline="$packet/01_foundational_schema.sql" -f "$2"
}

setup() {
  sql postgres -c "create database $1"
  sql "$1" -v legacy_grants="$2" -v with_cron="$3" -f tests/local_supabase_prerequisites.sql
}

for grants in legacy opt_in; do
  for cron in absent present; do
    database="foundation_${grants}_${cron}"
    legacy_grants=false
    with_cron=false
    if [[ $grants == legacy ]]; then legacy_grants=true; fi
    if [[ $cron == present ]]; then with_cron=true; fi
    setup "$database" "$legacy_grants" "$with_cron"
    sql "$database" -f 00_preflight.sql > "$scratch/preflight.log"
    grep -Fx "$cron|0" "$scratch/preflight.log"
    init "$database" "$initializer"
    sql "$database" -f tests/local_role_access.sql | sed '/^$/d'
    sql "$database" -f tests/deadline_broadcast_compat.sql
    sql "$database" -f tests/broadcast_staging_preflight.sql
    test "$(sql "$database" -c 'select count(*) from auth.users')" = 0
    printf 'Passed with %s grants and cron catalog %s.\n' "$grants" "$cron"
  done
done

setup foundation_scheduled true true
if init foundation_scheduled "$packet/00_initialization.sql" > "$scratch/rejected.log" 2>&1; then
  echo 'The unmodified initializer accepted the local socket.' >&2
  exit 1
fi
grep -F 'refusing unexpected connection host' "$scratch/rejected.log"
sql foundation_scheduled -c 'insert into cron.job values (1, false)'
sql foundation_scheduled -f 00_preflight.sql > "$scratch/preflight.log"
grep -Fx 'present|1' "$scratch/preflight.log"
if init foundation_scheduled "$initializer" > "$scratch/rejected.log" 2>&1; then
  echo 'Initialization unexpectedly accepted a scheduled job.' >&2
  exit 1
fi
grep -F 'refusing database with scheduled jobs' "$scratch/rejected.log"
test "$(sql foundation_scheduled -c "select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public'")" = 0
printf '%s\n' 'All foundation checks passed.'
