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
    public class TargetAccessTest : REMIManagerBase
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
        public void GetAllAccessByWorkstation()
        {
            var ta = new REMI.Entities.TargetAccess();
            ta = (from t in instance.TargetAccesses where t.WorkstationName != null orderby t.ID descending select t).FirstOrDefault();

            Assert.IsNotNull(TargetAccessManager.GetAllAccessByWorkstation(ta.WorkstationName, false));
            Assert.That(TargetAccessManager.GetAllAccessByWorkstation("", false).Count == 0);
        }

        [Test]
        public void HasAccess()
        {
            var ta = new REMI.Entities.TargetAccess();
            ta = (from t in instance.TargetAccesses where t.WorkstationName != null && t.DenyAccess == false orderby t.ID descending select t).FirstOrDefault();

            Assert.True(TargetAccessManager.HasAccess(ta.TargetName, ta.WorkstationName));

            ta = (from t in instance.TargetAccesses where t.WorkstationName != null && t.DenyAccess == true orderby t.ID descending select t).FirstOrDefault();
            
            Assert.False(TargetAccessManager.HasAccess(ta.TargetName, ta.WorkstationName));
        }

        [Test]
        public void AddRemoveTargetAccess()
        {
            Assert.True(TargetAccessManager.AddTargetAccess("Test", String.Empty, false));
            
            var ta = new REMI.Entities.TargetAccess();
            ta = (from t in instance.TargetAccesses where t.TargetName == "Test" orderby t.ID descending select t).FirstOrDefault();
            Assert.True(TargetAccessManager.DeleteTargetAccess(ta.ID));
        }
    }
}
