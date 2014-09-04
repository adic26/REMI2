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
    [TestFixture]
    public class SecurityTest : REMIManagerBase
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
        public void GetRolesPermissionsGrid()
        {
            Assert.That(SecurityManager.GetRolesPermissionsGrid().Rows.Count > 0);
        }

        [Test]
        public void AddRemoveRolePermission()
        {
            Assert.True(SecurityManager.AddNewRole("Test"));
            Assert.True(SecurityManager.AddRemovePermission("HasDocumentAuthority", "Test"));
            Assert.True(SecurityManager.AddRemovePermission("HasDocumentAuthority", "Test"));
            Assert.True(SecurityManager.RemoveRole("Test"));
        }
    }
}
