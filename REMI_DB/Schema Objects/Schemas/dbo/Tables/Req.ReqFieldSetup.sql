CREATE TABLE [Req].[ReqFieldSetup](
	[ReqFieldSetupID] [int] IDENTITY(1,1) NOT NULL,
	[RequestTypeID] [int] NOT NULL,
	[Name] [nvarchar](150) NOT NULL,
	[Description] [nvarchar](350) NULL,
	[FieldTypeID] [int] NOT NULL,
	[FieldValidationID] [int] NULL,
	[Archived] [bit] NOT NULL,
	[IsRequired] [bit] NOT NULL,
	[DisplayOrder] [int] NOT NULL,
	[OptionsTypeID] [int] NULL,
	[ColumnOrder] [int] NOT NULL,
	[Category] [nvarchar](100) NOT NULL,
	[ParentReqFieldSetupID] [int] NULL,
 CONSTRAINT [PK_ReqFieldSetup] PRIMARY KEY CLUSTERED 
(
	[ReqFieldSetupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Req].[ReqFieldSetup]  WITH CHECK ADD  CONSTRAINT [FK_ReqFieldSetup_FieldTypeID] FOREIGN KEY([FieldTypeID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [Req].[ReqFieldSetup] CHECK CONSTRAINT [FK_ReqFieldSetup_FieldTypeID]
GO

ALTER TABLE [Req].[ReqFieldSetup]  WITH CHECK ADD  CONSTRAINT [FK_ReqFieldSetup_FieldValidationID] FOREIGN KEY([FieldValidationID])
REFERENCES [dbo].[Lookups] ([LookupID])
GO

ALTER TABLE [Req].[ReqFieldSetup] CHECK CONSTRAINT [FK_ReqFieldSetup_FieldValidationID]
GO

ALTER TABLE [Req].[ReqFieldSetup]  WITH CHECK ADD  CONSTRAINT [FK_ReqFieldSetup_RequestType] FOREIGN KEY([RequestTypeID])
REFERENCES [Req].[RequestType] ([RequestTypeID])
GO

ALTER TABLE [Req].[ReqFieldSetup] CHECK CONSTRAINT [FK_ReqFieldSetup_RequestType]
GO

ALTER TABLE [Req].[ReqFieldSetup] ADD  CONSTRAINT [DF_ReqFieldSetup_Archived]  DEFAULT ((0)) FOR [Archived]
GO

ALTER TABLE [Req].[ReqFieldSetup] ADD  CONSTRAINT [DF_ReqFieldSetup_IsRequired]  DEFAULT ((0)) FOR [IsRequired]
GO

