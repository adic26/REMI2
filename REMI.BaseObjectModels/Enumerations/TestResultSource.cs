using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace REMI.BaseObjectModels.Enumerations
{
    public enum TestResultSource
    {
        // <summary> 
        // Indicates an unidentified value.
        // </summary> 
        NotSet = 0,
        // <summary> 
        //Indicates the result came from the relab database.
        // </summary> 
        Relab = 1,
        // <summary> 
        // Indicates the result came from the webservice applications.
        // </summary> 
        WebService = 2,
        // <summary> 
        // Indicates the result came from a manual entry
        // </summary>
        Manual = 3
    }
}
