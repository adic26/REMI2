using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using REMI.Contracts;

namespace REMI.BaseObjectModels
{
    [Serializable] 
    public class BatchCommentView : IBatchCommentView
    {
        public int Id { get; set; }
        public string Text { get; set; }
        public string UserName { get; set; }
        public DateTime DateAdded { get; set; }
    }
}