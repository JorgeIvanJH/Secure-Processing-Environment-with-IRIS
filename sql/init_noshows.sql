CREATE TABLE MockPackage.NoShowsAppointmentsCSV (
    patientid DECIMAL(20,5),
    appointmentid INTEGER,
    gender CHAR(1),
    scheduledday DATE,
    appointmentday DATE,
    age SMALLINT,
    neighbourhood VARCHAR(64),
    scholarship VARCHAR(5),
    hipertension VARCHAR(5),
    diabetes VARCHAR(5),
    alcoholism VARCHAR(5),
    handcap VARCHAR(5),
    sms_received VARCHAR(5),
    showed_up VARCHAR(5),
    date_diff SMALLINT
)
GO

LOAD DATA FROM FILE '/dur/data/healthcare_noshows_appointments.csv'
INTO MockPackage.NoShowsAppointmentsCSV
USING {"from":{"file":{"header":true}}}
GO

CREATE TABLE MockPackage.NoShowsAppointments (
    patientid DECIMAL(20,5) NOT NULL,
    appointmentid INTEGER NOT NULL,
    gender CHAR(1) NOT NULL,
    scheduledday DATE NOT NULL,
    appointmentday DATE NOT NULL,
    age SMALLINT NOT NULL,
    neighbourhood VARCHAR(64) NOT NULL,
    scholarship BIT NOT NULL,
    hipertension BIT NOT NULL,
    diabetes BIT NOT NULL,
    alcoholism BIT NOT NULL,
    handcap BIT NOT NULL,
    sms_received BIT NOT NULL,
    showed_up BIT NOT NULL,
    date_diff SMALLINT NOT NULL,
    CONSTRAINT NoShowsAppointmentsPK PRIMARY KEY (appointmentid)
)
GO

INSERT INTO MockPackage.NoShowsAppointments (
    patientid,
    appointmentid,
    gender,
    scheduledday,
    appointmentday,
    age,
    neighbourhood,
    scholarship,
    hipertension,
    diabetes,
    alcoholism,
    handcap,
    sms_received,
    showed_up,
    date_diff
)
SELECT
    patientid,
    appointmentid,
    gender,
    scheduledday,
    appointmentday,
    age,
    neighbourhood,
    CASE WHEN UPPER(scholarship) = 'TRUE' THEN 1 ELSE 0 END,
    CASE WHEN UPPER(hipertension) = 'TRUE' THEN 1 ELSE 0 END,
    CASE WHEN UPPER(diabetes) = 'TRUE' THEN 1 ELSE 0 END,
    CASE WHEN UPPER(alcoholism) = 'TRUE' THEN 1 ELSE 0 END,
    CASE WHEN UPPER(handcap) = 'TRUE' THEN 1 ELSE 0 END,
    CASE WHEN UPPER(sms_received) = 'TRUE' THEN 1 ELSE 0 END,
    CASE WHEN UPPER(showed_up) = 'TRUE' THEN 1 ELSE 0 END,
    date_diff
FROM MockPackage.NoShowsAppointmentsCSV
GO

DROP TABLE MockPackage.NoShowsAppointmentsCSV
GO
