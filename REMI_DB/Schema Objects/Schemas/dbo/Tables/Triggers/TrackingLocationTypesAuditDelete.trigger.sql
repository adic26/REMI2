-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[TrackingLocationTypesAuditDelete]
   ON  dbo.TrackingLocationTypes
    for  delete
AS 
BEGIN
 SET NOCOUNT ON;
 
  If not Exists(Select * From Deleted) 
	return	 --No delete action, get out of here
	
insert into TrackingLocationTypesaudit (
	TrackingLocationTypeId, 
	TrackingLocationTypeName, 
	TrackingLocationFunction,
	WILocation, 
	UnitCapacity,
	Comment,
	Username,
	Action)
	Select 
	Id, 
	TrackingLocationTypeName, 
	TrackingLocationFunction,
	WILocation, 
	UnitCapacity,
	Comment,
	lastuser,
'D' from deleted

END
