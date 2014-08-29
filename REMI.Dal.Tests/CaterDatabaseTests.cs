using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
namespace REMI.Dal.Tests
{
    [TestFixture]
  public  class CaterDatabaseTests
    {
        [Test]
        public void GetTRSRequestData() { 
            REMI.Contracts.IQRARequest req = RequestDB.GetTRSRequest("QRA-10-1111");
            
        }
    }
}
