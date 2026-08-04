#!/bin/bash
set -e

CSV_PATH="/dur/data/healthcare_noshows_appointments.csv"
READY_FILE="/tmp/iris_csv_ready"

if [[ ! -r "$CSV_PATH" ]]; then
    echo "CSV source is missing or unreadable: $CSV_PATH" >&2
    exit 1
fi

# Exclude the header. awk counts the final record even if it has no newline.
CSV_EXPECTED_ROWS=$(awk 'END { print NR - 1 }' "$CSV_PATH")
export CSV_EXPECTED_ROWS

IRIS_OUTPUT=$(iris session IRIS <<'EOF'
Write "Importing the CSV setup class...",!
Set status=$system.OBJ.Import("/usr/irissys/mgr/MockPackage/Setup.cls","ck")
If $SYSTEM.Status.IsError(status) Do $SYSTEM.Status.DisplayError(status) Halt

Write "Ensuring MockPackage.NoShowsAppointments is loaded...",!
Set expectedRows=+$SYSTEM.Util.GetEnviron("CSV_EXPECTED_ROWS")
Set status=##class(MockPackage.Setup).Initialize(expectedRows)
If $SYSTEM.Status.IsError(status) Do $SYSTEM.Status.DisplayError(status) Halt

Write "Enabling DeepSee for USER namespace...",!
Do EnableDeepSee^%SYS.cspServer("/csp/user/")

Halt
EOF
)

printf '%s\n' "$IRIS_OUTPUT"

if ! grep -q "CSV import verified: ${CSV_EXPECTED_ROWS} rows." <<< "$IRIS_OUTPUT"; then
    echo "IRIS CSV initialization did not complete successfully." >&2
    exit 1
fi

touch "$READY_FILE"
