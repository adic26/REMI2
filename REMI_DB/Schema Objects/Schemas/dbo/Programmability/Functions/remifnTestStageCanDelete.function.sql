﻿SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION dbo.remifnTestStageCanDelete (@TestStageID INT)
RETURNS BIT
AS
BEGIN
	DECLARE @Exists BIT
	
	SELECT @Exists = (SELECT DISTINCT 0
		FROM TestRecords
		WHERE TestStageID=@TestStageID
		UNION
		SELECT DISTINCT 0
		FROM Relab.Results
		WHERE TestStageID=@TestStageID
		UNION
		SELECT DISTINCT 0
		FROM Req.RequestSetup
		WHERE TestStageID=@TestStageID)
	
	RETURN ISNULL(@Exists, 1)
END
GO
GRANT EXECUTE ON remifnTestStageCanDelete TO Remi
GO