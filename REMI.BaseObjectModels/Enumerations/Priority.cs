using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace REMI.BaseObjectModels.Enumerations
{    // <summary> 
    // Indicates the priority of an item in REMI. 
    // </summary> 
    public enum Priority
    {
        // <summary> 
        // Indicates an unknown priority. 
        // </summary> 
        NotSet = 0,
        // <summary> 
        // Indicates a low priority. 
        // </summary> 
        Low = 1,
        // <summary> 
        // Indicates a normal priority. This is the default.
        // </summary> 
        Medium = 2,
        // <summary> 
        // Indicates a high priority. 
        // </summary> 
        High = 3

    }
}
