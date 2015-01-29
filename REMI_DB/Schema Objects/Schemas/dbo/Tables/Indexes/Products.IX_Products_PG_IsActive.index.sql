CREATE NONCLUSTERED INDEX [IX_Products_PG_IsActive] ON [dbo].[Products] ([LookupID], [IsActive]) INCLUDE ([ID])
GO