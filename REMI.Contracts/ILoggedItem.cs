
namespace REMI.Contracts
{
    public interface ILoggedItem : IBusinessBase
    {
        string LastUser { get; set; }
    }
}