namespace REMI.Contracts
{
    // <summary> 
    // Determines the current status of a batch of test units. 
    // </summary> 
    public enum TRSStatus
    {
        Rejected = 0,
        Assigned = 1,
        Received = 2,
        Submitted = 3,
        PMReview = 4,
        Verified = 5,
    }
}
