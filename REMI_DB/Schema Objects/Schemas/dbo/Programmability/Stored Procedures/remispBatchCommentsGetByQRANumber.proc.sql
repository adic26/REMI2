CREATE PROCEDURE [dbo].[remispBatchCommentsGetByQRANumber]
/*	'===============================================================
	'   NAME:                	remispBatchCommentsGetByQRANumber
	'   DATE CREATED:       	5 July 2011
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	Retrieves a list of batch comments
	'   VERSION: 1           
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON MODIFICATION: 
	'===============================================================*/

	@QRANumber nvarchar(11) = null
as
declare @batchid int = (select id from batches where QRANumber = @QRANumber)
select bc.DateAdded, bc.ID, bc.[Text], bc.LastUser from BatchComments as bc
 where  bc.BatchID = @batchid and bc.Active = 1 order by DateAdded desc;
	RETURN
