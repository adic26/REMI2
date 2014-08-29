ALTER PROCEDURE [dbo].[remispTestStagesDeleteSingleItem]
/*	'===============================================================
'   NAME:                	remispTestStagesDeleteSingleItem
'   DATE CREATED:       	20 April 2009
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Deletes an item from table: TestStages     
'   VERSION: 1                   
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON FOR MODIFICATION: 
'===============================================================*/
	@ID int,
	@UserName nvarchar(255)
AS
declare @testID int;
declare @teststagetype int;
select @testID = testid, @teststagetype = teststagetype from TestStages as ts where ts.ID = @ID

begin transaction deleteteststage
	
-- set the last user before the delete
PRINT 'UPDATE TestStages'
UPDATE TestStages
Set LastUser = @UserName
WHERE ID = @ID
	
SELECT DISTINCT pvt.ID
INTO #temp
FROM vw_ExceptionsPivoted as pvt
WHERE TestStageID = @ID

PRINT 'DELETE TestExceptions'
DELETE FROM TestExceptions WHERE ID IN (SELECT ID FROM #temp)
DROP TABLE #temp
		
PRINT 'DELETE TaskAssignments'
delete from TaskAssignments where TaskID = @id
	
PRINT 'DELETE TestStages'
delete from TestStages where ID=@id

--if this is an environmental stress test delete the corrisponding test/task
if (@teststagetype = 2)
BEGIN
	PRINT 'remispTestsDeleteSingleItem'
	execute remispTestsDeleteSingleItem @testid, @username
END

commit transaction deleteteststage