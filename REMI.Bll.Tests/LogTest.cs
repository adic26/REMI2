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
    public class LogTest : REMIManagerBase
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
        public void GetCurrentLog()
        {
            var tu = new REMI.Entities.TestUnit();
            tu = (from u in instance.TestUnits.Include("Batch") where u.Batch.QRANumber.StartsWith("QRA-14") orderby u.Batch.QRANumber ascending, u.ID ascending select u).FirstOrDefault();

            Assert.That(TrackingLogManager.GetCurrentLog(tu.ID).ID > 0);
        }

        [Test]
        public void GetLastTrackingLog()
        {
            var tu = new REMI.Entities.TestUnit();
            tu = (from u in instance.TestUnits.Include("Batch") where u.Batch.QRANumber.StartsWith("QRA-14") orderby u.Batch.QRANumber ascending, u.ID ascending select u).FirstOrDefault();

            DeviceBarcodeNumber bc = new DeviceBarcodeNumber(tu.Batch.QRANumber, "1");

            Assert.That(TrackingLogManager.GetLastTrackingLog(bc).ID > 0);

            Assert.That(TrackingLogManager.GetLastTrackingLog(tu.ID).ID > 0);

            Assert.That(TrackingLogManager.GetTrackingLogsForUnitByBarcode(bc.Number).Count > 0);

            try
            {
                TrackingLogManager.Get24HourLogsForTestUnit(tu.ID, 24);
            }
            catch (Exception err)
            {
                Assert.Fail("Expected no exception, but got: " + err.Message);
            }
        }

        [Test]
        public void Get24HourLogsForBatch()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches where b.QRANumber.StartsWith("QRA-14") orderby b.QRANumber ascending select b).FirstOrDefault();

            try
            {
                TrackingLogManager.Get24HourLogsForBatch(batch.QRANumber, 24);
            }
            catch (Exception err)
            {
                Assert.Fail("Expected no exception, but got: " + err.Message);
            }
        }

        [Test]
        public void Get24HourLogsForProduct()
        {
            var prod = new REMI.Entities.Product();
            prod = (from p in instance.Products orderby p.ID descending select p).FirstOrDefault();

            try
            {
                TrackingLogManager.Get24HourLogsForProduct(prod.ID, 24);
            }
            catch (Exception err)
            {
                Assert.Fail("Expected no exception, but got: " + err.Message);
            }
        }

        [Test]
        public void Get24HourLogsForLocation()
        {
            var tl = new REMI.Entities.TrackingLocation();
            tl = (from t in instance.TrackingLocations orderby t.ID descending select t).FirstOrDefault();

            try
            {
                TrackingLogManager.Get24HourLogsForLocation(tl.ID, 24);
            }
            catch (Exception err)
            {
                Assert.Fail("Expected no exception, but got: " + err.Message);
            }
        }

        [Test]
        public void GetTrackingLogsForTestRecord()
        {
            var tr = new REMI.Entities.TestRecord();
            tr = (from r in instance.TestRecords where r.TestRecordsXTrackingLogs.Count > 0 orderby r.ID descending select r).FirstOrDefault();

            try
            {
                Assert.That(TrackingLogManager.GetTrackingLogsForTestRecord(tr.ID).Count > 0);
            }
            catch (Exception err)
            {
                Assert.Fail("Expected no exception, but got: " + err.Message);
            }
        }
    }
}
