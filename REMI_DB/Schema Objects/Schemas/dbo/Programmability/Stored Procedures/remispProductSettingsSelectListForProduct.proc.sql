ALTER PROCEDURE [dbo].[remispProductSettingsSelectListForProduct] @LookupID INT
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
			left outer join ProductSettings as ps2 on ps1.KeyName = ps2.KeyName and ps2.LookupID = @LookupID
	) as keyVals
order by keyname 
GO
GRANT EXECUTE ON remispProductSettingsSelectListForProduct TO Remi