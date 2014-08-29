-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[JobsAuditDelete]
   ON  dbo.Jobs
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into jobsaudit (JobId, JobName, WILocation, Comment, UserName, Action, ProcedureLocation, IsActive)
Select ID, JobName, WILocation, Comment, LastUser, 'D', ProcedureLocation, IsActive from deleted

END