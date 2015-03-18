ALTER TRIGGER Req.[ReqFieldDataAuditDelete] ON  Req.ReqFieldData
	for  delete
AS 
BEGIN
	SET NOCOUNT ON;

	If not Exists(Select * From Deleted) 
		return	 --No delete action, get out of here
	
	insert into Req.ReqFieldDataAudit (RequestID,ReqFieldSetupID,Value,InsertTime,Action, UserName, ReqFieldDataID, InstanceID)
	Select RequestID,ReqFieldSetupID,Value,InsertTime, 'D', lastuser, ReqFieldDataID, InstanceID from deleted
END