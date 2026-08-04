# Use of IRIS as SPE or TRE

## Automatic CSV import

Starting the container creates `MockPackage.NoShowsAppointments` and imports
`dur/data/healthcare_noshows_appointments.csv`. The schema and native IRIS SQL
load steps are defined in `sql/init_noshows.sql` and invoked by
`iris_autoconf.sh` after IRIS starts.

For a new user, the complete setup command is:

```console
docker compose up --build -d
```

Docker downloads the public InterSystems IRIS Community Edition image, builds
this repository image, starts IRIS, and performs the CSV import. No IPM package
or `csvgenpy` installation is required.

The standard host ports are `1972` and `52773`. If either is already occupied,
set `IRIS_SUPERSERVER_PORT` and `IRIS_WEB_PORT` before running Docker Compose;
for example, use `1973` and `52774`. The ports inside the container remain the
standard IRIS ports.

The startup step is idempotent: it skips an existing table and verifies that
its row count still matches the CSV. Docker reports the container as healthy
only after this verification succeeds. To force a clean re-import, recreate
the container and its IRIS data storage.

Verify the imported data in the Management Portal or with:

```SQL
SELECT COUNT(*) FROM MockPackage.NoShowsAppointments
```

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

