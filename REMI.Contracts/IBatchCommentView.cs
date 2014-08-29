using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace REMI.Contracts
{
    public interface IBatchCommentView
    {
        int Id { get; set; }
        string Text { get; set; }
        string UserName { get; set; }
        DateTime DateAdded { get; set; }
    }
}
