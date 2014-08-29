CREATE procedure [dbo].[remispSetProductGroupRFBand]

@productGroupName nvarchar(400),
@RFBands nvarchar(400),
@lastUser nvarchar(255)
as
--if it's an existing product then update the rfvalue
if ((select productgroupname from rfbands where productgroupname = @productGroupName) is not null)
begin
update RFBands set RFBands = @RFBands, lastuser=@lastUser where ProductGroupName = @productGroupName
end
else
begin
--otherwise just insert the new product value
insert into RFBands (ProductGroupName, RFBands, LastUser) values (@productGroupName,@RFBands, @lastuser)
end

	IF (@@ERROR != 0)
	BEGIN
		RETURN -1
	END
	ELSE
	BEGIN
		RETURN 0
	END

