using System.Collections.Generic;

namespace REMI.Contracts
{
    public interface ITRSRequest
    {
        ITRSRequestNumber TRSReqNumber { get; set; }
        string RequestNumber { get; }
        Dictionary<string, string> RequestProperties { get; set; }
        TRSRequestType RequestType { get; }
        string Requestor { get; set; }
        string Summary { get; }
        bool Validate();
        string RequestStatus { get; set; }
        int RQID { get; set; }
        string TRSLink { get; }
    }
}