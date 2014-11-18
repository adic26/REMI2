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
    public class StageTest : REMIManagerBase
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
        public void GetTestStage()
        {
            var stage = new REMI.Entities.TestStage();
            stage = (from s in instance.TestStages orderby s.ID descending select s).FirstOrDefault();

            Assert.IsNotNull(TestStageManager.GetTestStage(stage.ID));
            Assert.IsNull(TestStageManager.GetTestStage(0));
        }

        [Test]
        public void GetListOfNamesForChambers()
        {
            var job = new REMI.Entities.Job();
            job = (from j in instance.Jobs where j.IsActive == true orderby j.ID descending select j).FirstOrDefault();

            Assert.IsNotNull(TestStageManager.GetListOfNamesForChambers(job.JobName));
        }

        [Test]
        public void GetTestStage2()
        {
            var stage = new REMI.Entities.TestStage();
            stage = (from s in instance.TestStages.Include("Job") orderby s.ID descending select s).FirstOrDefault();

            Assert.IsNotNull(TestStageManager.GetTestStage(stage.TestStageName, stage.Job.JobName));
            Assert.IsNull(TestStageManager.GetTestStage("test",""));
        }

        [Test]
        public void GetTestStagesNameByBatch()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches.Include("TestUnits") where b.TestUnits.Count > 2 orderby b.ID descending select b).FirstOrDefault();

            Assert.IsNotNull(TestStageManager.GetTestStagesNameByBatch(batch.ID));
        }

        [Test]
        public void GetAllTestStages()
        {
            Assert.That(TestStageManager.GetAllTestStages().Count > 0);
        }

        [Test]
        public void GetListOfNames()
        {
            Assert.That(TestStageManager.GetListOfNames().Count > 0);
        }

        [Test]
        public void GetList()
        {
            var job = new REMI.Entities.Job();
            job = (from j in instance.Jobs.Include("TestStages") where j.IsActive == true && j.TestStages.Count > 0 orderby j.ID descending select j).FirstOrDefault();

            Assert.That(TestStageManager.GetList(TestStageType.Parametric, job.JobName).Count > 0);
        }

        [Test]
        public void AddRemoveTaskAssignment()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches.Include("TestUnits") where b.TestUnits.Count > 2 orderby b.ID descending select b).FirstOrDefault();

            Assert.True(TestStageManager.AddUpdateTaskAssignment(batch.QRANumber, 0, ConfigurationManager.AppSettings["userName"].ToString()));
            Assert.True(TestStageManager.RemoveTaskAssignment(batch.QRANumber, 0));
        }

        [Test]
        public void SaveTestStage()
        {
            var stage = new REMI.Entities.TestStage();
            stage = (from s in instance.TestStages.Include("Job") orderby s.ID descending select s).FirstOrDefault();
            TestStage ts = TestStageManager.GetTestStage(stage.TestStageName, stage.Job.JobName);

            Assert.That(TestStageManager.SaveTestStage(ts) > 0);
        }
    }
}
