﻿CREATE TABLE [Req].[Request](
	[RequestID] [int] IDENTITY(1,1) NOT NULL,
	[RequestNumber] [nvarchar](11) NOT NULL,
	rv ROWVERSION,
 CONSTRAINT [PK_Request] PRIMARY KEY CLUSTERED 
(
	[RequestID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
go
ALTER TABLE Req.Request
 ADD CONSTRAINT uc_RequestNumber UNIQUE (RequestNumber)