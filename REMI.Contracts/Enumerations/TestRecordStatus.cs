using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace REMI.Contracts
{
    public enum TestRecordStatus
    {
           // <summary> 
        // Indicates an unknown status. 
        // </summary> 
        NotSet = 0,
        // <summary> 
        // Indicates complete with a fail result. Thsi means the test result requires a review.
        // </summary> 
        CompleteFail = 1,
        // <summary> 
        // Indicates complete and passed. 
        // </summary> 
        Complete = 2,
        // <summary> 
        // Indicates the required FA has been raised. 
        // </summary> 
        FARaised = 3,
        // <summary> 
        // Indicates the an FA is required. 
        // </summary> 
        FARequired = 4,
        // <summary> 
        // Indicates a retest is required
        // </summary> 
        NeedsRetest = 5,
        //' <summary> 
        //' Indicates the result has been reviewed and is a known failure so the units should continue
        //' </summary> 
        CompleteKnownFailure = 6,
        // <summary> 
        // Indicates that the device has been through a test but relab does not have a result yet or the user has not entered a manual result for a non
        // relab test yet.
        // </summary> 
        WaitingForResult = 7,
        // <summary> 
        // Indicates that the test in in progress for this device.
        // </summary> 
        InProgress = 8,
        // <summary> 
        // Indicates that this unit cannot be tested.
        // </summary> 
        Quarantined = 9,
        // <summary> 
        // Indicates an fa is complete and the units were returned to test
        // </summary> 
        FAComplete_InTest = 10,
        // <summary> 
        // Indicates the FA is complete and the unit was not returned to test. 
        // </summary> 
        FAComplete_OutOfTest = 11,
        // <summary> 
        // Indicates the unit has partially completed testing but testing is not underway
        // </summary> 
        TestingSuspended = 12
    }
}
