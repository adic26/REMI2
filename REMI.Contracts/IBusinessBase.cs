namespace REMI.Contracts
{
    public interface IBusinessBase
    {
        int ID { get; set; }
        byte[] ConcurrencyID { get; set; }
        bool IsNew();

    }
}