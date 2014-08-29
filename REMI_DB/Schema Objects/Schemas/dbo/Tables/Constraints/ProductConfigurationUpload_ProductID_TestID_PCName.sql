ALTER TABLE [dbo].[ProductConfigurationUpload] ADD  CONSTRAINT [ProductConfigurationUpload_ProductID_TestID_PCName] UNIQUE NONCLUSTERED 
(
	[ProductID] ASC,
	[TestID] ASC,
	[PCName] ASC
)