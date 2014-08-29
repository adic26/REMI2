using System.Collections.Generic;

namespace REMI.Contracts
{
    public interface ICommentedItem
    {
        List<IBatchCommentView> Comments { get; set; }
    }
}
