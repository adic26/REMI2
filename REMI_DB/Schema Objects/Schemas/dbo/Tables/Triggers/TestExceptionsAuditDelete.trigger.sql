-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[TestExceptionsAuditDeleteNew]
   ON  dbo.TestExceptions
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
--insert into TestExceptionsaudit (
--TestUnitTestExceptionID,
--TestName,
--TestStageId,
--ProductGroupName,
--ReasonforRequest,
--TestUnitID,
--UserName,
--Action)
-- Select 
-- ID,
--TestName,
--TestStageId,
--ProductGroupName,
--ReasonforRequest,
--TestUnitID,
--LastUser,
--'D' from deleted

INSERT INTO TestExceptionsAudit (ID, LookupID, Value, UserName, Action)
SELECT ID, LookupID, Value, LastUser, 'D'
FROM deleted

END
