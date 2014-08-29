namespace REMI.BaseObjectModels.Enumerations
{  
    // <summary> 
    // Determines the current status of a batch of test units. 
    // </summary> 
    public enum BatchStatus
    {
        // <summary> 
        // Indicates an unidentified value. 
        // </summary> 
        NotSet = 0,
        // <summary> 
        // Indicates the batch has been held for an unknown reason.
        // </summary>
        Held = 1,
        // <summary> 
        // Indicates the batch has started testing. 
        // </summary>
        InProgress = 2,
        // <summary> 
        // Indicates the batch has been quarantined pending FA analysis.
        // </summary> 
        Quarantined = 3,
        // <summary> 
        // Indicates the batch has been given labels and is going through various checks.
        // </summary> 
        Received = 4,
        // <summary> 
        // Indicates the batch has been completed in TRS.
        // </summary> 
        Complete = 5,
        // <summary> 
        // Indicates the batch has been entered in the trs but not saved to remi yet.
        // </summary> 
        NotSavedToREMI = 6,
        // <summary> 
        // Indicates the batch has been entered in to remi but has been rejected by the incoming process.
        // </summary> 
        Rejected = 7,
        // <summary>
        // Indicates that the batch has completed testing. It is not nessecarily 'complete' in TRS.
        // </summary>
        TestingComplete = 8

    }
}
