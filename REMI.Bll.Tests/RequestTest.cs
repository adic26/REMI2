using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using REMI.Bll;
using REMI.BusinessEntities;
using REMI.Dal;
using REMI.Contracts;

namespace REMI.Bll.Tests
{
    [TestFixture]
    public class RequestTest : REMIManagerBase
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
        public void GetRequestSetupInfo()
        {
            Assert.That(RequestManager.GetRequestSetupInfo(0, 188, 0, (int)TestStageType.Parametric, 0).Rows.Count > 0);
        }
    }
}
