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
    public class ProductTests : REMIManagerBase
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
        public void GetProductTestReady()
        {
            var product = new REMI.Entities.Lookup();
            product = (from p in instance.Lookups where p.LookupID == 6588 orderby p.LookupID descending select p).FirstOrDefault();
            Assert.That(ProductGroupManager.GetProductTestReady(product.LookupID, "M3").Rows.Count > 0);
        }

        [Test]
        public void GetProductSetting()
        {
            Assert.IsNotEmpty(ProductGroupManager.GetProductSetting(526, "M2"));
        }

        [Test]
        public void HasProductConfigurationXML()
        {
            var pc = new REMI.Entities.ProductConfigurationUpload();
            pc = (from c in instance.ProductConfigurationUploads.Include("Product").Include("Test") orderby c.ID descending select c).FirstOrDefault();

            Assert.True(ProductGroupManager.HasProductConfigurationXML(pc.LookupID, pc.Test.ID, pc.PCName));
        }

        [Test]
        public void GetProductConfigurationXMLVersion()
        {
            var pc = new REMI.Entities.ProductConfigurationUpload();
            pc = (from c in instance.ProductConfigurationUploads.Include("ProductConfigurationVersions") orderby c.ID descending select c).FirstOrDefault();

            Assert.IsNotEmpty(ProductGroupManager.GetProductConfigurationXMLVersion(pc.ProductConfigurationVersions.ElementAt(0).ID).ToString());
        }

        [Test]
        public void GetProductConfigurationXML()
        {
            var pc = new REMI.Entities.ProductConfigurationUpload();
            pc = (from c in instance.ProductConfigurationUploads orderby c.ID descending select c).FirstOrDefault();

            Assert.IsNotEmpty(ProductGroupManager.GetProductConfigurationXML(pc.ID).ToString());
        }

        [Test]
        public void GetProductConfigurationXMLCombined()
        {
            var pc = new REMI.Entities.ProductConfigurationUpload();
            pc = (from c in instance.ProductConfigurationUploads.Include("Product").Include("Test") orderby c.ID descending select c).FirstOrDefault();

            Assert.IsNotEmpty(ProductGroupManager.GetProductConfigurationXMLCombined(pc.LookupID, pc.Test.ID).ToString());
        }

        [Test]
        public void GetProductConfigurationHeader()
        {
            var pc = new REMI.Entities.ProductConfigurationUpload();
            pc = (from c in instance.ProductConfigurationUploads orderby c.ID descending select c).FirstOrDefault();

            Assert.That(ProductGroupManager.GetProductConfigurationHeader(pc.ID).Rows.Count > 0);
        }

        [Test]
        public void GetProductConfigurationDetails()
        {
            var pc = new REMI.Entities.ProductConfiguration();
            pc = (from c in instance.ProductConfigurations orderby c.ID descending select c).FirstOrDefault();

            Assert.That(ProductGroupManager.GetProductConfigurationDetails(pc.ID).Rows.Count > 0);
        }

        [Test]
        public void GetSimilarTestConfigurations()
        {
            var pc = (from c in instance.ProductConfigurationUploads.Include("Product").Include("Test") group c by new { TestID = c.Test.ID } into grp where grp.Count() > 1 select new { grp.Key.TestID}).FirstOrDefault();

            Assert.That(ProductGroupManager.GetSimilarTestConfigurations(0, pc.TestID).Rows.Count > 0);
        }

        [Test]
        public void GetProductContacts()
        {
            Assert.That(ProductGroupManager.GetProductContacts(526).Rows.Count > 0);
        }

        [Test]
        public void SaveDeleteSetting()
        {
            var product = new REMI.Entities.Lookup();
            product = (from p in instance.Lookups orderby p.LookupID descending select p).FirstOrDefault();

            Assert.True(ProductGroupManager.SaveSetting(product.LookupID, "ProductTest", "test", "test"));
            Assert.True(ProductGroupManager.DeleteSetting(product.LookupID, "ProductTest"));

            Assert.True(ProductGroupManager.CreateSetting(product.LookupID, "ProductTest", "test", "test"));
            Assert.True(ProductGroupManager.DeleteSetting(product.LookupID, "ProductTest"));
        }
    }
}
