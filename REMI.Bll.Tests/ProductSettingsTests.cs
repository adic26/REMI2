using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using REMI.Bll;
namespace REMI.Bll.Tests
{
    [TestFixture]
    public class ProductSettingsTests
    {
        //string sampleProduct2 = "product2";
        //string sampleProduct1 = "product1";
        Int32 sampleProduct1 = 1;
        //string sampleUser = "doriordan";
        string sampleKey1 = "keyval1";
        string sampleValue1 = "val1";
        string sampleDefaultValue1 = "defaultValue1";
        string sampleKey2 = "keyval2";
        string sampleValue2 = "val2";
        string sampleDefaultValue2 = "defaultValue2";

        [Test]
        public void GetADictionaryList()
        {
            //make sure the product is 'empty'
            var vals = ProductGroupManager.GetProductSettingsDictionary(sampleProduct1);
            Assert.That(vals.Count == 0);
            //add the keys
            bool keySaved = ProductGroupManager.SaveSetting(sampleProduct1, sampleKey1, sampleValue1, sampleDefaultValue1);
            Assert.True(keySaved, "Could not save the key");
            keySaved = ProductGroupManager.SaveSetting(sampleProduct1, sampleKey2, sampleValue2, sampleDefaultValue2);
            Assert.True(keySaved, "Could not save the key");
            //check we can retrieve them
            vals = ProductGroupManager.GetProductSettingsDictionary(sampleProduct1);
            Assert.That(vals.Count == 2);
            Assert.That(vals[sampleKey1] == sampleValue1);
            Assert.That(vals[sampleKey2] == sampleValue2);


        }
    }
}
