
namespace REMI.Contracts
{
    public enum TestStageCompletionStatus
    {
                // <summary>
        // Represents an unset status
        // </summary>
        // <remarks></remarks>
        NotSet = 0,
        // <summary>
        // Represents the case when testing is not complete yet. there are outstanding tests
        // </summary>
        // <remarks></remarks>
        InProgress = 1,
        // <summary>
        // Indicates all testing is complete but there are fails that require review
        // </summary>
        // <remarks></remarks>
        TestingComplete = 2,
        // <summary>
        // Indicates testing is complete and there were no items require review or all of these reviews are complete.
        // </summary>
        // <remarks></remarks>
        ReadyForNextStage = 3,
        ProcessComplete = 4
    }
}
