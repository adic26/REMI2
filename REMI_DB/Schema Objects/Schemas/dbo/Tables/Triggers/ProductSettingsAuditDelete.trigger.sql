-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER TRIGGER [dbo].[ProductSettingsAuditDelete]
   ON  [dbo].[ProductSettings]
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into ProductSettingsAudit (
	ProductSettingsId, 
	LookupID,
	KeyName, 
	ValueText,	
	DefaultValue,
	Action)
	Select 
	Id, 
	LookupID,
	KeyName, 
	ValueText,
	DefaultValue,
'D' from deleted

END
