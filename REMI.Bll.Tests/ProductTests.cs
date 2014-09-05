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
        public void GetProductList()
        {
            Assert.That(ProductGroupManager.GetProductList(true, -1, false).Rows.Count > 0);
        }

        [Test]
        public void GetProductTestReady()
        {
            Assert.That(ProductGroupManager.GetProductTestReady(526, "M3").Rows.Count > 0);
        }

        [Test]
        public void GetProductOracleList()
        {
            Assert.That(ProductGroupManager.GetProductOracleList().Count> 0);
        }

        [Test]
        public void GetProductNameByID()
        {
            Assert.IsNotEmpty(ProductGroupManager.GetProductNameByID( (from p in instance.Products select p.ID).FirstOrDefault()));
        }

        [Test]
        public void GetProductIDByName()
        {
            Assert.That(ProductGroupManager.GetProductIDByName((from p in instance.Products orderby p.ID descending select p.ProductGroupName).FirstOrDefault()) > 0);
        }

        [Test]
        public void GetProductSetting()
        {
            Assert.IsNotEmpty(ProductGroupManager.GetProductSetting(526, "M2"));
        }

        [Test]
        public void GetProductSettingsDictionary()
        {
            Assert.That(ProductGroupManager.GetProductSettingsDictionary((from p in instance.Products orderby p.ID descending select p.ID).FirstOrDefault()).Count > 0);
            Assert.That(ProductGroupManager.GetProductSettings((from p in instance.Products orderby p.ID descending select p.ID).FirstOrDefault()).Count > 0);
        }

        [Test]
        public void HasProductConfigurationXML()
        {
            var pc = new REMI.Entities.ProductConfigurationUpload();
            pc = (from c in instance.ProductConfigurationUploads.Include("Product").Include("Test") orderby c.ID descending select c).FirstOrDefault();

            Assert.True(ProductGroupManager.HasProductConfigurationXML(pc.Product.ID, pc.Test.ID, pc.PCName));
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

            Assert.IsNotEmpty(ProductGroupManager.GetProductConfigurationXMLCombined(pc.Product.ID, pc.Test.ID).ToString());
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
            var pc = new REMI.Entities.ProductConfigurationUpload();
            pc = (from c in instance.ProductConfigurationUploads.Include("Product").Include("Test") orderby c.ID descending select c).FirstOrDefault();

            Assert.That(ProductGroupManager.GetSimilarTestConfigurations(pc.Product.ID, pc.Test.ID).Rows.Count > 0);
        }

        [Test]
        public void GetProductContacts()
        {
            Assert.That(ProductGroupManager.GetProductContacts(526).Rows.Count > 0);
        }

        [Test]
        public void UpdateProduct()
        {
            var product = new REMI.Entities.Product();
            product = (from p in instance.Products orderby p.ID descending select p).FirstOrDefault();

            Assert.True(ProductGroupManager.UpdateProduct(product.ProductGroupName, (product.IsActive ? 1 : 0), product.ID, product.QAPLocation, product.TSDContact));
        }

        [Test]
        public void SaveDeleteSetting()
        {
            var product = new REMI.Entities.Product();
            product = (from p in instance.Products orderby p.ID descending select p).FirstOrDefault();

            Assert.True(ProductGroupManager.SaveSetting(product.ID, "ProductTest", "test", "test"));
            Assert.True(ProductGroupManager.DeleteSetting(product.ID, "ProductTest"));
            
            Assert.True(ProductGroupManager.CreateSetting(product.ID, "ProductTest", "test", "test"));
            Assert.True(ProductGroupManager.DeleteSetting(product.ID, "ProductTest"));
        }
    }
}
