ALTER PROCEDURE [Relab].[remispResultsInformation] @ResultID INT, @IncludeArchived INT = 0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @FalseBit BIT
	SET @FalseBit = CONVERT(BIT, 0)
	
	SELECT ri.Name, ri.Value, ri.XMLID, rxml.VerNum, ISNULL(ri.IsArchived, 0) AS IsArchived, c.Definition AS ConfigXML
	FROM Relab.ResultsInformation ri
		INNER JOIN Relab.ResultsXML rxml ON ri.XMLID=rxml.ID
		LEFT OUTER JOIN dbo.Configurations c ON c.ConfigID=ri.ConfigID
	WHERE rxml.ResultID=@ResultID AND ((@IncludeArchived = 0 AND ri.IsArchived=@FalseBit) OR (@IncludeArchived=1))

	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultsInformation] TO Remi
GO