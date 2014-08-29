using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using REMI.Dal;
namespace REMI.Dal.Tests
{
    [TestFixture]
    public class ProductSettingsTests
    {
        //string sampleProduct2 = "product2";
        Int32 sampleProduct2 = 1;
        Int32 sampleProduct1 = 2;
        string sampleUser = "doriordan";
        string sampleKey1 = "keyval1";
        string sampleValue1 = "val1";
        string sampleDefaultValue1 = "defaultValue1";
        string sampleKey2 = "keyval2";
        string sampleValue2 = "val2";
        string sampleDefaultValue2 = "defaultValue2";
        [Test]
        public void InsertSettingTest()
        { 
            //make sure the key isn't already there
            string returnedValue = ProductGroupDB.GetProductSetting(sampleProduct1, sampleKey1);
            Assert.That(returnedValue == null);
            //add the key
           bool keySaved =  ProductGroupDB.SaveProductSetting(sampleProduct1, sampleKey1, sampleValue1, sampleDefaultValue1,sampleUser);
           Assert.True(keySaved, "Could not save the key");
            //check we can retrieve it
           returnedValue = ProductGroupDB.GetProductSetting(sampleProduct1, sampleKey1);
           Assert.That(returnedValue == sampleValue1);
            //check that we can update it
           string updatedValue1 = "updatedValue1";
           keySaved = ProductGroupDB.SaveProductSetting(sampleProduct1, sampleKey1, updatedValue1,sampleDefaultValue1, sampleUser);
           Assert.True(keySaved, "Could not save the key");
            //reget
           returnedValue = ProductGroupDB.GetProductSetting(sampleProduct1, sampleKey1);
           Assert.That(returnedValue == updatedValue1);

            //check that we can delete it
           bool isDeleted = ProductGroupDB.DeleteProductSetting(sampleProduct1, sampleKey1, sampleUser);
           Assert.That(isDeleted);
            //confirm it is gone.
           returnedValue = ProductGroupDB.GetProductSetting(sampleProduct1, sampleKey1);
           Assert.That(returnedValue == null);

        }
        /// <summary>
        /// This tests that keys set for a different product are still included in the result set for a query where that particular key
        /// is not set.
        /// </summary>
        [Test]
        public void GetSettingsListReturnsAllKeysCorrectly()
        {
            //add 3 keys, 2 for one product and one for another product
           ProductGroupDB.SaveProductSetting(sampleProduct1, sampleKey1, sampleValue1,sampleDefaultValue1, sampleUser);
           ProductGroupDB.SaveProductSetting(sampleProduct1, sampleKey2, sampleValue2, sampleDefaultValue2, sampleUser);
           ProductGroupDB.SaveProductSetting(sampleProduct2, sampleKey1, sampleValue1, sampleDefaultValue1, sampleUser);
         
            //check that when we retrieve the list of keys for the second product it includes an empty
            //key for the missing key

           var ps = ProductGroupDB.GetProductSettings(sampleProduct2);
           Assert.That(ps.Count == 2);
           Assert.That((from p in ps where p.KeyName.Equals(sampleKey1) select p).Count() ==1);
           Assert.That((from p in ps where p.KeyName.Equals(sampleKey1) select p.ValueText).FirstOrDefault() == sampleValue1);
            //important to check that we got the default value back where there was no value entered.
           Assert.That((from p in ps where p.KeyName.Equals(sampleKey2) select p.ValueText).FirstOrDefault() == sampleDefaultValue2);
        

        }

        [Test]
        public void GetAFullList()
        {
            //make sure the product is 'empty'
           var vals =  ProductGroupDB.GetProductSettings(sampleProduct1);
            Assert.That(vals.Count == 0);
            //add the keys
            bool keySaved = ProductGroupDB.SaveProductSetting(sampleProduct1, sampleKey1, sampleValue1,sampleDefaultValue1, sampleUser);
            Assert.True(keySaved, "Could not save the key");
            keySaved = ProductGroupDB.SaveProductSetting(sampleProduct1, sampleKey2, sampleValue2, sampleDefaultValue2, sampleUser);
            Assert.True(keySaved, "Could not save the key");
            //check we can retrieve them
            vals = ProductGroupDB.GetProductSettings(sampleProduct1);
            Assert.That(vals.Count == 2);
            Assert.That((from p in vals where p.KeyName.Equals(sampleKey1) select p.ValueText).FirstOrDefault() == sampleValue1);
            Assert.That((from p in vals where p.KeyName.Equals(sampleKey2) select p.ValueText).FirstOrDefault() == sampleValue2);

        }

        
        [TearDown]
        public void Teardown()
        {
            //delete any remaining keys
            var vals = ProductGroupDB.GetProductSettings(sampleProduct1);
            foreach (var k in vals)
            {
                ProductGroupDB.DeleteProductSetting(sampleProduct1, k.KeyName, sampleUser);            
            }
            //and for the second product also
            vals = ProductGroupDB.GetProductSettings(sampleProduct2);
            foreach (var k in vals)
            {
                ProductGroupDB.DeleteProductSetting(sampleProduct2, k.KeyName, sampleUser);
            }
        }
    }
}
