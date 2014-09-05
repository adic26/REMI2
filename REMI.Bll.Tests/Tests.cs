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
    public class Tests : REMIManagerBase
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
            var test = new REMI.Entities.Test();
            test = (from t in instance.Tests orderby t.ID descending select t).FirstOrDefault();

            Assert.IsNotNull(TestManager.GetTest(test.ID));
            Assert.IsNull(TestManager.GetTest(0));
        }

        [Test]
        public void GetTestByName()
        {
            var test = new REMI.Entities.Test();
            test = (from t in instance.Tests orderby t.ID descending select t).FirstOrDefault();

            Assert.IsNotNull(TestManager.GetTestByName(test.TestName, true));
            Assert.IsNull(TestManager.GetTestByName(String.Empty, true));
        }

        [Test]
        public void GetEditableTests()
        {
            Assert.IsNotNull(TestManager.GetEditableTests(false, TestType.Parametric.ToString()));
        }

        [Test]
        public void GetTestsByType()
        {
            Assert.That(TestManager.GetTestsByType(TestType.Parametric, false).Count > 0);
        }

        [Test]
        public void GetTestsByBatchStage()
        {
            var batch = new REMI.Entities.Batch();
            batch = (from b in instance.Batches where b.TestStageName == "Baseline" && b.BatchStatus == 2 orderby b.ID descending select b).FirstOrDefault();

            Assert.IsNotNull(TestManager.GetTestsByBatchStage(batch.ID, batch.TestStageName, false));
        }

        [Test]
        public void SaveTestAndTypes()
        {
            var test = new REMI.Entities.Test();
            test = (from t in instance.Tests where t.TestType==1 orderby t.ID descending select t).FirstOrDefault();

            Test tests = TestManager.GetTest(test.ID);

            Assert.That(TestManager.SaveTest(tests) > 0);

            Assert.IsNotNull(TestManager.SaveApplicableTLTypes(tests.TrackingLocationTypes, tests.ID));
        }
    }
}
