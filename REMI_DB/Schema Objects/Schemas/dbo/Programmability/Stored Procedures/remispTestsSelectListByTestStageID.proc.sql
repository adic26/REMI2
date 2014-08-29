ALTER PROCEDURE [dbo].[remispTestsSelectListByTestStageID] @TestStageID int = -1
AS
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, t.IsArchived
	FROM  Tests AS t, TestStages as ts
	WHERE ts.ID = @TestStageID
		and 
		((ts.TestStagetype = 2  and t.id = ts.TestID ) --if its an env teststage get the equivelant test
		or (ts.teststagetype = 1 and t.testtype = 1))--otherwise if its a para test stage get all the para tests
GO
GRANT EXECUTE ON remispTestsSelectListByTestStageID TO REMI
GO