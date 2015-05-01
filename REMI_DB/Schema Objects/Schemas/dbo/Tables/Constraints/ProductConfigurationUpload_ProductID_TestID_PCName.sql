ALTER TABLE [dbo].[ProductConfigurationUpload] ADD  CONSTRAINT [ProductConfigurationUpload_ProductID_TestID_PCName] UNIQUE NONCLUSTERED 
(
	[LookupID] ASC,
	[TestID] ASC,
	[PCName] ASC
)