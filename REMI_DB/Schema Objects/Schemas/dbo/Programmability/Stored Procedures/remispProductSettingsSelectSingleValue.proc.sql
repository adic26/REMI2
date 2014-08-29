ALTER PROCEDURE [dbo].[remispProductSettingsSelectSingleValue]
/*	'===============================================================
'   NAME:                	remispProductSettingsSelectSingleValue
'   DATE CREATED:       	4 Nov 2011
'   CREATED BY:          	Darragh O'Riordan
'   FUNCTION:            	Retrieves data from table: ProductSettings 
'   VERSION: 1           
'   COMMENTS:            
'   MODIFIED ON:         
'   MODIFIED BY:         
'   REASON MODIFICATION: 
	'===============================================================*/
	@ProductID INT,
	@keyname as nvarchar(MAX)
AS
declare @valueText nvarchar(MAX);
declare @defaultValue nvarchar(MAX);
	
set @valuetext = (select ValueText FROM ProductSettings as ps where ps.ProductID = @ProductID and KeyName = @keyname)
set @defaultValue =(select top (1) DefaultValue FROM ProductSettings as ps where KeyName = @keyname and DefaultValue is not null)
select case when @valueText is not null then @valueText else @defaultValue end as [ValueText];
GO
GRANT EXECUTE ON remispProductSettingsSelectSingleValue TO Remi