#!/bin/bash
set -euo pipefail

SQL_FILE="${IRIS_SQL_FILE:-/usr/irissys/mgr/sql/bootstrap.sql}"
READY_FILE="/tmp/iris_data_ready"

rm -f "$READY_FILE"

if [[ ! -r "$SQL_FILE" ]]; then
    echo "IRIS SQL bootstrap file is missing or unreadable: $SQL_FILE" >&2
    exit 1
fi

# LOAD SQL FROM FILE accepts a quoted file path. Reject a quote instead of
# constructing an ambiguous SQL command from it.
if [[ "$SQL_FILE" == *"'"* ]]; then
    echo "IRIS_SQL_FILE cannot contain a single quote: $SQL_FILE" >&2
    exit 1
fi

echo "Running IRIS SQL bootstrap: $SQL_FILE"

if ! IRIS_OUTPUT=$(
    printf "LOAD SQL FROM FILE '%s' VERBOSE\nQUIT\n" "$SQL_FILE" | iris sql IRIS
); then
    echo "The IRIS SQL Shell could not run the bootstrap." >&2
    exit 1
fi

printf '%s\n' "$IRIS_OUTPUT"

# VERBOSE exposes LOAD SQL diagnostics in the terminal. The interactive SQL
# Shell can still return process status 0 after reporting an SQL error, so its
# output is checked before the container is marked healthy.
if grep -Eq 'SQLCODE[^-0-9]*-[0-9]+|ERROR #[0-9]+:|with errors reported:[[:space:]]*[1-9]' <<< "$IRIS_OUTPUT"; then
    echo "The IRIS SQL bootstrap reported an error." >&2
    exit 1
fi

touch "$READY_FILE"
echo "IRIS SQL bootstrap completed successfully."
