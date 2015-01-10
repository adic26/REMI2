ALTER FUNCTION [Relab].[ResultsXMLParametersComma](@Parameters XML)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @listStr VARCHAR(MAX)
	DECLARE @tab table(value varchar(max))

	INSERT INTO @tab(value)
	SELECT CONVERT(NVARCHAR(MAX), T.c.value('@ParameterName', 'NVARCHAR(max)')) + ': ' + CONVERT(NVARCHAR(MAX), T.c.query('./child::text()'))  as Value
	FROM @Parameters.nodes('/child::*/child::*') T(c)	
	ORDER BY CONVERT(VARCHAR(MAX), T.c.value('@ParameterName', 'nvarchar(max)')), CONVERT(VARCHAR(MAX), T.c.query('./child::text()')) ASC

	SELECT @listStr=(select STUFF(value, 1, 0, ', ') from @tab for xml path('')) 

	RETURN SUBSTRING(@listStr, 2, LEN(@listStr))
END