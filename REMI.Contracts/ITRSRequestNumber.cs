using System;

namespace REMI.Contracts
{
    public interface ITRSRequestNumber
    {
        string Number { get; set; }
        TRSRequestType Type { get; }
    }
}
