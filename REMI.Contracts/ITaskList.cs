using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace REMI.Contracts
{
   public  interface ITaskList
    {
       List<ITaskModel> Tasks { get; set; }
    }
}
