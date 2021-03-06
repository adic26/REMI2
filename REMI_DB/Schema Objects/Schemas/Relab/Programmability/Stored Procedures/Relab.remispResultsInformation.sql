﻿ALTER PROCEDURE [Relab].[remispResultsInformation] @ResultID INT, @IncludeArchived INT = 0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @FalseBit BIT
	SET @FalseBit = CONVERT(BIT, 0)
	
	SELECT ri.Name, ri.Value, ri.XMLID, rxml.VerNum, ISNULL(ri.IsArchived, 0) AS IsArchived,
		rxml.TestXML, rxml.ProductXML, rxml.SequenceXML, rxml.StationXML
	FROM Relab.ResultsInformation ri
		INNER JOIN Relab.ResultsXML rxml ON ri.XMLID=rxml.ID
	WHERE rxml.ResultID=@ResultID AND ((@IncludeArchived = 0 AND ri.IsArchived=@FalseBit) OR (@IncludeArchived=1))

	SET NOCOUNT OFF
END
GO
GRANT EXECUTE ON [Relab].[remispResultsInformation] TO Remi
GO