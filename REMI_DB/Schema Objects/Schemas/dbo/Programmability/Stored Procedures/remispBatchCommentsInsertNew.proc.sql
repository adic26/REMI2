Create PROCEDURE [dbo].[remispBatchCommentsInsertNew]
/*	'===============================================================
	'   NAME:                	remispBatchCommentsInsertNew
	'   DATE CREATED:       	30 July 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Inserts a new comment for a batch
	'===============================================================*/

	@BatchID int, 
	@Text nvarchar(max),
	@LastUser nvarchar(255)

	AS


		INSERT INTO BatchComments
		(
	BatchID, 
	[Text], 
	LastUser,
	Active,
	DateAdded	
		)
		VALUES
		(
	@BatchID, 
	@Text, 
	@LastUser,
	1,
	GETUTCDATE()
		)

		SELECT SCOPE_IDENTITY()
	
