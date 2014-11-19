ALTER PROCEDURE [dbo].remispJobsList @UserID INT
AS
	BEGIN
		DECLARE @TrueBit BIT
		SET @TrueBit = CONVERT(BIT, 1)
		
		SELECT j.ID, j.JobName, j.IsActive, j.ContinueOnFailures, j.LastUser, j.NoBSN, j.TechnicalOperationsTest, j.ProcedureLocation, j.MechanicalTest,
			j.WILocation, j.OperationsTest, j.Comment
		FROM Jobs j
			INNER JOIN JobAccess ja ON ja.JobID=j.ID
			INNER JOIN UserDetails ud ON ud.LookupID = ja.LookupID AND ud.UserID IN (SELECT ID FROM Users u WHERE u.ID=@UserID)
		WHERE j.IsActive=@TrueBit
		ORDER BY j.JobName
	END
Go
GRANT EXECUTE ON remispJobsList TO REMI
GO