using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace REMI.Contracts
{    // <summary> 
    // Indicates the current type of a test. 
    // </summary> 
   public enum TestType
    {  
        // <summary> 
        // Indicates an unidentified value.
        // </summary> 
        NotSet = 0,
        // <summary> 
        // Indicates the test is a parametric test.
        // </summary> 
        Parametric = 1,
        // <summary> 
        // Indicates the test is an Environmental stress test.
        // </summary>
        EnvironmentalStress = 2,
        // <summary> 
        // Indicates the test is an incoming evaluation test.
        // </summary> 
        IncomingEvaluation = 3,
        // <summary> 
        // Indicates the test is a non testing task.
        // </summary> 
        NonTestingTask = 4

    }
}
