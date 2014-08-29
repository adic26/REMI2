ALTER PROCEDURE [dbo].[remispProductSettingsSelectListForProduct]
/*	'===============================================================
'   NAME:                	remispProductSettingsSelectList
'   DATE CREATED:       	4 Nov 2011
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Retrieves data from table: ProductSettings 
'   VERSION: 1           
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON MODIFICATION: 
	'===============================================================*/
	@productID INT		
AS 
select keyVals.keyname,
	case when keyVals.valueText is not null then keyVals.valueText 
	else keyVals.defaultValue 
	end as valuetext, 
	keyVals.defaultvalue
from
	(
		select distinct ps1.keyName as keyname, ps2.ValueText, ps1.DefaultValue
		FROM ProductSettings as ps1
			left outer join ProductSettings as ps2 on ps1.KeyName = ps2.KeyName and ps2.ProductID = @productID
	) as keyVals
order by keyname 
GO
GRANT EXECUTE ON remispProductSettingsSelectListForProduct TO Remi