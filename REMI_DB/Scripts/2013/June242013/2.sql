while (select COUNT(*) from Relab.Results where IsProcessed=0)>0
begin
	exec Relab.remispResultsFileProcessing
end