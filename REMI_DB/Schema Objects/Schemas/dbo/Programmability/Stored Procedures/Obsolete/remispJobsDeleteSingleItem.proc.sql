CREATE PROCEDURE [dbo].[remispJobsDeleteSingleItem]
/*	'===============================================================
	'   NAME:                	remispJobsDeleteSingleItem
	'   DATE CREATED:       	20 April 2009
	'   CREATED BY:          	Darragh O'Riordan
	'   FUNCTION:            	deletes a job from the database    
	'   VERSION: 1                   
	'   COMMENTS:            
	'   MODIFIED ON:         
	'   MODIFIED BY:         
	'   REASON FOR MODIFICATION: 
	'===============================================================*/
	@ID int,
	@UserName nvarchar(255)
	
	AS
	begin transaction deletejobs
	
	
	execute remispTestStagesDeleteSingleItem @ID, @username

	UPDATE Jobs SET LastUser = @username WHERE (ID = @ID)
	
	delete from Jobs where ID = @id
	
	
	commit transaction deletejobs