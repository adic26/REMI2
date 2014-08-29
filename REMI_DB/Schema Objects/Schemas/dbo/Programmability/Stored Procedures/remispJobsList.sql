ALTER PROCEDURE [dbo].remispJobsList
AS
	BEGIN
		DECLARE @TrueBit BIT
		SET @TrueBit = CONVERT(BIT, 1)
		
		SELECT j.ID, j.JobName, j.IsActive, j.ContinueOnFailures, j.LastUser, j.NoBSN, j.TechnicalOperationsTest, j.ProcedureLocation, j.MechanicalTest,
			j.WILocation, j.OperationsTest, j.Comment
		FROM Jobs j
		WHERE j.IsActive=@TrueBit
		ORDER BY j.JobName
	END
Go
GRANT EXECUTE ON remispJobsList TO REMI
GO