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
    public class UserTest : REMIManagerBase
    {
        REMI.Entities.Entities instance;
        FakeHttpContext fcontext;

        [SetUp]
        public void SetUp()
        {
            instance = new REMI.Dal.Entities().Instance;
            fcontext = new FakeHttpContext();
        }

        [TearDown]
        public void TearDown()
        {
            instance = null;
        }

        [Test]
        public void GetTraining()
        {
            var ut = new REMI.Entities.UserTraining();
            ut = (from t in instance.UserTrainings.Include("User") orderby t.ID descending select t).FirstOrDefault();

            Assert.That(UserManager.GetTraining(ut.User.ID, 1).Rows.Count > 0);
        }

        [Test]
        public void GetSimiliarTraining()
        {
            var ut = new REMI.Entities.UserTraining();
            ut = (from t in instance.UserTrainings.Include("User").Include("Lookup") orderby t.ID descending select t).FirstOrDefault();

            Assert.IsNotNull(UserManager.GetSimiliarTraining(ut.Lookup.LookupID));
        }

        [Test]
        public void Save()
        {
            var ut = new REMI.Entities.UserTraining();
            ut = (from t in instance.UserTrainings.Include("User").Include("Lookup") orderby t.ID descending select t).FirstOrDefault();

            User u = UserManager.GetUser(ut.User.LDAPLogin, ut.User.ID);

            Assert.That(UserManager.Save(u, true, true, true) > 0);
        }

        [Test]
        public void UserExists()
        {
            var ut = new REMI.Entities.UserTraining();
            ut = (from t in instance.UserTrainings.Include("User").Include("Lookup") orderby t.ID descending select t).FirstOrDefault();

            Assert.True(UserManager.UserExists(ut.User.LDAPLogin));
        }

        //[Test]
        //public void GetRemiUsernameList()
        //{
        //    Assert.That(UserManager.GetRemiUsernameList(1).Count > 0);
        //}

        [Test]
        public void GetRoles()
        {
            Assert.That(UserManager.GetRoles().Count > 0);
        }

        [Test]
        public void SessionUserIsSet()
        {
            fcontext.Current.Session.Add("CurrentUser", UserManager.GetCurrentUser());
            Assert.True(UserManager.SessionUserIsSet());
        }

        [Test]
        public void SetUserToSession()
        {
            var ut = new REMI.Entities.UserTraining();
            ut = (from t in instance.UserTrainings.Include("User").Include("Lookup") orderby t.ID descending select t).FirstOrDefault();

            User u = UserManager.GetUser(ut.User.LDAPLogin, ut.User.ID);

            Assert.True(UserManager.SetUserToSession(ut.User.LDAPLogin));
            Assert.True(UserManager.SetUserToSession(u));
        }

        [Test]
        public void GetCurrentUser()
        {
            Assert.IsNotNull(UserManager.GetCurrentUser());
        }

        [Test]
        public void GetUser()
        {
            var ut = new REMI.Entities.UserTraining();
            ut = (from t in instance.UserTrainings.Include("User").Include("Lookup") orderby t.ID descending select t).FirstOrDefault();

            Assert.IsNotNull(UserManager.GetUser(ut.User.LDAPLogin, ut.User.ID));
        }

        [Test]
        public void GetCurrentValidUserLDAPName()
        {
            Assert.IsNotEmpty(UserManager.GetCurrentValidUserLDAPName());
        }

        [Test]
        public void GetCurrentValidUserID()
        {
            Assert.That(UserManager.GetCurrentValidUserID() > 0);
        }

        [Test]
        public void GetCleanedHttpContextCurrentUserName()
        {
            Assert.That(UserManager.GetCleanedHttpContextCurrentUserName() != "User Not Set");
        }
    }
}