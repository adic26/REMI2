CREATE function dbo.GetDateDiffInMinutes(@dteStart datetime, @dteEnd datetime)
RETURNS INT
AS
BEGIN
	declare @minutes int
	set @minutes = 0
	
	WHILE @dteEnd >= @dteStart
		BEGIN
			if  (datename(weekday,@dteStart) <> 'Saturday' and datename(weekday,@dteStart) <> 'Sunday') and (datepart(hour,@dteStart) >= 8 and (datepart(hour,@dteStart) < 16))
			begin
				set @minutes = @minutes + 1
			end     
			
			set @dteStart = dateadd(minute,1,@dteStart)
		END
	RETURN @minutes
END
GO