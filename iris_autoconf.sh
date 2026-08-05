#!/bin/bash
set -euo pipefail

SQL_FILE="${IRIS_SQL_FILE:-/usr/irissys/mgr/sql/bootstrap.sql}"
SECURITY_POLICY_FILE="${IRIS_SECURITY_POLICY:-/usr/irissys/mgr/config/security-policy.json}"
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

if [[ ! -r "$SECURITY_POLICY_FILE" ]]; then
    echo "IRIS security policy is missing or unreadable: $SECURITY_POLICY_FILE" >&2
    exit 1
fi

export SECURITY_POLICY_FILE

SECURITY_OUTPUT=$(iris session IRIS <<'EOF'
Set policyPath=$SYSTEM.Util.GetEnviron("SECURITY_POLICY_FILE")
Set policy={}.%FromJSONFile(policyPath),namespace=policy.namespace,table=policy.table

Set profile=policy.users.%Get(0),username=profile.username,password=profile.password,canRead=+profile.canReadTable
Set $Namespace="%SYS"
Set:$SYSTEM.SQL.Security.UserExists(username) status=##class(Security.Users).Delete(username)
Set status=##class(Security.Users).Create(username,"%SQL,%DB_USER",password,username,namespace,"","",0,1,"Configured from security-policy.json")
If $SYSTEM.Status.IsError(status) Do $SYSTEM.Status.DisplayError(status) Halt
Set $Namespace=namespace
Set:canRead status=$SYSTEM.SQL.Security.GrantPrivilege("Select",table,"Table",username)
If canRead,$SYSTEM.Status.IsError(status) Do $SYSTEM.Status.DisplayError(status) Halt
Write "Configured user ",username,": table SELECT ",$Select(canRead:"allowed",1:"denied"),!

Set profile=policy.users.%Get(1),username=profile.username,password=profile.password,canRead=+profile.canReadTable
Set $Namespace="%SYS"
Set:$SYSTEM.SQL.Security.UserExists(username) status=##class(Security.Users).Delete(username)
Set status=##class(Security.Users).Create(username,"%SQL,%DB_USER",password,username,namespace,"","",0,1,"Configured from security-policy.json")
If $SYSTEM.Status.IsError(status) Do $SYSTEM.Status.DisplayError(status) Halt
Set $Namespace=namespace
Set:canRead status=$SYSTEM.SQL.Security.GrantPrivilege("Select",table,"Table",username)
If canRead,$SYSTEM.Status.IsError(status) Do $SYSTEM.Status.DisplayError(status) Halt
Write "Configured user ",username,": table SELECT ",$Select(canRead:"allowed",1:"denied"),!

Write "IRIS security policy applied successfully.",!
Halt
EOF
)

printf '%s\n' "$SECURITY_OUTPUT"

if grep -Eq '<[A-Z][A-Z0-9]*>|ERROR #[0-9]+:' <<< "$SECURITY_OUTPUT" || \
   ! grep -q "IRIS security policy applied successfully." <<< "$SECURITY_OUTPUT"; then
    echo "IRIS security policy initialization did not complete successfully." >&2
    exit 1
fi

touch "$READY_FILE"
echo "IRIS data and security bootstrap completed successfully."
