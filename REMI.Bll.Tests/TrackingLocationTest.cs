﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using REMI.BusinessEntities;
using REMI.Contracts;
using REMI.Dal;

namespace REMI.Bll.Tests
{
    [TestFixture]
    public class TrackingLocationTest : REMIManagerBase
    {
        String username = "ogaudreault";
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
        public void GetUserPermissionList()
        {
            try
            {
                TrackingLocationManager.GetUserPermissionList(username);
            }
            catch (Exception ex)
            {
                Assert.Fail("Expected no exception, but got: " + ex.Message);
            }
        }

        [Test]
        public void GetLocationsWithoutHost()
        {
            Assert.That(TrackingLocationManager.GetLocationsWithoutHost(0, 1).Count > 0);
        }

        [Test]
        public void GetTrackingLocationID()
        {
            var tln = new REMI.Entities.TrackingLocation();
            tln = (from tl in instance.TrackingLocations.Include("Lookup") where tl.Decommissioned != true select tl).FirstOrDefault();
            
            Assert.That(TrackingLocationManager.GetTrackingLocationID(tln.TrackingLocationName, tln.Lookup.LookupID) > 0);
        }

        [Test]
        public void GetHostID()
        {
            var tln = new REMI.Entities.TrackingLocation();
            tln = (from tl in instance.TrackingLocations.Include("TrackingLocationsHosts") where tl.Decommissioned != true select tl).FirstOrDefault();

            Assert.That(TrackingLocationManager.GetHostID(tln.TrackingLocationsHosts.ElementAt(0).HostName, tln.ID) > 0);
        }

        [Test]
        public void CheckStatus()
        {
            var tln = new REMI.Entities.TrackingLocation();
            tln = (from tl in instance.TrackingLocations.Include("TrackingLocationsHosts") where tl.Decommissioned != true select tl).FirstOrDefault();

            Assert.NotNull(TrackingLocationManager.CheckStatus(tln.TrackingLocationsHosts.ElementAt(0).HostName));
        }

        [Test]
        public void GetTrackingLocationHostsByID()
        {
            var tln = new REMI.Entities.TrackingLocation();
            tln = (from tl in instance.TrackingLocations.Include("TrackingLocationsHosts") where tl.Decommissioned != true select tl).FirstOrDefault();

            try
            {
                TrackingLocationManager.GetTrackingLocationHostsByID(tln.TrackingLocationsHosts.ElementAt(0).ID);
            }
            catch (Exception ex)
            {
                Assert.Fail("Expected no exception, but got: " + ex.Message);
            }
        }

        [Test]
        public void GetSpecificLocationForCurrentUsersTestCenter()
        {
            var tln = new REMI.Entities.TrackingLocation();
            tln = (from tl in instance.TrackingLocations.Include("TrackingLocationsHosts") where tl.Decommissioned != true select tl).FirstOrDefault();
            Assert.That(TrackingLocationManager.GetSpecificLocationForCurrentUsersTestCenter(tln.TrackingLocationName, username) > 0);
        }

        [Test]
        public void GetTrackingLocationByID()
        {
            var tln = new REMI.Entities.TrackingLocation();
            tln = (from tl in instance.TrackingLocations.Include("TrackingLocationsHosts") where tl.Decommissioned != true select tl).FirstOrDefault();

            try
            {
                TrackingLocationManager.GetTrackingLocationByID(tln.ID);
            }
            catch (Exception ex)
            {
                Assert.Fail("Expected no exception, but got: " + ex.Message);
            }
        }

        [Test]
        public void GetTrackingLocationsByHostName()
        {
            var tln = new REMI.Entities.TrackingLocation();
            tln = (from tl in instance.TrackingLocations.Include("TrackingLocationsHosts").Include("TrackingLocationType") where tl.Decommissioned != true select tl).FirstOrDefault();

           Assert.That( TrackingLocationManager.GetTrackingLocationsByHostName(tln.TrackingLocationsHosts.ElementAt(0).HostName, tln.TrackingLocationType.TrackingLocationTypeName, 1, 0).Count > 0);
        }

        [Test]
        public void GetTrackingLocationsByHostNameAtTestCenter()
        {
            var tln = new REMI.Entities.TrackingLocation();
            tln = (from tl in instance.TrackingLocations.Include("Lookup").Include("TrackingLocationsHosts") where tl.Decommissioned != true select tl).FirstOrDefault();

            Assert.That(TrackingLocationManager.GetTrackingLocationsByHostNameAtTestCenter(tln.TrackingLocationsHosts.ElementAt(0).HostName, tln.Lookup.LookupID).Count > 0);
        }

        [Test]
        public void GetMultipleTrackingLocationByHostNameAndType()
        {
            var tln = new REMI.Entities.TrackingLocation();
            tln = (from tl in instance.TrackingLocations.Include("TrackingLocationsHosts").Include("TrackingLocationType") where tl.Decommissioned != true select tl).FirstOrDefault();

            Assert.That(TrackingLocationManager.GetMultipleTrackingLocationByHostNameAndType(tln.TrackingLocationsHosts.ElementAt(0).HostName, tln.TrackingLocationType.TrackingLocationTypeName).Count > 0);
        }

        [Test]
        public void GetMultipleTrackingLocationByHostName()
        {
            var tln = new REMI.Entities.TrackingLocation();
            tln = (from tl in instance.TrackingLocations.Include("TrackingLocationsHosts") where tl.Decommissioned != true select tl).FirstOrDefault();


            Assert.That(TrackingLocationManager.GetMultipleTrackingLocationByHostName(tln.TrackingLocationsHosts.ElementAt(0).HostName).Count > 0);
        }

        [Test]
        public void GetSingleTrackingLocationByHostName()
        {
            var tln = new REMI.Entities.TrackingLocation();
            tln = (from tl in instance.TrackingLocations.Include("TrackingLocationsHosts") where tl.Decommissioned != true select tl).FirstOrDefault();

            Assert.That(TrackingLocationManager.GetSingleTrackingLocationByHostName(tln.TrackingLocationsHosts.ElementAt(0).HostName).ID > 0);
        }

        [Test]
        public void GetSingleItem()
        {
            var tln = new REMI.Entities.TrackingLocation();
            tln = (from tl in instance.TrackingLocations.Include("TrackingLocationsHosts") where tl.Decommissioned != true select tl).FirstOrDefault();

            TrackingLocationCriteria tlc = new TrackingLocationCriteria();
            tlc.ID = tln.ID;

            Assert.That(TrackingLocationManager.GetSingleItem(tlc).ID > 0);
        }

    }
}
