using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using REMI.Bll;
using REMI.BusinessEntities;
using REMI.Dal;

namespace REMI.Bll.Tests
{
    public class LookupTest : REMIManagerBase
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
        public void GetLookups()
        {
            Assert.That(LookupsManager.GetLookups("Priority", 0, 0, String.Empty, String.Empty, 0, false, 0,false).Rows.Count > 0);
        }

        [Test]
        public void GetLookupsTypeString()
        {
            Assert.That(LookupsManager.GetLookups("Priority", 0, 0, String.Empty, String.Empty, 0, false, 0,false).Rows.Count > 0);
        }

        [Test]
        public void GetLookupID()
        {
            Assert.That(LookupsManager.GetLookupID("Priority", "low", 0) > 0);
        }

        [Test]
        public void GetLookupIDByTypeString()
        {
            Assert.That(LookupsManager.GetLookupID("Priority", "low", 0) > 0);
        }

        //[Test]
        //public void GetOracleProductTypeList()
        //{
        //    Assert.That(LookupsManager.GetOracleProductTypeList().Count > 0);
        //}

        //[Test]
        //public void GetOracleDepartmentList()
        //{
        //    Assert.That(LookupsManager.GetOracleDepartmentList().Count > 0);
        //}

        //[Test]
        //public void GetOracleAccessoryGroupList()
        //{
        //    Assert.That(LookupsManager.GetOracleAccessoryGroupList().Count > 0);
        //}

        //[Test]
        //public void GetOracleTestCentersList()
        //{
        //    Assert.That(LookupsManager.GetOracleTestCentersList().Count > 0);
        //}

        [Test]
        public void SaveLookup()
        {
            var e = new REMI.Entities.Lookup();
            e = (from l in instance.Lookups where l.IsActive == 1 orderby l.LookupID descending select l).FirstOrDefault();

            Assert.True(LookupsManager.SaveLookup(e.LookupType.Name, e.Values, e.IsActive, e.Description, (e.ParentID == null ? 0 : (int)e.ParentID)));
        }
    }
}
