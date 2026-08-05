# Use of IRIS as SPE or TRE

## Automatic data bootstrap

Starting the container runs the SQL script configured by `IRIS_SQL_FILE`. Its
default is `sql/bootstrap.sql`, which demonstrates a CSV import by creating
`MockPackage.NoShowsAppointments` and loading
`dur/data/healthcare_noshows_appointments.csv`.

`iris_autoconf.sh` contains no ObjectScript and knows nothing about the source
file, table names, columns, or expected row count. It only asks the documented
IRIS SQL Shell to run the configured SQL file in verbose mode and marks the
container healthy when no SQL error is reported.

For a new user, the complete setup command is:

```console
docker compose up --build -d
```

Docker downloads the public InterSystems IRIS Community Edition image, builds
this repository image, starts IRIS, and runs the SQL bootstrap. No IPM package,
custom ObjectScript setup class, or `csvgenpy` installation is required.

The standard host ports are `1972` and `52773`. If either is already occupied,
set `IRIS_SUPERSERVER_PORT` and `IRIS_WEB_PORT` before running Docker Compose;
for example, use `1973` and `52774`. The ports inside the container remain the
standard IRIS ports.

The example SQL drops and rebuilds its target table, so it is repeatable. For a
different source, put the files under `dur/data`, replace `sql/bootstrap.sql`
with the required standard DDL and loading SQL, then rebuild. All source-specific
conversion and loading logic belongs in that SQL file.

You can instead point the same image at another SQL file. The file must be
readable inside the container; the repository's `dur` directory is mounted at
`/dur`:

```powershell
$env:IRIS_SQL_FILE = "/dur/sql/my_bootstrap.sql"
docker compose up --build -d
```

The script is executed on every container start, so make a replacement script
repeatable with `DROP TABLE IF EXISTS`, `CREATE TABLE IF NOT EXISTS`, or another
appropriate loading strategy. Docker reports the container as healthy after
the SQL script completes without a reported negative SQLCODE. Data-quality and
row-count checks remain source-specific; add the appropriate verification query
or application test for each source.

Verify the imported data in the Management Portal or with:

```SQL
SELECT COUNT(*) FROM MockPackage.NoShowsAppointments
```

This approach uses the official IRIS SQL facilities documented under
[the `iris sql` command](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GSA_using_instance),
[LOAD SQL FROM FILE](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RSQL_loadsql),
and [LOAD DATA](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RSQL_loaddata).

## Automatic table-access users

`config/security-policy.json` defines the namespace, table, and two demo users.
Edit the username, password, or `canReadTable` value and rebuild the image. The
startup script recreates both users, gives them the basic roles required for an
SQL connection, and directly grants table `SELECT` only when `canReadTable` is
`true`.

The notebook `dur/sandbox/EDA.ipynb` contains two simple connection examples.
Yomna reads five rows into a pandas DataFrame; Jorge runs the same query and is
denied with SQLCODE `-99`.

The clear-text `demo` passwords are intentionally simple for this local
demonstration. Replace them or use a secrets-management mechanism outside a
demo environment.

This follows the official IRIS APIs for
[creating users](https://docs.intersystems.com/irislatest/csp/documatic/%25CSP.Documatic.cls?CLASSNAME=Security.Users&LIBRARY=%25SYS),
and [granting SQL privileges](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RSQL_grant).

## Python SQLAlchemy access

The image installs the official InterSystems IRIS SQLAlchemy dialect through
the `sqlalchemy-intersystems-iris` package. An external Python application can
connect using the `iris://` dialect:

```python
from sqlalchemy import create_engine, text

engine = create_engine(
    "iris://username:password@localhost:1972/USER"
)

with engine.connect() as connection:
    row_count = connection.execute(
        text("SELECT COUNT(*) FROM MockPackage.NoShowsAppointments")
    ).scalar_one()
```

For a least-privilege application account, grant only the required SQL table
privileges and assign a role containing `%Native_ClassExecution:Use`. The
SQLAlchemy dialect uses that resource while identifying the IRIS version when
it opens a connection. Do not use the predefined `_SYSTEM` account for an
application.

Supply credentials through your application's secret-management mechanism;
do not commit them to the repository or bake them into the container image.

## Admin
Assign Tables to users and SQL permission (SELECT, INSERT, UPDATE, DELETE)

## SQL
You can use SQL with InterSystems IRIS at scales from queries running on a single CPU core, to parallel queries using dozens of cores, to distributed queries across a cluster of InterSystems IRIS servers.

Connectivity with ODBC and JDBC clients.

Same syntax as MySQL, PostgreSQL, or SQL Server (SQL-92 standard syntax)

### Syntax additions:

#### arrow operations for implicit joins (->)

```SQL
SELECT e.Name, c.CompanyName 
FROM Employee AS e 
JOIN Company AS c ON e.CompanyID = c.ID
```

InterSystems SQL
```SQL
SELECT Name, CompanyID->CompanyName FROM Employee
```


## Scalability

