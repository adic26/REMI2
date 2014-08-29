ALTER PROCEDURE [dbo].[remispTestExceptionsGetProductGroupTable]
/*	'===============================================================
'   NAME:                	remispTestExceptionsGetProductGroupTable
'   DATE CREATED:       	09 Oct 2009
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Retrieves a list of test names / boolean
'   VERSION: 1           
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON MODIFICATION: 
'===============================================================*/
	@ProductID INT
AS
	declare @testUnitExemptions table (exTestName nvarchar(255), ExceptionID int)
	
	insert into @testunitexemptions
	SELECT TestName, pvt.ID
	FROM vw_ExceptionsPivoted as pvt
		INNER JOIN Tests t WITH(NOLOCK) ON pvt.Test = t.ID
	where [ProductID]=@ProductID AND [TestStageID] IS NULL AND [Test] IS NOT NULL
	
	SELECT TestName AS Name, (CASE WHEN (SELECT TOP 1 ExceptionID FROM @testUnitExemptions WHERE exTestName = t.TestName) IS NOT NULL THEN 'True' ELSE 'False' END ) AS TestUnitException
	FROM Tests t WITH(NOLOCK)
	WHERE t.TestType = 1
	ORDER BY TestName
GO
GRANT EXECUTE On remispTestExceptionsGetProductGroupTable TO Remi
GO