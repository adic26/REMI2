ALTER FUNCTION dbo.Split(@sep nvarchar(5) = ',', @s nvarchar(MAX))
RETURNS @RtnValue table
(
    RowID INT NOT NULL IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    s nvarchar(100) NOT NULL
)
AS
BEGIN
    IF @s IS NULL RETURN
    IF @s = '' RETURN

    DECLARE @split_on_len INT = LEN(@sep)
    DECLARE @start_at INT = 1
    DECLARE @end_at INT
    DECLARE @data_len INT

    WHILE 1=1
    BEGIN
        SET @end_at = CHARINDEX(@sep,@s,@start_at)
        SET @data_len = CASE @end_at WHEN 0 THEN LEN(@s) ELSE @end_at-@start_at END
        INSERT INTO @RtnValue (s) VALUES( SUBSTRING(@s,@start_at,@data_len) );
        IF @end_at = 0 BREAK;
        SET @start_at = @end_at + @split_on_len
    END

    RETURN
END
go