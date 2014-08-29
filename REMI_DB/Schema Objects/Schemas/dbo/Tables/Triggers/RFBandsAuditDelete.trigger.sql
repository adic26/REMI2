-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[RFBandsAuditDelete]
   ON  [dbo].[RFBands]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into RFBandsaudit (
	ProductGroupName,
	RFbands,
	UserName,
	Action)
	Select 
	ProductGroupName,
	RFbands,
	lastuser,
'D' from deleted

END
