using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace REMI.Contracts
{
    public enum TRSRequestType
    {
        // <summary> 
        // Indicates an unknown number type.
        // </summary> 
        NotSet = 0,
        // <summary> 
        // Indicates a QRA type number - QRA-XX-XXXX
        // </summary> 
        QRARequest = 1,
        // <summary> 
        // Indicates an FA type number - FA-YYYY-XXXXX
        // </summary> 
        FARequest = 2,
        // <summary> 
        // Indicates an RIT type number - RIT-YYYY-XXXXX
        // </summary> 
        RITRequest = 3,
        // <summary> 
        // Indicates an SCM type number - SCM-YYYY-XXXXX
        // </summary> 
        SCMRequest = 4
    }
}
