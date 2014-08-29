CREATE PROCEDURE [dbo].[remispTestExceptionsGetTestUnitTableForAllTestStages]
/*	'===============================================================
	'   NAME:                	remispTestExceptionsGetTestUnitTable
	'   DATE CREATED:       	09 Oct 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves a list of test names / boolean
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/
	
	@QRANumber nvarchar(11) = null,
	@BatchunitNumber int = null

	AS

declare teststagename cursor for select teststagename from TestStages where 
JobID = (select j.ID from Jobs as j, batches as b where j.JobName = b.jobname and b.qranumber = @qranumber)


declare @currentteststagename nvarchar(400)

open teststagename 
--get the first ts name
fetch next from teststagename into @currentteststagename
--loop through them
while @@FETCH_STATUS = 0
begin

select @currentteststagename;
exec remispTestExceptionsGetTestUnitTable @QRANumber,@batchUnitNumber,@currentteststagename

fetch next from teststagename into @currentteststagename

end

close teststagename
deallocate teststagename