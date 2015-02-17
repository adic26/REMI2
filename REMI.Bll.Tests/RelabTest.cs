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
    public class RelabTest : REMIManagerBase
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
        public void ResultSummary()
        {
            var result = new REMI.Entities.Result();
            result = (from r in instance.Results.Include("TestUnit").Include("TestUnit.Batch") orderby r.ID descending select r).FirstOrDefault();
            
            Assert.That(RelabManager.ResultSummary(result.TestUnit.Batch.ID).Rows.Count > 0);
            Assert.That(RelabManager.ResultSummary(0).Rows.Count == 0);
        }

        [Test]
        public void OverallResultSummary()
        {
            var result = new REMI.Entities.Result();
            result = (from r in instance.Results.Include("TestUnit").Include("TestUnit.Batch") orderby r.ID descending select r).FirstOrDefault();

            Assert.That(RelabManager.OverallResultSummary(result.TestUnit.Batch.ID).Rows.Count > 0);
            Assert.That(RelabManager.OverallResultSummary(0).Rows.Count == 0);
        }

        [Test]
        public void FailureAnalysis()
        {
            var result = new REMI.Entities.Result();
            result = (from r in instance.Results.Include("TestUnit").Include("TestUnit.Batch").Include("Test") orderby r.ID descending select r).FirstOrDefault();

            Assert.That(RelabManager.FailureAnalysis(result.Test.ID, result.TestUnit.Batch.ID).Rows.Count > 0);
            Assert.That(RelabManager.FailureAnalysis(0, 0).Rows.Count == 0);
        }

        [Test]
        public void ResultSummaryExport()
        {
            var result = new REMI.Entities.Result();
            result = (from r in instance.Results.Include("TestUnit").Include("TestUnit.Batch").Include("ResultsMeasurements") where r.ResultsMeasurements.Count > 1 orderby r.ID descending select r).FirstOrDefault();

            Assert.That(RelabManager.ResultSummaryExport(result.TestUnit.Batch.ID, result.ID).Rows.Count > 0);
            Assert.That(RelabManager.ResultSummaryExport(0, 0).Rows.Count == 0);
        }

        [Test]
        public void ResultMeasurements()
        {
            var result = new REMI.Entities.Result();
            result = (from r in instance.Results.Include("TestUnit").Include("TestUnit.Batch").Include("ResultsMeasurements") where r.ResultsMeasurements.Count > 1 orderby r.ID descending select r).FirstOrDefault();

            Assert.That(RelabManager.ResultMeasurements(result.ID, false, false).Rows.Count > 0);
            Assert.That(RelabManager.ResultMeasurements(0, false, false).Rows.Count == 0);
        }

        [Test]
        public void ResultVersions()
        {
            var result = new REMI.Entities.Result();
            result = (from r in instance.Results.Include("TestUnit").Include("TestUnit.Batch").Include("ResultsMeasurements").Include("Test") where r.ResultsMeasurements.Count > 1 orderby r.ID descending select r).FirstOrDefault();

            Assert.That(RelabManager.ResultVersions(result.Test.ID, result.TestUnit.Batch.ID,0,0).Rows.Count > 0);
            Assert.That(RelabManager.ResultVersions(0, result.TestUnit.Batch.ID,0,0).Rows.Count == 0);
        }

        [Test]
        public void GetMeasurementParameterCommaSeparated()
        {
            var rm = new REMI.Entities.ResultsMeasurement();
            rm = (from m in instance.ResultsMeasurements.Include("ResultsParameters") where m.ResultsParameters.Count > 1 orderby m.ID descending select m).FirstOrDefault();

            Assert.That(RelabManager.GetMeasurementParameterCommaSeparated(rm.ID).Rows.Count > 0);
            Assert.That(RelabManager.GetMeasurementParameterCommaSeparated(0).Rows.Count == 1);
        }
    }
}
