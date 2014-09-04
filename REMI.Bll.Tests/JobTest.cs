﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using REMI.Bll;
using REMI.BusinessEntities;
using REMI.Dal;

namespace REMI.Bll.Tests
{
    [TestFixture]
    public class JobTest : REMIManagerBase
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
        public void GetProductList()
        {
            Assert.That(JobManager.GetJobByName("T101 Internal Use Only").ID > 0);
        }

        [Test]
        public void GetJobNameByID()
        {
            Assert.IsNotEmpty(JobManager.GetJobNameByID((from j in instance.Jobs where j.IsActive != false select j.ID).FirstOrDefault()));
        }

        [Test]
        public void GetJobList()
        {
            Assert.That(JobManager.GetJobList().Count > 0);
        }

        [Test]
        public void GetJobListForTestStations()
        {
            Assert.That(JobManager.GetJobListForTestStations().Count > 0);
        }

        [Test]
        public void GetJobListDT()
        {
            Assert.That(JobManager.GetJobListDT().Count > 0);
        }
    }
}
