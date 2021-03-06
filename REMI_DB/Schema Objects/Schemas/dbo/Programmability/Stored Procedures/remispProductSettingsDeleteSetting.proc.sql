﻿alter PROCEDURE [dbo].[remispProductSettingsDeleteSetting]
	@lookupid INT,
	@keyname as nvarchar(MAX),
	@userName as nvarchar(255)
AS 
	
declare @id int =(select ProductSettings.id from ProductSettings where LookupID = @lookupid and KeyName = @keyname)

if (@id is not null)
begin
	update ProductSettings set LastUser = @userName where ID = @id;
	Delete FROM ProductSettings where ID = @id;
end
GO
GRANT EXECUTE ON remispProductSettingsDeleteSetting TO Remi