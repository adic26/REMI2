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
    public class BatchTest : REMIManagerBase
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
        public void GetBatchDocuments()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches.Include("TestUnits") where b.TestUnits.Count > 2 orderby b.ID descending select b).FirstOrDefault();

            Assert.That(BatchManager.GetBatchDocuments(batch.QRANumber).Rows.Count > 0);
            Assert.That(BatchManager.GetBatchDocuments("QRA-14").Rows.Count == 1);
        }

        [Test]
        public void GetReqString()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches orderby b.ID descending select b).FirstOrDefault();
            DeviceBarcodeNumber bc = new DeviceBarcodeNumber(batch.QRANumber);

            Assert.IsNotEmpty(BatchManager.GetReqString(bc.BatchNumber));
            Assert.IsNotEmpty(BatchManager.GetReqString(bc.BatchNumber.Replace("QRA-", "")));
            Assert.IsEmpty(BatchManager.GetReqString(String.Empty));
        }

        [Test]
        public void GetBatchAuditLogs()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches orderby b.ID descending select b).FirstOrDefault();

            Assert.IsNotNull(BatchManager.GetBatchAuditLogs(batch.QRANumber));
        }

        [Test]
        public void GetRAWBatchInformation()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches orderby b.ID descending select b).FirstOrDefault();

            Assert.IsNotNull(BatchManager.GetRAWBatchInformation(batch.QRANumber));
        }

        [Test]
        public void GetActiveBatches()
        {
            Assert.IsNotNull(BatchManager.GetActiveBatches());
        }

        [Test]
        public void GetActiveBatches2()
        {
            Assert.IsNotNull(BatchManager.GetActiveBatches("ogaudreault"));
        }

        [Test]
        public void BatchSearch()
        {
            BatchSearch bs = new BatchSearch();
            bs.Status = BatchStatus.TestingComplete;

            Assert.IsNotNull(BatchManager.BatchSearch(bs, false, 0));
        }

        [Test]
        public void GetViewBatch()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches orderby b.ID descending select b).FirstOrDefault();

            Assert.That(BatchManager.GetViewBatch(batch.QRANumber).ID > 0);
        }

        [Test]
        public void GetBatchComments()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches orderby b.ID descending select b).FirstOrDefault();

            Assert.IsNotNull(BatchManager.GetBatchComments(batch.QRANumber));
        }

        [Test]
        public void SaveBatchComment()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches orderby b.ID descending select b).FirstOrDefault();

            Assert.IsTrue(BatchManager.SaveBatchComment(batch.QRANumber, "remi", "Testing..."));
        }

        [Test]
        public void SaveExecutiveSummary()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches orderby b.ID descending select b).FirstOrDefault();

            Assert.IsTrue(BatchManager.SaveExecutiveSummary(batch.QRANumber, "remi", "Testing..."));
        }

        [Test]
        public void Save()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches orderby b.ID descending select b).FirstOrDefault();
            Batch bt = BatchManager.GetItem(batch.QRANumber);
            
            Assert.That(BatchManager.Save(bt) > 0);
        }

        [Test]
        public void SetPriority()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches orderby b.ID descending select b).FirstOrDefault();
            var p = new REMI.Entities.Lookup();
            p = (from l in instance.Lookups where l.LookupType.Name == "Priority" && l.IsActive == 1 orderby l.LookupID descending select l).FirstOrDefault();

            Assert.That(BatchManager.SetPriority(batch.QRANumber, p.LookupID, p.Values).Count > 0);
        }

        [Test]
        public void SetStatus()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches orderby b.ID descending select b).FirstOrDefault();

            Assert.That(BatchManager.SetStatus(batch.QRANumber, BatchStatus.InProgress).Count > 0);
        }

        [Test]
        public void ChangeTestStage()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches orderby b.ID descending select b).FirstOrDefault();

            Assert.That(BatchManager.ChangeTestStage(batch.QRANumber, "Baseline").Count > 0);
        }
    }
}
