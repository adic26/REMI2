CREATE TABLE [dbo].[TaskAssignments] (
    [BatchID]    INT            NOT NULL,
    [ID]         INT            IDENTITY (1, 1) NOT NULL,
    [TaskID]     INT            NULL,
    [AssignedBy] NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [AssignedTo] NVARCHAR (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [Active]     BIT            NOT NULL,
    [AssignedOn] DATETIME       NOT NULL
);

