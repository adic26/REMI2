Create PROCEDURE [dbo].[remispBatchCommentsDeactivate]
/*	'===============================================================
	'   NAME:                	remispBatchCommentsDeactivate
	'   DATE CREATED:       	30 July 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Deactivates a comment
	'===============================================================*/

	@CommentID int

	AS

	update batchcomments set active = 0 where id = @commentid
