using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using REMI.BusinessEntities;
using REMI.Contracts;
using REMI.Dal;

namespace REMI.Bll.Tests
{
    public class TestRecordTest : REMIManagerBase
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
        public void GetItemByID()
        {
            var tr = new REMI.Entities.TestRecord();
            tr = (from r in instance.TestRecords orderby r.ID descending select r).FirstOrDefault();

            Assert.IsNotNull(TestRecordManager.GetItemByID(tr.ID));
            Assert.IsNull(TestRecordManager.GetItemByID(0).QRANumber);
        }

        [Test]
        public void GetTestRecordAuditLogs()
        {
            var tr = new REMI.Entities.TestRecord();
            tr = (from r in instance.TestRecords orderby r.ID descending select r).FirstOrDefault();

            Assert.IsNotNull(TestRecordManager.GetTestRecordAuditLogs(tr.ID));
            Assert.IsNotNull(TestRecordManager.GetTestRecordAuditLogs(0));
        }

        [Test]
        public void Save()
        {
            var tr = new REMI.Entities.TestRecord();
            tr = (from r in instance.TestRecords orderby r.ID descending select r).FirstOrDefault();

            TestRecord record = TestRecordManager.GetItemByID(tr.ID);

            Assert.That(TestRecordManager.Save(record) > 0);
        }

        [Test]
        public void UpdateStatus()
        {
            var tr = new REMI.Entities.TestRecord();
            tr = (from r in instance.TestRecords orderby r.ID descending select r).FirstOrDefault();

            Assert.That(TestRecordManager.UpdateStatus(tr.ID, TestRecordStatus.NotSet, String.Empty, false).Count > 0);
            Assert.That(TestRecordManager.UpdateStatus(tr.ID, (TestRecordStatus)tr.Status, String.Empty, false).Count > 0);
        }

        [Test]
        public void CheckBatchForResultUpdates()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches where b.BatchStatus == 2 orderby b.ID descending select b).FirstOrDefault();

            BatchView btc = BatchManager.GetBatchView(batch.QRANumber, false, true, false, false, false, false, false, false, false, false);

            Assert.That(TestRecordManager.CheckBatchForResultUpdates(btc, false) > -1);
        }
    }
}
