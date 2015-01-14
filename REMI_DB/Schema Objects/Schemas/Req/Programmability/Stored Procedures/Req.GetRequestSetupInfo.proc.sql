﻿ALTER PROCEDURE [Req].[GetRequestSetupInfo] @ProductID INT, @JobID INT, @BatchID INT, @TestStageType INT, @BlankSelected INT
AS
BEGIN
	IF NOT EXISTS(SELECT 1 FROM Req.RequestSetup rs INNER JOIN Tests t ON t.ID=rs.TestID WHERE BatchID=@BatchID AND t.TestType=@TestStageType)
	BEGIN
		IF EXISTS(SELECT 1 FROM Req.RequestSetup rs INNER JOIN Tests t ON t.ID=rs.TestID WHERE JobID=@JobID AND ProductID=@ProductID AND t.TestType=@TestStageType)
		BEGIN
			SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN rs.ID IS NULL THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
			FROM Jobs j
				INNER JOIN TestStages ts ON j.ID=ts.JobID
				INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
				LEFT OUTER JOIN Req.RequestSetup rs ON rs.JobID=@JobID AND rs.ProductID=@ProductID AND rs.TestID=t.ID AND rs.TestStageID=ts.ID
			WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
			ORDER BY ts.ProcessOrder, t.TestName
		END
		ELSE IF @BlankSelected = 0 AND EXISTS(SELECT 1 FROM Req.RequestSetup rs INNER JOIN Tests t ON t.ID=rs.TestID WHERE JobID=@JobID AND ProductID IS NULL AND t.TestType=@TestStageType)
		BEGIN
			SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN rs.ID IS NULL THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
			FROM Jobs j
				INNER JOIN TestStages ts ON j.ID=ts.JobID
				INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
				LEFT OUTER JOIN Req.RequestSetup rs ON rs.JobID=@JobID AND rs.ProductID IS NULL AND rs.TestID=t.ID AND rs.TestStageID=ts.ID
			WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
			ORDER BY ts.ProcessOrder, t.TestName
		END
		ELSE
		BEGIN
			SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN @BlankSelected = 1 THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
			FROM Jobs j
				INNER JOIN TestStages ts ON j.ID=ts.JobID
				INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
			WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
			ORDER BY ts.ProcessOrder, t.TestName
		END
	END
	ELSE
	BEGIN
		SELECT ts.ID As TestStageID, ts.TestStageName, t.ID AS TestID, t.TestName, CASE WHEN rs.ID IS NULL THEN CONVERT(BIT, 0) ELSE CONVERT(BIT, 1) END AS Selected
		FROM Jobs j
			INNER JOIN TestStages ts ON j.ID=ts.JobID
			INNER JOIN Tests t WITH(NOLOCK) ON ( ( ts.teststagetype = 2 AND ts.testid = t.id ) OR ts.teststagetype != 2 AND ts.teststagetype = t.testtype )
			LEFT OUTER JOIN Req.RequestSetup rs ON rs.TestID=t.ID 
											AND rs.BatchID=@BatchID 
											AND rs.TestStageID=ts.ID 
											AND 
											(
												(ISNULL(rs.ProductID,0)=ISNULL(@ProductID,0))
												OR
												(rs.ProductID IS NULL)
											)
		WHERE j.ID=@JobID AND ts.TestStageType=@TestStageType AND ts.ProcessOrder >= 0 AND ISNULL(ts.IsArchived, 0) = 0 AND ISNULL(t.IsArchived, 0) = 0
		ORDER BY ts.ProcessOrder, t.TestName
		
	END
END
GO
GRANT EXECUTE ON [Req].[GetRequestSetupInfo] TO REMI
GO