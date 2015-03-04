CREATE TABLE [Req].[ReqFieldSetupSibling](
	[ReqFieldSiblingID] [int] IDENTITY(1,1) NOT NULL,
	[ReqFieldSetupID] [int] NOT NULL,
	[DefaultDisplayNum] [int] NOT NULL,
	[MaxDisplayNum] [int] NOT NULL,
 CONSTRAINT [PK_ReqFieldSetupSibling] PRIMARY KEY CLUSTERED 
(
	[ReqFieldSiblingID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Req].[ReqFieldSetupSibling]  WITH CHECK ADD  CONSTRAINT [FK_ReqFieldSetupSibling_ReqFieldSetup] FOREIGN KEY([ReqFieldSetupID])
REFERENCES [Req].[ReqFieldSetup] ([ReqFieldSetupID])
GO

ALTER TABLE [Req].[ReqFieldSetupSibling] CHECK CONSTRAINT [FK_ReqFieldSetupSibling_ReqFieldSetup]
GO

ALTER TABLE [Req].[ReqFieldSetupSibling] ADD  CONSTRAINT [DF_ReqFieldSetupSibling_DefaultDisplayNum]  DEFAULT ((1)) FOR [DefaultDisplayNum]
GO

ALTER TABLE [Req].[ReqFieldSetupSibling] ADD  CONSTRAINT [DF_ReqFieldSetupSibling_MaxDisplayNum]  DEFAULT ((2)) FOR [MaxDisplayNum]
GO