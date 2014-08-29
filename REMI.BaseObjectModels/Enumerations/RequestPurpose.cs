using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace REMI.BaseObjectModels.Enumerations
{
   public enum RequestPurpose
    {
         // <summary> 
        // Indicates an unknown purpose.
        // </summary> 
        NotSet = 0,
        // <summary> 
        // Indicates New Product Qualification
        // </summary> 
        NPQ = 1,
        // <summary>
        // Indicates Production Reliability Monitoring
        // </summary>
        // <remarks></remarks>
        PRM = 2,
        // <summary>
        // Indicates Outsourcing Qualification
        // </summary>
        // <remarks></remarks>
        OQ = 3,
        // <summary>
        // Indicates Design/Process/Part Change Qualification
        // </summary>
        // <remarks></remarks>
        PCQ = 4,
        // <summary>
        // Indicates Supplier Qualification
        // </summary>
        // <remarks></remarks>
        SQ = 5,
        // <summary>
        // Outsourced Manufacturing Qual
        // </summary>
        // <remarks></remarks>
        OMQ = 6,
        // <summary>
        // Outsourced Repair Qual
        // </summary>
        // <remarks></remarks>
        ORQ = 7,
        // <summary>
        // Outsourced Manufacturing Monitoring
        // </summary>
        // <remarks></remarks>
        OMM = 8,
        // <summary>
        // RMA Qualification
        // </summary>
        // <remarks></remarks>
        RMAQ = 9,
        // <summary>
        // Outsourced RMA Qualification
        // </summary>
        // <remarks></remarks>
        ORMAQ = 10,
        // <summary>
        // Indicates internal use only
        // </summary>
        // <remarks></remarks>
        IUO = 11,
        // <summary>
        // Indicates Sample Storage
        // </summary>
        // <remarks></remarks>
       SS =12
    }
}
