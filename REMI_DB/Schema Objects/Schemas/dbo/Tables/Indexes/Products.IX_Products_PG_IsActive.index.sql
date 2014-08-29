CREATE NONCLUSTERED INDEX [IX_Products_PG_IsActive] ON [dbo].[Products] ([ProductGroupName], [IsActive]) INCLUDE ([ID])
GO