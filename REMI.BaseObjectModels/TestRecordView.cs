using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using REMI.Contracts;
namespace REMI.BaseObjectModels
{
    public class TestRecordView : IEquatable<TestRecordView>
    {
        public string Comment { get; set; }
        public string FailDocNumber { get; set; }
        public TestResultSource ResultSource { get; set; }
        public int RelabVersion { get; set; }
        public TestRecordStatus Status { get; set; }
        public int BatchUnitNumber { get; set; }
        public int TotalTestTimeMinutes { get; set; }
        public int NumberOfScansForTest { get; set; }

        public override bool Equals(object obj)
        {
            return Equals(obj as TestRecordView);
        }
        public override int GetHashCode()
        {
            return base.GetHashCode();
        }

        public bool Equals(TestRecordView other)
        {
            return this.BatchUnitNumber == other.BatchUnitNumber &&
                this.Comment == other.Comment &&
                this.FailDocNumber == other.FailDocNumber &&
                this.NumberOfScansForTest == other.NumberOfScansForTest &&
                this.RelabVersion == other.RelabVersion &&
                this.ResultSource == other.ResultSource &&
                this.Status == other.Status &&
                this.TotalTestTimeMinutes == other.TotalTestTimeMinutes;
        }

   
    }
}
