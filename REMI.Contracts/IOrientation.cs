using System;
using System.Collections.Generic;

namespace REMI.Contracts
{
    public interface IOrientation
    {
        int ID { get; set; }
        string Name { get; set; }
        string Definition { get; set; }
        string Description { get; set; }
        string ProductType { get; set; }
        DateTime CreatedDate { get; set; }
        bool IsActive { get; set; }
        int ProductTypeID { get; set; }
        int NumUnits { get; set; }
        int NumDrops { get; set; }
        int JobID { get; set; }
    }
}