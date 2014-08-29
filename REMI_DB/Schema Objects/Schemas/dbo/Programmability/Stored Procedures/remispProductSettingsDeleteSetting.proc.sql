alter PROCEDURE [dbo].[remispProductSettingsDeleteSetting]
/*	'===============================================================
'   NAME:                	remispProductSettingsDeleteSetting
'   DATE CREATED:       	4 Nov 2011
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Deletes an entry from table: ProductSettings 
'   VERSION: 1           
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON MODIFICATION: 
	'===============================================================*/
	@ProductID INT,
	@keyname as nvarchar(MAX),
	@userName as nvarchar(255)
AS 
	
declare @id int =(select ProductSettings.id from ProductSettings where ProductID = @ProductID and KeyName = @keyname)

if (@id is not null)
begin
	update ProductSettings set LastUser = @userName where ID = @id;
	Delete FROM ProductSettings where ID = @id;
end
GO
GRANT EXECUTE ON remispProductSettingsDeleteSetting TO Remi