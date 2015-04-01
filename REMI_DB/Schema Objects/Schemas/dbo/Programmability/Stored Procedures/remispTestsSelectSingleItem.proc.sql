ALTER PROCEDURE [dbo].[remispTestsSelectSingleItem] @ID INT = 0, @Name nvarchar(400) = NULL, @ParametricOnly INT = 1
AS
	SELECT t.Comment,t.ConcurrencyID,t.Duration,t.ID,t.LastUser,t.ResultBasedOntime,t.TestName,t.TestType,t.WILocation, t.IsArchived, t.Owner, t.Trainee, t.DegradationVal
	FROM Tests as t
	WHERE 
		(
			(t.ID = @ID AND @ID > 0)
			OR
			(@ID = 0 AND t.TestName = @name)
		)
		AND 
		(
			@ParametricOnly = 0
			OR
			(@ParametricOnly = 1 AND TestType=1)
		)
GO
GRANT EXECUTE ON remispTestsSelectSingleItem TO REMI
GO