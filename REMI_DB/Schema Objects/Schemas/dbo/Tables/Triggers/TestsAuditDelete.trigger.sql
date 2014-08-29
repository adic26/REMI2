-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[TestsAuditDelete]
   ON  [dbo].[Tests]
    after delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into Testsaudit (
	TestId, 
	TestName, 
	Duration,
	TestType,
	WILocation,
	Comment,
	ResultBasedOnTime,
	UserName,
	[Action], DegradationVal)
	Select 
	Id, 
	TestName, 
	Duration,
	TestType,
	WILocation,
	Comment, 
	ResultBasedOnTime,
	LastUser, 'D', DegradationVal from deleted

END
