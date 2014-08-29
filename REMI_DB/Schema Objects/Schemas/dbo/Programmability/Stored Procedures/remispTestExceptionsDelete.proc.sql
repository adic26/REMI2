ALTER PROCEDURE [dbo].[remispTestExceptionsDelete] @id int, @lastuser nvarchar(255)
AS
BEGIN	
	update TestExceptions set LastUser = @lastuser where ID= @id

	delete from TestExceptions where TestExceptions.ID = @id
	
	return @id
END
GO
GRANT EXECUTE ON remispTestExceptionsDelete TO REMI
GO