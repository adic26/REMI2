BEGIN TRAN
GO
CREATE TABLE [dbo].[JobAccess]
(
[JobAccessID] [int] NOT NULL IDENTITY(1, 1),
[JobID] [int] NOT NULL,
[LookupID] [int] NOT NULL
)
GO
-- Constraints and Indexes

ALTER TABLE [dbo].[JobAccess] ADD CONSTRAINT [PK_JobAccess] PRIMARY KEY CLUSTERED  ([JobAccessID])
GO
-- Foreign Keys

ALTER TABLE [dbo].[JobAccess] ADD CONSTRAINT [FK_JobAccess_Jobs] FOREIGN KEY ([JobID]) REFERENCES [dbo].[Jobs] ([ID])
GO
ALTER TABLE [dbo].[JobAccess] ADD CONSTRAINT [FK_JobAccess_Lookups] FOREIGN KEY ([LookupID]) REFERENCES [dbo].[Lookups] ([LookupID])
GO
DECLARE @LookupID INT

SELECT @LookupID=LookupID FROM Lookups WHERE LookupTypeID IN (SELECT LookupTypeID FROM LookupType WHERE Name='Department') AND [Values]='Product Validation'

insert into JobAccess (JobID, LookupID)
select id, @LookupID
from jobs
WHERE IsActive=1
go
ALTER PROCEDURE [dbo].remispJobsList @UserID INT
AS
	BEGIN
		DECLARE @TrueBit BIT
		SET @TrueBit = CONVERT(BIT, 1)
		
		SELECT ja.JobID
		INTO #JobAccess
		FROM UserDetails ud 
			INNER JOIN Lookups l ON l.LookupID=ud.LookupID
			INNER JOIN LookupType lt ON lt.LookupTypeID=l.LookupTypeID AND lt.Name='Department'
			INNER JOIN JobAccess ja ON ja.LookupID=ud.LookupID
		WHERE ud.UserID=@UserID
		
		SELECT j.ID, j.JobName, j.IsActive, j.ContinueOnFailures, j.LastUser, j.NoBSN, j.TechnicalOperationsTest, j.ProcedureLocation, j.MechanicalTest,
			j.WILocation, j.OperationsTest, j.Comment
		FROM Jobs j
		WHERE j.IsActive=@TrueBit AND j.ID IN (SELECT JobID FROM #JobAccess)
		ORDER BY j.JobName
		
		DROP TABLE #JobAccess
	END
Go
GRANT EXECUTE ON remispJobsList TO REMI
GO

GO
ROLLBACK TRAN