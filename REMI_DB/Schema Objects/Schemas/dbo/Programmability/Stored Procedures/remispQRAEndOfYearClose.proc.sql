ALTER PROCEDURE [dbo].[remispQRAEndOfYearClose]
AS
BEGIN
	BEGIN TRANSACTION

	BEGIN TRY
		DECLARE @query VARCHAR(MAX)
		DECLARE @subject VARCHAR(25)
		DECLARE @dbName VARCHAR(25)
		SET @dbName = CONVERT(VARCHAR, DB_NAME())
		SET @subject = 'QRA Numbers Automatically Completed - ' + @dbName
		SET @query = ''
		
		IF ((SELECT COUNT(*) FROM Batches WHERE QRANumber LIKE 'QRA-' + CONVERT(VARCHAR(2), RIGHT(YEAR(GETDATE()),2)-1) + '-%' AND BatchStatus NOT IN (5,7)) > 0)
		BEGIN
			SET @query = @query + '
			DECLARE @temp TABLE (QRANumber NVARCHAR(11))

			INSERT INTO @temp (QRANumber)
			SELECT QRANumber
			FROM Batches 
			WHERE QRANumber LIKE ''QRA-' + CONVERT(VARCHAR(2), RIGHT(YEAR(GETDATE()),2)-1) + '-%'' AND BatchStatus NOT IN (5,7)

			UPDATE Batches
			SET BatchStatus=5, LastUser=''AutoCloseUser''
			WHERE QRANumber LIKE ''QRA-' + CONVERT(VARCHAR(2), RIGHT(YEAR(GETDATE()),2)-1) + '-%'' AND BatchStatus NOT IN (5,7)
			
			SELECT * FROM @temp'

			  EXEC msdb.dbo.sp_send_dbmail
					@execute_query_database=@dbName,
					@recipients=N'tsdinfrastructure@blackberry.com;jemclaughlin@blackberry.com',
					@body='The attached QRA''s have been automatically closed due to end of year', 
					@subject =@subject,
					@query =@query,
					@attach_query_result_as_file = 1,
					@query_attachment_filename ='QRANumbers.txt'

			  PRINT 'COMMIT TRANSACTION'
			  COMMIT TRANSACTION
		END
	ELSE
		BEGIN
			PRINT 'There Are No Batches Currently Needing Completion'
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		  SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage

		  PRINT 'ROLLBACK TRANSACTION'
		  ROLLBACK TRANSACTION
	END CATCH
END
GO