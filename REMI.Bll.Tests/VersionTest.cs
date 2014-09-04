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
    [TestFixture]
    public class VersionTest : REMIManagerBase
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
        public void GetProductConfigXMLByAppVersion()
        {
        }

        [Test]
        public void CheckVersion()
        {
            var v = new REMI.Entities.Application();
            v = (from a in instance.Applications.Include("ApplicationVersions") select a).FirstOrDefault();
            String verNum = v.ApplicationVersions.ElementAt(0).VerNum;

            if (v.ApplicationVersions.Count == 1)
            {
                Assert.That(VersionManager.CheckVersion(v.ApplicationName, verNum) == 0);
            }
            else
            {
                Assert.That(VersionManager.CheckVersion(v.ApplicationName, verNum) == 1);
                Assert.That(VersionManager.CheckVersion(v.ApplicationName, v.ApplicationVersions.ElementAt(v.ApplicationVersions.Count-1).VerNum) == 0);
            }
        }

        [Test]
        public void remispVersionProductLink()
        {
            var v = new REMI.Entities.Application();
            v = (from a in instance.Applications.Include("ApplicationVersions") select a).FirstOrDefault();

            if (v.ApplicationVersions.ElementAt(0).ApplicationProductVersions.Count > 0)
            {
                Assert.That(VersionManager.remispVersionProductLink(v.ApplicationName, v.ApplicationVersions.ElementAt(0).ApplicationProductVersions.ElementAt(0).ProductConfigurationVersion.ProductConfigurationUpload.ID).Rows.Count > 0);
            }
        }
    }
}
