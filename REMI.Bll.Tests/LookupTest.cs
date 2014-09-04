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
            Assert.That(LookupsManager.GetLookups(Contracts.LookupType.Priority, 0, 0, 0).Rows.Count > 0);
        }

        [Test]
        public void GetLookupID()
        {
            Assert.That(LookupsManager.GetLookupID(Contracts.LookupType.Priority, "low") > 0);
        }

        [Test]
        public void GetOracleProductTypeList()
        {
            Assert.That(LookupsManager.GetOracleProductTypeList().Count > 0);
        }

        [Test]
        public void GetOracleAccessoryGroupList()
        {
            Assert.That(LookupsManager.GetOracleAccessoryGroupList().Count > 0);
        }

        [Test]
        public void GetOracleTestCentersList()
        {
            Assert.That(LookupsManager.GetOracleTestCentersList().Count > 0);
        }
    }
}
