using System;
namespace REMI.BaseObjectModels
{
    public class TaskAssignment
    {
        public int TaskID { get; set; }
        public string TaskName { get; set; }
        public string AssignedTo { get; set; }
        public string AssignedBy { get; set; }
        public DateTime AssignedOn { get; set; }
    }
}
