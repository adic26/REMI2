ALTER PROCEDURE [dbo].[remispTestsDeleteSingleItem]
/*	'===============================================================
'   NAME:                	remispTestsDeleteSingleItem
'   DATE CREATED:       	06 jun 2009
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Marks an item as not visible       
'   VERSION: 1                   
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON FOR MODIFICATION: 
'===============================================================*/
	@ID int,
	@UserName nvarchar(255)
AS
begin transaction deletetest

PRINT 'UPDATE tests lastuser'
Update tests Set lastuser = @UserName WHERE ID = @ID

PRINT 'DELETE BatchSpecificTestDurations'
delete from BatchSpecificTestDurations  where BatchSpecificTestDurations.TestID = @ID;

PRINT 'DELETE TrackingLocationsForTests'
delete from TrackingLocationsForTests where TestID = @id

SELECT DISTINCT pvt.ID
INTO #temp
FROM vw_ExceptionsPivoted as pvt
WHERE Test = @ID

PRINT 'DELETE TestExceptions'
DELETE FROM TestExceptions WHERE ID IN (SELECT ID FROM #temp)
DROP TABLE #temp

PRINT 'DELETE Tests'
delete from Tests where ID=@ID
	
commit transaction deletetest
GO
GRANT EXECUTE ON remispTestsDeleteSingleItem TO Remi
GO