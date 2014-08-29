ALTER PROCEDURE [dbo].[remispTestsSelectSingleItem] @ID int
AS
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, t.IsArchived, t.Owner, t.Trainee, t.DegradationVal
	FROM Tests as t
	WHERE t.ID = @ID
GO
GRANT EXECUTE ON remispTestsSelectSingleItem TO REMI
GO