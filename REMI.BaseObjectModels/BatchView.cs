using System.Collections.Generic;
using System;
using System.Linq;
using REMI.Contracts;
namespace REMI.BaseObjectModels
{
    public class BatchView : IEquatable<BatchView>, ICommentedItem
    {
        public BatchView()
        {
            this._testUnits = new List<TestUnitView>();
        }

        private List<TestUnitView> _testUnits;
        public string ProductGroup { get; set; }
        public string ProductType { get; set; }
        public string AccessoryGroup { get; set; }
        public string QRANumber { get; set; }
        public string TestCenter { get; set; }
        public String RequestPurpose { get; set; }
        public Int32 RequestPurposeID { get; set; }
        public BatchStatus Status { get; set; }
        public String Priority { get; set; }
        public Int32 PriorityID { get; set; }
        public Boolean HasBatchSpecificExceptions { get; set; }
        public List<IBatchCommentView> Comments { get; set; }
        public TestStageCompletionStatus TestStageCompletionStatus { get; set; }
        public void AddTestUnit(TestUnitView tu) { _testUnits.Add(tu); }
        public IEnumerable<TestUnitView> TestUnits { get { return _testUnits; } }

        public override bool Equals(object otherObject)
        {
            BatchView otherBatch = otherObject as BatchView;
            return this.Equals(otherBatch);
        }

        public override int GetHashCode()
        {
            int hashQRANumber = QRANumber == null ? 0 : QRANumber.GetHashCode();
            return hashQRANumber;
        }

        public bool Equals(BatchView otherBatch)
        {
            if (otherBatch == null)
                return false;

            return this.Priority.Equals(otherBatch.Priority) &&
            this.ProductGroup.Equals(otherBatch.ProductGroup) &&
            this.QRANumber.Equals(otherBatch.QRANumber) &&
            this.RequestPurpose.Equals(otherBatch.RequestPurpose) &&
            this.Status.Equals(otherBatch.Status) &&
            this.TestCenter.Equals(otherBatch.TestCenter) &&
            this.TestStageCompletionStatus.Equals(otherBatch.TestStageCompletionStatus) &&
            this.TestUnits.SequenceEqual(otherBatch.TestUnits);
        }
    }
}