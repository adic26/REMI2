using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace REMI.Contracts
{
   public interface ITaskModel
    {
        int ProcessOrder { get; set; }
        int TestID { get; set; }
        int TestStageID { get; set; }
       string TestStageName { get; set; }
       string TestName { get; set; }
       bool ResultBaseOnTime { get; set; }
       TestType TestType { get; set; }
       TestStageType TestStageType { get; set; }
       int[] UnitsForTask { get; }
       void SetUnitsForTask(string units);
       Boolean IsArchived { get; set; }
       Boolean TestIsArchived { get; set; }

       TimeSpan ExpectedDuration { get; set; }
    }
}
