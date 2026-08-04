Include %occStatus

Class MockPackage.Setup Extends %RegisteredObject
{

Parameter SQLInitPath = "/usr/irissys/mgr/sql/init_noshows.sql";

/// Create and populate MockPackage.NoShowsAppointments once, then verify that
/// every CSV data row reached the final table.
ClassMethod Initialize(expectedRows As %Integer) As %Status
{
    Try {
        If '$SYSTEM.SQL.Schema.TableExists("MockPackage.NoShowsAppointments") {
            // Remove a staging table left behind by an interrupted first load.
            If $SYSTEM.SQL.Schema.TableExists("MockPackage.NoShowsAppointmentsCSV") {
                Set status=$SYSTEM.SQL.Schema.DropTable("MockPackage.NoShowsAppointmentsCSV",1)
                If $SYSTEM.Status.IsError(status) Return status
            }

            Set command="LOAD SQL FROM FILE '"_..#SQLInitPath_"'"
            Set result=##class(%SQL.Statement).%ExecDirect(,command)
            If result.%SQLCODE<0 {
                Return $$$ERROR($$$GeneralError,"SQL initialization failed: "_result.%Message)
            }
        }
        Else {
            Write "Table already exists; skipping CSV import.",!
        }

        Set result=##class(%SQL.Statement).%ExecDirect(,"SELECT COUNT(*) FROM MockPackage.NoShowsAppointments")
        If result.%SQLCODE<0 {
            Return $$$ERROR($$$GeneralError,"Unable to validate imported table: "_result.%Message)
        }
        If 'result.%Next() {
            Return $$$ERROR($$$GeneralError,"The imported table row count could not be read")
        }

        Set actualRows=+result.%GetData(1)
        If actualRows'=expectedRows {
            Return $$$ERROR($$$GeneralError,"CSV import row-count mismatch: expected "_expectedRows_", found "_actualRows)
        }

        Write "CSV import verified: ",actualRows," rows.",!
        Return $$$OK
    }
    Catch exception {
        Return exception.AsStatus()
    }
}

}
