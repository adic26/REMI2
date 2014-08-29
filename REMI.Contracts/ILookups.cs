using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace REMI.Contracts
{
    public interface ILookups : REMI.Validation.IValidatable
    {
        Int32 LookupID { get; set; }
        string Type { get; set; }
        string Value { get; set; }
    }
}