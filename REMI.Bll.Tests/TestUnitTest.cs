using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using REMI.BusinessEntities;
using REMI.Contracts;
using REMI.Dal;
using System.Configuration;

namespace REMI.Bll.Tests
{
    [TestFixture]
    public class TestUnitTest : REMIManagerBase
    {
        REMI.Entities.Entities instance;

        [SetUp]
        public void SetUp()
        {
            instance = new REMI.Dal.Entities().Instance;
            FakeHttpContext fcontext = new FakeHttpContext();
        }

        [TearDown]
        public void TearDown()
        {
            instance = null;
        }

        [Test]
        public void GetUnitAssignedTo()
        {
            var unit = new REMI.Entities.TestUnit();
            unit = (from u in instance.TestUnits.Include("Batch") where u.BSN > 0 && u.AssignedTo != String.Empty orderby u.Batch.ID descending select u).FirstOrDefault();

            Assert.IsNotNullOrEmpty(TestUnitManager.GetUnitAssignedTo(unit.Batch.QRANumber, unit.BatchUnitNumber));
            
            unit = (from u in instance.TestUnits.Include("Batch") where u.BSN > 0 && u.AssignedTo == null orderby u.Batch.ID descending select u).FirstOrDefault();

            Assert.IsNullOrEmpty(TestUnitManager.GetUnitAssignedTo(unit.Batch.QRANumber, unit.BatchUnitNumber));
        }

        [Test]
        public void GetUnitBSN()
        {
            var unit = new REMI.Entities.TestUnit();
            unit = (from u in instance.TestUnits.Include("Batch") where u.BSN > 0 orderby u.Batch.ID descending select u).FirstOrDefault();

            Assert.That(TestUnitManager.GetUnitBSN(unit.Batch.QRANumber, unit.BatchUnitNumber) > 0);
            Assert.That(TestUnitManager.GetUnitBSN("QRA-14", 1) == 0);
        }

        [Test]
        public void GetUnitID()
        {
            var unit = new REMI.Entities.TestUnit();
            unit = (from u in instance.TestUnits.Include("Batch") where u.BSN > 0 orderby u.Batch.ID descending select u).FirstOrDefault();

            Assert.That(TestUnitManager.GetUnitID(unit.Batch.QRANumber, unit.BatchUnitNumber) > 0);
            Assert.That(TestUnitManager.GetUnitID("QRA-14", 1) == 0);
        }

        [Test]
        public void GetAvailableUnits()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches.Include("TestUnits") where b.TestUnits.Count > 2 orderby b.ID descending select b).FirstOrDefault();

            Assert.That(TestUnitManager.GetAvailableUnits(batch.QRANumber, 1).Count > 0);
            Assert.That(TestUnitManager.GetAvailableUnits("QRA-14", 1).Count == 0);
        }

        [Test]
        public void GetNumOfUnits()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches.Include("TestUnits") where b.TestUnits.Count > 2 orderby b.ID descending select b).FirstOrDefault();

            Assert.That(TestUnitManager.GetNumOfUnits(batch.QRANumber) > 0);
            Assert.That(TestUnitManager.GetNumOfUnits("QRA-14") == 0);
        }

        [Test]
        public void GetRAWUnitInformation()
        {
            var unit = new REMI.Entities.TestUnit();
            unit = (from u in instance.TestUnits.Include("Batch") where u.BSN > 0 orderby u.Batch.ID descending select u).FirstOrDefault();

            Assert.IsNotNull(TestUnitManager.GetRAWUnitInformation(unit.Batch.QRANumber, unit.BatchUnitNumber));
            Assert.IsNull(TestUnitManager.GetRAWUnitInformation("QRA-14", 1));
        }

        [Test]
        public void Save()
        {
            var unit = new REMI.Entities.TestUnit();
            unit = (from u in instance.TestUnits.Include("Batch") where u.BSN > 0 orderby u.Batch.ID descending select u).FirstOrDefault();
            DeviceBarcodeNumber bc = new DeviceBarcodeNumber(unit.Batch.QRANumber, unit.BatchUnitNumber.ToString());

            BatchView b = BatchManager.GetBatchView(unit.Batch.QRANumber, false, true, false, false, false, false, false, false, false, false);

            TestUnit tu = b.TestUnits[0];

            Assert.That(TestUnitManager.Save(tu) > 0);
        }
    }
}
