using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace REMI.Contracts
{
    /// <summary>
    /// This enum represents the security access allowed by a user at a tracking location
    /// </summary>
    [Flags]
    public enum TrackingLocationUserAccessPermission
    {
        /// <summary>
        /// User has no access. Cannot run test.
        /// </summary>
        None = 0, 
        /// <summary>
        /// User has basic access. Can run the test as it is pre-configured;.
        /// </summary>
        BasicTestAccess = 1,
        /// <summary>
        /// The user can modify the test procedure to run a smaller subset of tests for example
        /// </summary>
        ModifiedTestAccess =  1 << 1,
        /// <summary>
        /// The user can calibrate the test if applicable.
        /// </summary>
        CalibrationAccess = 1 << 2
    }
}
