using System;
namespace REMI.BaseObjectModels
{
    /// <summary>
    /// This is the basic class for a test unit. It is designed to be used as part of 
    /// a Batch.
    /// </summary>
    public class TestUnitView: IEquatable<TestUnitView>
    {
        public int BatchUnitNumber { get; set; }
        public long BSN { get; set; }
        public string AssignedTo { get; set; }
        public string TestStage { get; set; }
        public string CurrentTest { get; set; }
        public string CurrentLocation { get; set; }

        public override bool Equals(object obj)
        {          
            return base.Equals(obj as TestUnitView);
        }
        public override int GetHashCode()
        {
            return BatchUnitNumber ^ BSN.GetHashCode(); 
        }
        #region IEquatable<TestUnitView> Members

        public bool Equals(TestUnitView other)
        {
            return this.AssignedTo == other.AssignedTo &&
                this.BatchUnitNumber == other.BatchUnitNumber &&
                this.BSN == other.BSN &&
                this.CurrentLocation == other.CurrentLocation &&
                this.CurrentTest == other.CurrentTest &&
                this.TestStage == other.TestStage;
        }

        #endregion
    }
}
