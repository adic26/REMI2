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
    }
}
