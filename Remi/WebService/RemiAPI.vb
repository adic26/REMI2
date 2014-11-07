﻿Imports System.Web.Services
Imports System.Web.Services.Protocols
Imports System.ComponentModel
Imports Remi.Validation
Imports Remi.BusinessEntities
Imports Remi.Bll
Imports log4net
Imports Remi.Contracts
Imports System.Data
Imports System.Web.Script.Services

<System.Web.Services.WebService(Name:="RemiAPI", Namespace:="http://go/remi/")> _
<System.Web.Services.WebServiceBinding(ConformsTo:=WsiProfiles.BasicProfile1_1)> _
<ToolboxItem(False)> _
Public Class RemiAPI
    Inherits System.Web.Services.WebService

#Region "Units"
    <WebMethod(EnableSession:=True, Description:="Adds an exception for a specific unit for a test.")> _
    Public Function AddUnitException(ByVal qraNumber As String, ByVal TestName As String, ByVal userIdentification As String) As Notification
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Return ExceptionManager.AddException(Helpers.CleanInputText(qraNumber, 21), TestName, userIdentification)
            End If
        Catch ex As Exception
            TestUnitManager.LogIssue("REMI API Add Exception", "e7", NotificationType.Errors, ex, "User: " + userIdentification + " Request: " + qraNumber + " T Name:" + TestName)
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Sets the BSN for a unit. The given user badge number will override the windows login if available.")> _
    Public Function AddUnit(ByVal QRANumber As String, ByVal BSN As String, ByVal userIdentification As String) As Boolean
        Try
            'this used to add a unit but now all units are created and this only changes the 
            'bsn of the unit if it exists
            Dim BSNConverted As Long
            If String.IsNullOrEmpty(BSN) Then
                BSNConverted = 0
            Else
                Long.TryParse(BSN, BSNConverted)
            End If
            Return TestUnitManager.SetUnitBSN(QRANumber, BSNConverted, userIdentification)
        Catch ex As Exception
            TestUnitManager.LogIssue("REMI API Add Unit", "e8", NotificationType.Errors, ex, "Request: " + QRANumber + " UID: " + userIdentification + " BSN: " + BSN)
        End Try
        Return False
    End Function

    <WebMethod(EnableSession:=True, Description:="Gets all units that are available for scanning.")> _
    Public Function GetAvailableUnits(ByVal QRANumber As String) As List(Of String)
        Try
            Return TestUnitManager.GetAvailableUnits(QRANumber, 0)
        Catch ex As Exception
            TestUnitManager.LogIssue("REMI API GetAvailableUnits", "e8", NotificationType.Errors, ex, "Request: " + QRANumber)
        End Try
        Return New List(Of String)
    End Function

    <WebMethod(EnableSession:=True, Description:="Gets all units that are available for scanning except the unit number you pass in.")> _
    Public Function GetAvailableUnitsExcluded(ByVal QRANumber As String, ByVal excludedUnitNumber As String) As List(Of String)
        Try
            Return TestUnitManager.GetAvailableUnits(QRANumber, excludedUnitNumber)
        Catch ex As Exception
            TestUnitManager.LogIssue("REMI API GetAvailableUnitsExcluded", "e8", NotificationType.Errors, ex, "Request: " + QRANumber)
        End Try
        Return New List(Of String)
    End Function

    <WebMethod(EnableSession:=True, Description:="Gets Unit BSN.")> _
    Public Function GetUnitBSN(ByVal QRANumber As String, ByVal batchUnitNumber As Int32) As Int32
        Try
            Return TestUnitManager.GetUnitBSN(QRANumber, batchUnitNumber)
        Catch ex As Exception
            TestUnitManager.LogIssue("REMI API GetUnitBSN", "e8", NotificationType.Errors, ex, "Request: " + QRANumber)
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Gets # Of Units Assigned To This Batch.")> _
    Public Function GetNumOfUnits(ByVal QRANumber As String) As Int32
        Try
            Dim barcode As New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))

            If (barcode.Validate()) Then
                Return TestUnitManager.GetNumOfUnits(barcode.BatchNumber)
            End If
        Catch ex As Exception
            TestUnitManager.LogIssue("REMI API GetNumOfUnits", "e8", NotificationType.Errors, ex, "Request: " + QRANumber)
        End Try
        Return 0
    End Function

    <WebMethod(EnableSession:=True, Description:="Gets Unit Assigned To.")> _
    Public Function GetUnitAssignedTo(ByVal QRANumber As String, ByVal batchUnitNumber As Int32) As String
        Try
            Return TestUnitManager.GetUnitAssignedTo(QRANumber, batchUnitNumber)
        Catch ex As Exception
            TestUnitManager.LogIssue("REMI API GetUnitAssignedTo", "e8", NotificationType.Errors, ex, String.Format("Request: {0} Unit: {1} " + QRANumber, batchUnitNumber))
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Gets Unit.")> _
    Public Function GetUnit(ByVal QRANumber As String, ByVal batchUnitNumber As Int32) As TestUnit
        Try
            Return TestUnitManager.GetUnit(QRANumber, batchUnitNumber)
        Catch ex As Exception
            TestUnitManager.LogIssue("REMI API GetUnit", "e8", NotificationType.Errors, ex, String.Format("Request: {0} Unit: {1} " + QRANumber, batchUnitNumber))
        End Try
        Return Nothing
    End Function
#End Region

#Region "DTATTA"
    <WebMethod(EnableSession:=True, Description:="Attempts to mark a unit as fail for functional test or SFI Functional in remi for the given set of drops.")> _
    Public Function DTATTAAddRemoveUnit(ByVal qranumber As String, ByVal testStage As String, ByVal test As String, ByVal userIdentification As String, ByVal result As Remi.BusinessEntities.FinalTestResult) As Boolean
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Return TestRecordManager.DTATTAUpdateUnitTestStatus(qranumber, testStage, test, userIdentification, result)
            End If
        Catch ex As Exception
            TestRecordManager.LogIssue("Could not remove the given unit from test.", "e3", NotificationType.Errors, ex, " user: " + UserManager.GetCurrentValidUserLDAPName() + " test stage: " + testStage + " Request: " + qranumber)
        End Try
        Return False
    End Function
#End Region

#Region "Station/Hosts"
    <Obsolete("Don't use this routine any more. Use ReturnMultipleStationNames instead."), _
    WebMethod(Description:="Returns the test station this computer represents.")> _
    Public Function ResolveStationName(ByVal computerName As String) As String
        Try
            Dim t As TrackingLocation = TrackingLocationManager.GetSingleTrackingLocationByHostName(computerName)
            If t IsNot Nothing Then
                Return t.Name
            End If
        Catch ex As Exception
            TrackingLocationManager.LogIssue("REMI API ResolveStationName", "e3", NotificationType.Errors, ex, "computer Name: " + computerName)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns the hostID for the station name.")> _
    Public Function GetHostID(ByVal computerName As String, ByVal trackingLocationID As Int32) As Int32
        Try
            Return TrackingLocationManager.GetHostID(computerName, trackingLocationID)
        Catch ex As Exception
            TrackingLocationManager.LogIssue("REMI API GetHostID", "e3", NotificationType.Errors, ex, "computer Name: " + computerName)
        End Try
        Return 0
    End Function

    <WebMethod(Description:="Returns the tracking location ID for your test center. Use GetLookupID to get TestCenterID value.")> _
    Public Function GetTrackingLocationID(ByVal trackingLocationName As String, ByVal testCenterID As Int32) As Int32
        Try
            Return TrackingLocationManager.GetTrackingLocationID(trackingLocationName, testCenterID)
        Catch ex As Exception
            TrackingLocationManager.LogIssue("REMI API GetTrackingLocationID", "e3", NotificationType.Errors, ex, "computer Name: " + trackingLocationName)
        End Try
        Return 0
    End Function

    <WebMethod(Description:="Returns a set of test station(s) this computer represents.")> _
    Public Function ReturnMultipleStationNames(ByVal computerName As String) As List(Of String)
        Try
            Dim tlCol As TrackingLocationCollection = TrackingLocationManager.GetMultipleTrackingLocationByHostName(computerName)
            Dim lst As List(Of String) = New List(Of String)
            If tlCol IsNot Nothing Then
                For Each rw As TrackingLocation In tlCol
                    lst.Add(rw.Name)
                Next

                Return lst
            End If
        Catch ex As Exception
            TrackingLocationManager.LogIssue("REMI API ReturnMultipleStationNames", "e3", NotificationType.Errors, ex, "computer Name: " + computerName)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a set of test station(s) this computer represents by the type of station.")> _
    Public Function ReturnMultipleStationNamesByType(ByVal computerName As String, ByVal trackingLocationType As String) As TrackingLocationCollection
        Try
            Return TrackingLocationManager.GetMultipleTrackingLocationByHostNameAndType(computerName, trackingLocationType)
        Catch ex As Exception
            TrackingLocationManager.LogIssue("REMI API ReturnMultipleStationNamesByType", "e3", NotificationType.Errors, ex, "computer Name: " + computerName + " trackingLocationType: " + trackingLocationType)
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Returns the specific test station id for a given user, e.g. there are two labs - Lab - Cambridge & Lab - Bochum. If you want a specific location id for a given user use ""Lab"" and their username with this method.")> _
    Public Function GetSpecificLocationForCurrentUsersTestCenter(ByVal stationName As String, ByVal userIdentification As String) As Integer
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Return TrackingLocationManager.GetSpecificLocationForCurrentUsersTestCenter(stationName, UserManager.GetCurrentValidUserLDAPName)
            End If
        Catch ex As Exception
            TrackingLocationManager.LogIssue("Could not location specific location for the given details.", "e3", NotificationType.Errors, ex, "user: " + UserManager.GetCurrentValidUserLDAPName() + "test station: " + stationName)
        End Try
        Return 0
    End Function
#End Region

#Region "Tests"
    <WebMethod(Description:="Given a test name this method returns all the known details of a specific test.")> _
    Public Function GetTest(ByVal Name As String) As Test
        Try
            Return TestManager.GetTestByName(Name, True)
        Catch ex As Exception
            TestManager.LogIssue("REMI API GetTest", "e3", NotificationType.Errors, ex, "Test Name: " + Name)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Given a test name this method returns all the known details of a specific test.")> _
    Public Function GetTestByID(ByVal id As Int32) As Test
        Try
            Return TestManager.GetTest(id)
        Catch ex As Exception
            TestManager.LogIssue("REMI API GetTestByID", "e3", NotificationType.Errors, ex, "Test ID: " + id)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a list of the Parametric Tests available. Represented as a list of strings. This method can be used to populate lists.")> _
    Public Function GetParametricTests() As String()
        Try
            Return TestManager.GetTestsByType(TestType.Parametric, False).ToStringArray
        Catch ex As Exception
            TestManager.LogIssue("REMI API GetParametricTests", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a list of the Tests available for that station.")> _
    Public Function GetTestsByStation(ByVal trackingLocationID As Int32) As String()
        Try
            Return TrackingLocationManager.GetTestsByStation(trackingLocationID)
        Catch ex As Exception
            TrackingLocationManager.LogIssue("REMI API GetTestsByStation", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function
#End Region

#Region "TestStages"
    <WebMethod(Description:="Returns a list of the Parametric type Test Stages available. Does not return environmental stress type test stages. Represented as a list of strings. This method can be used to populate lists.")> _
    Public Function GetTestStages() As String()
        Try
            Return TestStageManager.GetListOfNames.ToArray
        Catch ex As Exception
            TestStageManager.LogIssue("REMI API Get Test Stages", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Given a job name and a test stage name this method returns all the known details for the test stage.")> _
    Public Function GetTestStage(ByVal testStageName As String, ByVal jobName As String) As TestStage
        Try
            Return TestStageManager.GetTestStage(testStageName, jobName)
        Catch ex As Exception
            TestStageManager.LogIssue("REMI API Get Test Stage", "e3", NotificationType.Errors, ex, "TS Name: " + testStageName + " Job Name: " + jobName)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Given a job name this function returns all the known stages of the job.")> _
    Public Function GetJobStages(ByVal jobName As String) As TestStageCollection
        Try
            Return TestStageManager.GetList(TestStageType.NotSet, jobName)
        Catch ex As Exception
            JobManager.LogIssue("REMI API GetJobStages", "e3", NotificationType.Errors, ex, "JobName: " + jobName)
        End Try
        Return Nothing
    End Function
#End Region

#Region "Lookups"
    <WebMethod(Description:="Returns an ID of Lookup based on type.")> _
    Public Function GetLookupIDByTypeString(ByVal type As String, ByVal lookup As String, ByVal parentID As Int32) As Int32
        Try
            Return GetLookupID([Enum].Parse(GetType(REMI.Contracts.LookupType), type), lookup, parentID)
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API GetLookupIDByTypeString", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns an ID of Lookup based on type.")> _
    Public Function GetLookupID(ByVal type As REMI.Contracts.LookupType, ByVal lookup As String, ByVal parentID As Int32) As Int32
        Try
            Return LookupsManager.GetLookupID(type, lookup, parentID)
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API GetLookupID", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a list of Lookups based on type/product.")> _
    Public Function GetLookupsTypeStringByProduct(ByVal type As String, ByVal productID As Int32) As DataTable
        Try
            Return GetLookupsByProduct([Enum].Parse(GetType(Remi.Contracts.LookupType), type), productID)
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API GetLookupsTypeStringByProduct", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a list of Lookups based on type/product.")> _
    Public Function GetLookupsByProduct(ByVal type As Remi.Contracts.LookupType, ByVal productID As Int32) As DataTable
        Try
            Return LookupsManager.GetLookups(type, productID, 0)
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API GetLookupsByProduct", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a list of Lookups based on type/product.")> _
    Public Function GetLookupsByProductParent(ByVal type As Remi.Contracts.LookupType, ByVal productID As Int32, ByVal parentID As Int32) As DataTable
        Try
            Return LookupsManager.GetLookups(type, productID, parentID, 1)
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API GetLookupsByProduct", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a list of Lookups based on type/product.")> _
    Public Function GetLookupsTypeStringByProductParent(ByVal type As String, ByVal productID As Int32, ByVal parentID As Int32) As DataTable
        Try
            Return GetLookupsByProductParent([Enum].Parse(GetType(Remi.Contracts.LookupType), type), productID, parentID)
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API GetLookupsTypeStringByProduct", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a list of Lookups based on type.")> _
    Public Function GetLookupsByTypeString(ByVal type As String) As DataTable
        Try
            Return GetLookups([Enum].Parse(GetType(Remi.Contracts.LookupType), type))
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API GetLookupsByTypeString", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a list of Lookups based on type.")> _
    Public Function GetLookups(ByVal type As Remi.Contracts.LookupType) As DataTable
        Try
            Return LookupsManager.GetLookups(type, 0, 0, 0)
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API GetLookups", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Save A New Lookup.")> _
    Public Function SaveLookup(ByVal lookupType As String, ByVal value As String, ByVal isActive As Int32, ByVal description As String, ByVal parentID As Int32) As Boolean
        Try
            Return LookupsManager.SaveLookup(lookupType, value, isActive, description, parentID)
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API SaveLookup", "e3", NotificationType.Errors, ex)
        End Try
        Return False
    End Function

    <WebMethod(Description:="Returns a full list of the oracle Accessory Types currently being worked on.")> _
    Public Function GetOracleAccessoryTypes() As String()
        Try
            Return LookupsManager.GetOracleAccessoryGroupList.ToArray
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API Get oracle Accessory Types", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a full list of the oracle Test Centers.")> _
    Public Function GetOracleTestCenters() As String()
        Try
            Return LookupsManager.GetOracleTestCentersList.ToArray
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API Get oracle test center", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a full list of the oracle Product Types currently being worked on.")> _
    Public Function GetOracleProductTypes() As String()
        Try
            Return LookupsManager.GetOracleProductTypeList.ToArray
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API Get oracle Product Types", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a full list of the oracle departments.")> _
    Public Function GetOracleDepartmentList() As String()
        Try
            Return LookupsManager.GetOracleDepartmentList.ToArray
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API Get oracle departments", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function
#End Region

#Region "Job"
    <WebMethod(Description:="Returns a list of the Jobs (Test Types) available. Represented as a list of strings. This method can be used to populate lists.")> _
    Public Function GetJobs() As String()
        Try
            Return JobManager.GetJobListForTestStations().ToArray
        Catch ex As Exception
            JobManager.LogIssue("REMI API Get jobs", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Given a job name this function returns all the known details of a job.")> _
    Public Function GetJob(ByVal Name As String) As Job
        Try
            Return JobManager.GetJobByName(Name)
        Catch ex As Exception
            JobManager.LogIssue("REMI API Get job", "e3", NotificationType.Errors, ex, "Name: " + Name)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Given a job name this function returns all orientations for this job.")> _
    Public Function GetOrientationsByJob(ByVal JobName As String) As DataTable
        Try
            Return JobManager.GetJobOrientationLists(0, JobName)
        Catch ex As Exception
            JobManager.LogIssue("REMI API GetOrientationsByJob", "e3", NotificationType.Errors, ex, "JobName: " + JobName)
        End Try

        Return New DataTable("JobOrientation")
    End Function

    <WebMethod(Description:="Get all TRS jobs.")> _
    Public Function GetTRSJobs() As String()
        Try
            Return JobManager.GetJobList().ToArray
        Catch ex As Exception
            JobManager.LogIssue("REMI API GetTRSJobs", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Update Job.")> _
    Public Function SaveJob(ByVal job As Job, ByVal userIdentification As String) As Boolean
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Return JobManager.SaveJob(job)
            End If
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API SaveJob", "e3", NotificationType.Errors, ex)
        End Try
        Return False
    End Function
#End Region

#Region "User"
    <Obsolete("Don't use this routine any more. Use GetUserDetails2 instead."), _
    WebMethod(EnableSession:=True, Description:="Returns the user's login name and their permissions for accessing the test station at the hostname given.", MessageName:="GetUserDetails")> _
    Public Function GetUserDetails(ByVal userIdentification As String, ByVal trackingLocationHostName As String) As UserDetails
        Return GetUserDetails2(userIdentification, trackingLocationHostName, String.Empty)
    End Function

    <WebMethod(EnableSession:=True, Description:="Returns the user's login name and their permissions for accessing the test station at the hostname given.", MessageName:="GetUserDetails2")> _
    Public Function GetUserDetails2(ByVal userIdentification As String, ByVal trackingLocationHostName As String, ByVal trackingLocationName As String) As UserDetails
        If UserManager.SetUserToSession(userIdentification) Then
            Dim userDetails As New UserDetails
            userDetails.UserName = UserManager.GetCurrentValidUserLDAPName()

            Dim userPermissions As Integer = TrackingLocationManager.GetUserPermission(userDetails.UserName, trackingLocationHostName, trackingLocationName)
            userDetails.HasBasicAccess = (userPermissions And REMI.Contracts.TrackingLocationUserAccessPermission.BasicTestAccess) = TrackingLocationUserAccessPermission.BasicTestAccess
            userDetails.HasCalibrationAccess = (userPermissions And REMI.Contracts.TrackingLocationUserAccessPermission.CalibrationAccess) = TrackingLocationUserAccessPermission.CalibrationAccess
            userDetails.HasModifiedAccess = (userPermissions And REMI.Contracts.TrackingLocationUserAccessPermission.ModifiedTestAccess) = TrackingLocationUserAccessPermission.ModifiedTestAccess

            Return userDetails
        End If
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Returns the user's login name and their permissions for accessing the test station at the hostname given.", MessageName:="GetUser")> _
    Public Function GetUser(ByVal userIdentification As String) As User
        If UserManager.SetUserToSession(userIdentification) Then
            Return UserManager.GetUser(userIdentification, 0)
        End If
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Given a badge number returns a user's login name.")> _
    <Obsolete("This method has been superceeded by GetUserDetails.")> _
    Public Function GetFriendlyUserID(ByVal userIdentification As String) As String
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Return UserManager.GetCurrentValidUserLDAPName()
            End If
        Catch ex As Exception
            UserManager.LogIssue("REMI API GetFriendlyUserID", "e3", NotificationType.Errors, ex, "userIdentification: " + userIdentification)
        End Try
        Return Nothing
    End Function
#End Region

#Region "Product"
    <WebMethod(Description:="Returns a full list of the oracle Product Groups currently being worked on.")> _
    Public Function GetProductOracleList() As String()
        Try
            Return ProductGroupManager.GetProductOracleList.ToArray
        Catch ex As Exception
            ProductGroupManager.LogIssue("REMI API Get ProductOracleGroups", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Update Product.")> _
    Public Function UpdateProduct(ByVal productGroupName As String, ByVal isActive As Int32, ByVal productID As Int32) As Boolean
        Try
            Return ProductGroupManager.UpdateProduct(productGroupName, isActive, productID, String.Empty, String.Empty)
        Catch ex As Exception
            ProductGroupManager.LogIssue("REMI API Update product", "e3", NotificationType.Errors, ex)
        End Try
        Return False
    End Function

    <WebMethod(Description:="Returns a full list of the Product Groups currently being worked on.")> _
    Public Function GetProductGroups() As String()
        Try
            Dim dt As DataTable = ProductGroupManager.GetProductList(True, -1, False)
            Dim productList
            productList = (From row In dt Select colB = row(1).ToString).ToArray
            Return productList
        Catch ex As Exception
            ProductGroupManager.LogIssue("REMI API Get Productgroups", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a datatable of the Product Groups currently being worked on.")> _
    Public Function GetProductGroupsDataTable() As DataTable
        Try
            Dim productList As DataTable = ProductGroupManager.GetProductList(True, -1, False)
            Return productList
        Catch ex As Exception
            ProductGroupManager.LogIssue("REMI API GetProductGroupsDataTable", "e3", NotificationType.Errors, ex)
        End Try
        Return New DataTable
    End Function

    <WebMethod(Description:="Returns the productID for a given product group name.")> _
    Public Function GetProductIDByName(ByVal productGroupName As String) As Int32
        Try
            Return ProductGroupManager.GetProductIDByName(productGroupName)
        Catch ex As Exception
            ProductGroupManager.LogIssue("REMI API GetProductIDByName", "e3", NotificationType.Errors, ex, "Product Group Name: " + productGroupName)
        End Try
        Return 0
    End Function

    <WebMethod(Description:="Returns a full list of the settings for a product.")> _
    Public Function GetProductSettingsByProductID(ByVal productID As Int32) As SerializableDictionary(Of String, String)
        Try
            Return ProductGroupManager.GetProductSettingsDictionary(productID)
        Catch ex As Exception
            ProductGroupManager.LogIssue("REMI API GetProductSettingsByProductID", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <Obsolete("Don't use this routine any more. Use GetProductSettingsByProductID instead."), _
    WebMethod(Description:="Returns a full list of the settings for a product.")> _
    Public Function GetProductSettings(ByVal productGroupName As String) As SerializableDictionary(Of String, String)
        Try
            Dim productID As Int32 = ProductGroupManager.GetProductIDByName(productGroupName)
            Return ProductGroupManager.GetProductSettingsDictionary(productID)
        Catch ex As Exception
            ProductGroupManager.LogIssue("REMI API GetProductSettings", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <Obsolete("Don't use this routine any more. Use GetProductSettingByProductID instead."), _
    WebMethod(Description:="Returns a specific setting for a product.")> _
    Public Function GetProductSetting(ByVal productGroupName As String, ByVal keyName As String) As String
        Try
            Dim productID As Int32 = ProductGroupManager.GetProductIDByName(productGroupName)
            Return ProductGroupManager.GetProductSetting(productID, keyName)
        Catch ex As Exception
            ProductGroupManager.LogIssue("REMI API GetProductSetting", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns a specific setting for a product.")> _
    Public Function GetProductSettingByProductID(ByVal productID As Int32, ByVal keyName As String) As String
        Try
            Return ProductGroupManager.GetProductSetting(productID, keyName)
        Catch ex As Exception
            ProductGroupManager.LogIssue("REMI API GetProductSettingByProductID", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function
#End Region

#Region "Batch"
    <WebMethod(EnableSession:=True, Description:="Returns The Parametric Testing Summary By QRANumber.")> _
    Public Function GetBatchUnitsInStage(ByVal qraNumber As String) As DataTable
        Try
            Return BatchManager.GetBatchUnitsInStage(qraNumber)
        Catch ex As Exception
            BatchManager.LogIssue("REMI API GetBatchUnitsInStage", "e7", NotificationType.Errors, ex, "Request: " + qraNumber)
        End Try

        Return New DataTable("TestingSummary")
    End Function

    <WebMethod(EnableSession:=True, Description:="Returns The Parametric Testing Summary By QRANumber.")> _
    Public Function BatchUpdateOrientation(ByVal requestNumber As String, ByVal orientationID As Int32) As Boolean
        Try
            Return BatchManager.BatchUpdateOrientation(requestNumber, orientationID)
        Catch ex As Exception
            BatchManager.LogIssue("REMI API BatchUpdateOrientation", "e7", NotificationType.Errors, ex, "Request: " + requestNumber)
        End Try

        Return False
    End Function

    <WebMethod(EnableSession:=True, Description:="Returns The Parametric Testing Summary By QRANumber.")> _
    Public Function GetTestingSummary(ByVal qraNumber As String, ByVal userIdentification As String) As DataTable
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Dim b As BatchView = Me.GetBatch(qraNumber)
                Dim records = (From rm In New Remi.Dal.Entities().Instance().ResultsMeasurements _
                                          Where rm.Result.TestUnit.Batch.ID = b.ID And rm.Archived = False _
                                          Select New With {.RID = rm.Result.ID, .TestID = rm.Result.Test.ID, .TestStageID = rm.Result.TestStage.ID, .UN = rm.Result.TestUnit.BatchUnitNumber}).Distinct.ToArray

                Dim rqResults As New DataTable
                rqResults.Columns.Add("RID", GetType(Int32))
                rqResults.Columns.Add("TestID", GetType(Int32))
                rqResults.Columns.Add("TestStageID", GetType(Int32))
                rqResults.Columns.Add("UN", GetType(Int32))

                For Each rec In records
                    Dim row As DataRow = rqResults.NewRow
                    row("RID") = rec.RID
                    row("TestID") = rec.TestID
                    row("TestStageID") = rec.TestStageID
                    row("UN") = rec.UN
                    rqResults.Rows.Add(row)
                Next

                Return b.GetParametricTestOverviewTable(False, False, rqResults, False, False)
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API GetTestingSummary", "e7", NotificationType.Errors, ex, "User: " + userIdentification + " Request: " + qraNumber)
        End Try

        Return New DataTable("TestingSummary")
    End Function

    <WebMethod(EnableSession:=True, Description:="Returns The Stressing Testing Summary By QRANumber.")> _
    Public Function GetStressingSummary(ByVal qraNumber As String, ByVal userIdentification As String) As DataTable
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Dim b As BatchView = Me.GetBatch(qraNumber)
                Return b.GetStressingOverviewTable(False, False, False, False, If(b.Orientation IsNot Nothing, b.Orientation.Definition, String.Empty))
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API GetStressingSummary", "e7", NotificationType.Errors, ex, "User: " + userIdentification + " Request: " + qraNumber)
        End Try

        Return New DataTable("StressingSummary")
    End Function

    <WebMethod(Description:="Determines whether the batch was started before assigned in TRS.")> _
    Public Function BatchStartedBeforeAssigned(ByVal qraNumber As String) As Boolean
        Try
            Dim barcode As New DeviceBarcodeNumber(BatchManager.GetReqString(qraNumber))

            If (barcode.Validate()) Then
                Dim batch As Batch = BatchManager.GetItem(barcode.BatchNumber)

                If ((From tr In batch.TestRecords Where tr.TestName <> "Sample Evaluation" Select tr).Count > 0) Then
                    If (batch.TRSData.RequestStatus.ToLower = TRSStatus.Received.ToString().ToLower() Or batch.TRSData.RequestStatus.ToLower = TRSStatus.Submitted.ToString().ToLower() Or batch.TRSData.RequestStatus.ToLower = "pm review") Then
                        Dim us As New UserSearch()
                        us.TestCenterID = batch.TestCenterLocationID

                        Dim emails As List(Of String) = (From u In Remi.Dal.UserDB.UserSearchList(us, False) Where u.IsProjectManager = True Or u.IsTestCenterAdmin = True Select u.EmailAddress).Distinct.ToList

                        Remi.Core.Emailer.SendMail(String.Join(",", emails.ConvertAll(Of String)(Function(i As String) i.ToString()).ToArray()), "tsdinfrastructure@blackberry.com", String.Format("{0} Started Before Assigned", qraNumber), String.Format("Please assign this batch as soon as possible in the TRS <a href=""{0}"">{1}</a>", batch.TRSLink, qraNumber), True)

                        Return True
                    End If
                End If
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API BatchStartedBeforeAssigned", "e3", NotificationType.Errors, ex)
        End Try

        Return False
    End Function

    <WebMethod(Description:="Gets Default Request Number.")> _
    Public Function GetDefaultReqNum() As String
        Try
            Return Remi.Core.REMIConfiguration.DefaultRequestNumber()
        Catch ex As Exception
            BatchManager.LogIssue("REMI API GetDefaultReqNum", "e3", NotificationType.Errors, ex)
        End Try
        Return String.Empty
    End Function

    <WebMethod(Description:="Gets Default Request Number With Unit.")> _
    Public Function GetDefaultReqNumWithUnit() As String
        Try
            Return String.Format("{0}-001", Remi.Core.REMIConfiguration.DefaultRequestNumber())
        Catch ex As Exception
            BatchManager.LogIssue("REMI API GetDefaultReqNum", "e3", NotificationType.Errors, ex)
        End Try
        Return String.Empty
    End Function

    <WebMethod(Description:="Gets product type Information.")> _
    Public Function GetProductTypeID(ByVal qraNumber As String) As Int32
        Try
            Dim batch As Remi.Entities.Batch = BatchManager.GetRAWBatchInformation(qraNumber)

            If batch IsNot Nothing And batch.ProductType IsNot Nothing Then
                Return batch.ProductType.LookupID
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API GetProductTypeID", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Gets Test Center Information.")> _
    Public Function GetTestCenterID(ByVal qraNumber As String) As Int32
        Try
            Dim batch As Remi.Entities.Batch = BatchManager.GetRAWBatchInformation(qraNumber)

            If batch IsNot Nothing And batch.TestCenter IsNot Nothing Then
                Return batch.TestCenter.LookupID
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API GetTestCenterID", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Gets accessory Information.")> _
    Public Function GetAccessoryTypeID(ByVal qraNumber As String) As Int32
        Try
            Dim batch As Remi.Entities.Batch = BatchManager.GetRAWBatchInformation(qraNumber)

            If batch IsNot Nothing And batch.AccessoryGroup IsNot Nothing Then
                Return batch.AccessoryGroup.LookupID
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API GetAccessoryTypeID", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Given a qra number this method will return the batch information.")> _
    Public Function GetBatch(ByVal QRANumber As String) As BatchView
        Try
            Return BatchManager.GetViewBatch(QRANumber)
        Catch ex As Exception
            BatchManager.LogIssue("REMI API GetBatch", "e3", NotificationType.Errors, ex, "Request: " + QRANumber)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Gets The Request Notifications")> _
    Public Function GetBatchNotifications(ByVal QRANumber As String) As NotificationCollection
        Try
            Dim b As BatchView = BatchManager.GetViewBatch(QRANumber)

            Return b.GetAllNotifications(False)
        Catch ex As Exception
            BatchManager.LogIssue("REMI API GetBatchNotifications", "e3", NotificationType.Errors, ex, "Request: " + QRANumber)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Gets The Request Comments")> _
    Public Function GetBatchComments(ByVal QRANumber As String) As DataTable
        Try
            Dim b As BatchView = BatchManager.GetViewBatch(QRANumber)
            Dim dtComments As New DataTable("Comments")
            dtComments.Columns.Add("Text", Type.GetType("System.String"))
            dtComments.Columns.Add("UserName", Type.GetType("System.String"))
            dtComments.Columns.Add("DateAdded", Type.GetType("System.DateTime"))

            For Each comment In b.Comments
                Dim dr As DataRow = dtComments.NewRow
                dr("Text") = comment.Text
                dr("UserName") = comment.UserName
                dr("DateAdded") = comment.DateAdded
                dtComments.Rows.Add(dr)
            Next

            Return dtComments
        Catch ex As Exception
            BatchManager.LogIssue("REMI API GetBatchComments", "e3", NotificationType.Errors, ex, "Request: " + QRANumber)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Given a qra number this method will return the Hardware Revision of a batch.")> _
    Public Function GetHardwareRevision(ByVal QRANumber As String) As String
        Try
            Dim batch As Remi.Entities.Batch = BatchManager.GetRAWBatchInformation(QRANumber)

            If batch IsNot Nothing Then
                If batch.HWRevision IsNot Nothing Then
                    Return batch.HWRevision
                Else
                    Return String.Empty
                End If
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API Get Hardware Revision", "e3", NotificationType.Errors, ex, "Request: " + QRANumber)
        End Try
        Return String.Empty
    End Function

    <WebMethod(Description:="Given a QRA Number this method returns the CPR Number.")> _
    Public Function GetCPRNumber(ByVal QRANumber As String) As String
        Try
            Dim batch As Remi.Entities.Batch = BatchManager.GetRAWBatchInformation(QRANumber)

            If batch IsNot Nothing Then
                If batch.CPRNumber IsNot Nothing Then
                    Return batch.CPRNumber
                Else
                    Return String.Empty
                End If
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API Get CPR Number", "e3", NotificationType.Errors, ex, "Request: " + QRANumber)
        End Try
        Return String.Empty
    End Function

    <WebMethod(Description:="Get Next Stage By Batch.")> _
    Public Function GetBatchNextStage(ByVal requestNumber As String) As TestStage
        Try
            Dim barcode As New DeviceBarcodeNumber(BatchManager.GetReqString(requestNumber))

            If (barcode.Validate() And barcode.HasTestUnitNumber) Then
                Return TestStageManager.GetNextTestStage(barcode.BatchNumber, barcode.UnitNumber)
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API Get batch stages", "e3", NotificationType.Errors, ex, "Request: " + requestNumber)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Get's All Batch Stages Name.")> _
    Public Function GetTestStagesNameByBatch(ByVal requestNumber As String) As List(Of String)
        Try
            Dim batch As Remi.Entities.Batch = BatchManager.GetRAWBatchInformation(requestNumber)

            If batch IsNot Nothing Then
                Return (From s In TestStageManager.GetTestStagesNameByBatch(batch.ID) Select s.Value).ToList
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API Get batch stages name", "e3", NotificationType.Errors, ex, "Request: " + requestNumber)
        End Try
        Return New List(Of String)
    End Function

    <WebMethod(Description:="Get's All Batch Stages.")> _
    Public Function GetTestStagesByBatch(ByVal requestNumber As String) As TestStageCollection
        Try
            Dim b As Batch = BatchManager.GetItem(requestNumber)

            If b IsNot Nothing Then
                Dim t As List(Of Int32) = (From stg In b.Tasks Select stg.TestStageID).ToList

                Return b.Job.TestStages.FindByIDs(t)
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API Get batch stages", "e3", NotificationType.Errors, ex, "Request: " + requestNumber)
        End Try
        Return New TestStageCollection
    End Function

    <WebMethod(Description:="Get's All Batch Stages needing completion.")> _
    Public Function GetStagesNeedingCompletionByUnit(ByVal requestNumber As String, ByVal unitNumber As Int32) As DataSet
        Try
            Return BatchManager.GetStagesNeedingCompletionByUnit(requestNumber, unitNumber)
        Catch ex As Exception
            BatchManager.LogIssue("REMI API GetBatchStagesNeedingCompletion", "e3", NotificationType.Errors, ex, "Request: " + requestNumber)
        End Try
        Return New DataSet("NeedsTesting")
    End Function

    <WebMethod(Description:="Get's All Batch Tests By Stage.")> _
    Public Function GetTestsByBatchStage(ByVal requestNumber As String, ByVal testStageName As String) As List(Of String)
        Try
            Dim batch As Remi.Entities.Batch = BatchManager.GetRAWBatchInformation(requestNumber)

            If batch IsNot Nothing Then
                Return (From s In TestManager.GetTestsByBatchStage(batch.ID, testStageName, False) Select s.Value).ToList
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API Get batch tests by stage", "e3", NotificationType.Errors, ex, "Request: " + requestNumber)
        End Try
        Return New List(Of String)
    End Function

    <WebMethod(Description:="Get's All Batch Tests.")> _
    Public Function GetTestsByBatch(ByVal requestNumber As String) As DataTable
        Try
            Dim batch As Remi.Entities.Batch = BatchManager.GetRAWBatchInformation(requestNumber)

            If batch IsNot Nothing Then
                Return TestManager.GetTestsByBatch(batch.ID)
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API Get batch tests", "e3", NotificationType.Errors, ex, "Request: " + requestNumber)
        End Try
        Return New DataTable("TestsByBatch")
    End Function

    <WebMethod(Description:="Add's a comment to the batch.")> _
    Public Function SaveBatchComment(ByVal qraNumber As String, ByVal userIdentification As String, ByVal comment As String) As Boolean
        Try
            Return BatchManager.SaveBatchComment(qraNumber, userIdentification, comment)
        Catch ex As Exception
            BatchManager.LogIssue("REMI API SaveBatchComment", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="DNP's all Parametric Tests For A Particular Batch.")> _
    Public Function DNPParametricForBatch(ByVal qraNumber As String, ByVal userIdentification As String, ByVal unitNumber As Int32) As Boolean
        Try
            Return BatchManager.DNPParametricForBatch(qraNumber, userIdentification, unitNumber)
        Catch ex As Exception
            BatchManager.LogIssue("REMI API DNPParametricForBatch", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns the percentage as an integer of test stages that are complete based on the current test stage that the batch is at.")> _
    Public Function GetPercentageCompleteForBatch(ByVal qraNumber As String) As Integer
        Try
            Dim b As BatchView = BatchManager.GetViewBatch(qraNumber)

            Return b.PercentageComplete()
        Catch ex As Exception
            BatchManager.LogIssue("REMI API Get Percentage", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Returns the data associated with a particular batch.")> _
    Public Function GetBatchResultsOverview(ByVal qraNumber As String) As List(Of TestStageResultOverview)
        Try
            Dim b As BatchView = BatchManager.GetViewBatch(qraNumber)

            Return GetTestStageOverview(b)
        Catch ex As Exception
            BatchManager.LogIssue("REMI API Get View Batch", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Returns a list of the Request's of active batches.")> _
    Public Function GetActiveBatchList() As String()
        Try
            Return BatchManager.GetActiveBatchList()
        Catch ex As Exception
            BatchManager.LogIssue("GetActiveBatchList", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Returns a list of the Request's of reviewed batches in TRS.")> _
    Public Function GetTRSReviewedBatchList(ByVal testCenter As String) As String()
        Try
            Return BatchManager.GetTRSReviewedBatchList(testCenter)
        Catch ex As Exception
            BatchManager.LogIssue("GetTRSReviewedBatchList", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Checks if batch is ready to be moved to a different status.")> _
    Public Function CheckBatchForStatusUpdates(ByVal qraNumber As String, ByVal userIdentification As String) As Integer
        Try
            If (HasAccess("RemiTimedServiceAvailable")) Then
                If UserManager.SetUserToSession(userIdentification) Then
                    Return BatchManager.CheckSingleBatchForStatusUpdate(Helpers.CleanInputText(qraNumber, 21))
                End If
            Else
                Return 0
            End If
        Catch ex As Exception
            BatchManager.LogIssue("CheckBatchForStatusUpdates", "e3", NotificationType.Errors, ex)
        End Try
        Return 1
    End Function

    <Obsolete("Don't use this routine any more. Use ScanAdvanced instead."), _
    WebMethod(EnableSession:=True, Description:="Used to scan a device in to a test in the REMI system. Input Values are: Request [(*REQUIRED*): ""QRA-yy-bbbb-uuu-lllll""],SelectedTestID [Optional (0 treated as null):""TestID""],OverallTestResult [ ** OBSOLETE ** - REMI only uses relab for results],UserIdentification [Optional (Empty String Treated as Null): ""BadgeScan Number""] ,locationIdentification [optional (Empty String is treated as null): the hostname of the pc]")> _
    Public Function Scan(ByVal qraNumber As String, ByVal testStageName As String, ByVal testName As String, ByVal overallTestResult As String, _
                                ByVal userIdentification As String, ByVal locationIdenitifcation As String, ByVal trackingLocationName As String) As ScanReturnData
        Return ScanAdvanced(qraNumber, testStageName, testName, overallTestResult, userIdentification, locationIdenitifcation, trackingLocationName, String.Empty, String.Empty)
    End Function

    ''' <summary>
    ''' This web method is used to scan a unit in and out of locations
    ''' </summary>
    ''' <param name="qraNumber"></param>
    ''' <param name="testName"></param>
    ''' <param name="testStageName"></param>
    ''' <param name="overallTestResult"></param>
    ''' <param name="userIdentification"></param>
    ''' <returns></returns>
    ''' <remarks></remarks>
    <WebMethod(EnableSession:=True, Description:="Used to scan a device in to a test in the REMI system. Input Values are: Request [(*REQUIRED*): ""QRA-yy-bbbb-uuu-lllll""],SelectedTestID [Optional (0 treated as null):""TestID""],OverallTestResult [ ** OBSOLETE ** - REMI only uses relab for results],UserIdentification [Optional (Empty String Treated as Null): ""BadgeScan Number""] ,locationIdentification [optional (Empty String is treated as null): the hostname of the pc]")> _
    Public Function ScanAdvanced(ByVal qraNumber As String, ByVal testStageName As String, ByVal testName As String, ByVal overallTestResult As String, _
                                ByVal userIdentification As String, ByVal locationIdenitifcation As String, ByVal trackingLocationName As String, ByVal jobName As String, ByVal productGroup As String) As ScanReturnData
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Dim sd As ScanReturnData = ScanManager.Scan(Helpers.CleanInputText(qraNumber, 21), Helpers.CleanInputText(testStageName, 400), Helpers.CleanInputText(testName, 400), locationIdentification:=locationIdenitifcation, ResultString:=overallTestResult, trackingLocationname:=trackingLocationName, jobName:=jobName, productGroup:=productGroup)

                Return sd
            End If
        Catch ex As Exception
            ScanManager.LogIssue("REMI API - Scan", "NA", NotificationType.Errors, ex, "Request: " + qraNumber + " TS: " + testStageName + " Test: " + testName + " Result: " + overallTestResult + " UID: " + userIdentification + " Location ID: " + locationIdenitifcation)
        End Try
        Return Nothing
    End Function

    Private Function GetTestStageOverview(ByVal batchOverview As BatchView) As List(Of TestStageResultOverview)
        Dim retVal As New List(Of TestStageResultOverview)
        Dim newT As TaskResultOverview
        Dim newTS As TestStageResultOverview
        Dim allFails As List(Of Integer)

        newT = New TaskResultOverview
        newT.FailDocs = New List(Of Integer)

        'add all the columns
        ' dt.Columns.Add("Sample Evaluation Test")
        Dim applicableParamtericTests As String() = (From task In batchOverview.Tasks Where task.TestType = TestType.Parametric Order By task.TestName Ascending Select task.TestName).Distinct().ToArray()

        For Each ts In (From task In batchOverview.Tasks Where task.TestStageType = TestType.Parametric AndAlso task.ProcessOrder >= 0 Order By task.ProcessOrder Ascending Select task.TestStageName, task.ProcessOrder).Distinct

            newTS = New TestStageResultOverview
            newTS.Tasks = New List(Of TaskResultOverview)

            newTS.TestStageName = ts.TestStageName
            newTS.Order = ts.ProcessOrder

            For Each t As String In applicableParamtericTests
                newT = New TaskResultOverview
                allFails = New List(Of Integer)
                newT.TaskName = t
                newT.OverallResult = batchOverview.GetTRSTestOverviewCellString(batchOverview.JobName, newTS.TestStageName, newT.TaskName)


                For Each record In (From tr In batchOverview.TestRecords _
                    Where tr.TestName = newT.TaskName And tr.TestStageName = newTS.TestStageName And _
                    tr.JobName = batchOverview.JobName Select tr)

                    allFails.AddRange(From fd In record.FailDocs Select fd.RQID)
                Next
                newT.FailDocs = allFails.Distinct().ToList()
                newTS.Tasks.Add(newT)
            Next
            retVal.Add(newTS)
        Next
        Return retVal
    End Function
#End Region

#Region "Incoming"
    ''' <summary>
    ''' Added as write becuase if the get fails it auto adds the batch.
    ''' </summary>
    ''' <param name="qraNumber"></param>
    ''' <returns></returns>
    ''' <remarks></remarks>
    <WebMethod(EnableSession:=True, Description:="Attempts to retrieve a batch from REMI and if it cannot find the batch will attempt to retrieve it from TRS. This method requires identification and will also save new batches.")> _
    Public Function IncomingGetAndSaveBatch(ByVal qraNumber As String, ByVal userIdentification As String) As IncomingAppBatchData
        Try
            Dim bc As New DeviceBarcodeNumber(Helpers.CleanInputText(BatchManager.GetReqString(qraNumber), 21))
            Dim ib As New IncomingAppBatchData
            If bc.Validate Then
                Dim b As Batch = BatchManager.GetItem(bc.BatchNumber)

                If b IsNot Nothing Then
                    ib.JobName = b.Job.Name
                    ib.JobID = b.Job.ID
                    ib.ProductGroup = b.ProductGroup
                    ib.QRANumber = b.QRANumber
                    ib.AssemblyNumber = b.AssemblyNumber
                    ib.AssemblyRevision = b.AssemblyRevision
                    ib.IsInREMI = b.Status <> BatchStatus.NotSavedToREMI
                    ib.Notifications = b.Notifications
                    ib.PartName = b.PartName
                End If
            End If

            Return ib
        Catch ex As Exception
            BatchManager.LogIssue("REMI API Get incoming batch", "e3", NotificationType.Errors, ex, "Request: " + qraNumber)
        End Try
        Return Nothing
    End Function

    ''' <summary>
    ''' Added as write becuase if the get fails it auto adds the batch.
    ''' </summary>
    ''' <param name="qraNumber"></param>
    ''' <returns></returns>
    ''' <remarks></remarks>
    <WebMethod(EnableSession:=True, Description:="Attempts to retrieve a batch from REMI and if it cannot find the batch will attempt to retrieve it from TRS.")> _
    Public Function IncomingGetBatch(ByVal qraNumber As String) As IncomingAppBatchData
        Try
            Dim bc As New DeviceBarcodeNumber(Helpers.CleanInputText(BatchManager.GetReqString(qraNumber), 21))
            Dim ib As New IncomingAppBatchData
            If bc.Validate Then
                Dim b As Batch = BatchManager.GetItem(bc.BatchNumber)
                If b IsNot Nothing Then
                    ib.JobName = b.Job.Name
                    ib.JobID = b.Job.ID
                    ib.ProductGroup = b.ProductGroup
                    ib.QRANumber = b.QRANumber
                    ib.AssemblyNumber = b.AssemblyNumber
                    ib.AssemblyRevision = b.AssemblyRevision
                    ib.IsInREMI = b.Status <> BatchStatus.NotSavedToREMI
                    ib.Notifications = b.Notifications
                    ib.PartName = b.PartName
                End If
            End If
            Return ib
        Catch ex As Exception
            BatchManager.LogIssue("REMI API Get incoming batch", "e3", NotificationType.Errors, ex, "Request: " + qraNumber)
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Adds a new batch to REMI. This is used to confirm the job is correct.")> _
    Public Function IncomingSaveBatch(ByVal qraNumber As String, ByVal userIdentification As String) As Boolean
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Dim b As Batch = BatchManager.GetItem(qraNumber)
                Return True
            End If
        Catch ex As Exception
            BatchManager.LogIssue("REMI API Add Incoming Batch", "e9", NotificationType.Errors, ex, "Request: " + qraNumber + " UID: " + userIdentification)
        End Try
        Return False
    End Function
#End Region

#Region "SendMail"
    <WebMethod(EnableSession:=True, Description:="Sends an email via smtp. Comma delimit destinations.")> _
    Public Sub SendMail(ByVal destinations As String, ByVal sender As String, ByVal subject As String, ByVal messageBody As String)
        Try
            Remi.Core.Emailer.SendMail(destinations, sender, subject, messageBody, False)
        Catch ex As Exception
            UserManager.LogIssue("Email could not be sent via API.", "e3", NotificationType.Errors, ex, "Dest: " + destinations + "Sender: " + sender)
        End Try
    End Sub

    <WebMethod(EnableSession:=True, Description:="Sends an email via smtp. Comma delimit destinations.")> _
    Public Sub SendMailAdvanced(ByVal destinations As String, ByVal sender As String, ByVal subject As String, ByVal messageBody As String, ByVal isHTML As Boolean)
        Try
            Remi.Core.Emailer.SendMail(destinations, sender, subject, messageBody, isHTML)
        Catch ex As Exception
            UserManager.LogIssue("Email could not be sent via API.", "e3", NotificationType.Errors, ex, "Dest: " + destinations + "Sender: " + sender)
        End Try
    End Sub
#End Region

#Region "Return data models"
    Structure TestStageResultOverview
        Public TestStageName As String
        Public Order As Integer
        Public Tasks As List(Of TaskResultOverview)
    End Structure

    Structure TaskResultOverview
        Public TaskName As String
        Public OverallResult As String
        Public FailDocs As List(Of Integer)
    End Structure
#End Region

#Region "Return data structures"
    Structure IncomingAppBatchData
        Public QRANumber As String
        Public JobID As Integer
        Public JobName As String
        Public ProductGroup As String
        Public PartName As String
        Public AssemblyRevision As String
        Public AssemblyNumber As String
        Public IsInREMI As Boolean
        Public Notifications As NotificationCollection
    End Structure

    Structure ExceptionData
        Public TestName As String
        Public ExceptionExists As Boolean
    End Structure

    Structure UserDetails
        Public UserName As String
        Public HasBasicAccess As Boolean
        Public HasModifiedAccess As Boolean
        Public HasCalibrationAccess As Boolean
    End Structure
#End Region

#Region "TargetAccess"
    <WebMethod(Description:="Retrieves all target access for a workstation and you can include the global target access.")> _
    Public Function GetAllAccessByWorkstation(ByVal workstationName As String, ByVal getGlobalAccess As Boolean) As List(Of String)
        Try
            Return TargetAccessManager.GetAllAccessByWorkstation(workstationName, getGlobalAccess)
        Catch ex As Exception
            TargetAccessManager.LogIssue("REMI API GetAllAccessByWorkstation", "e3", NotificationType.Errors, ex)
        End Try
        Return New List(Of String)
    End Function

    <WebMethod(Description:="Determines whether that target has access or not.")> _
    Public Function HasAccess(ByVal targetAccess As String) As Boolean
        Try
            Return TargetAccessManager.HasAccess(targetAccess, String.Empty)
        Catch ex As Exception
            TargetAccessManager.LogIssue("REMI API HasAccess", "e3", NotificationType.Errors, ex)
        End Try
        Return False
    End Function

    <WebMethod(Description:="Determines whether that target and workstation has access or not.")> _
    Public Function HasAccessByWorkstation(ByVal targetAccess As String, ByVal workstationName As String) As Boolean
        Try
            Return TargetAccessManager.HasAccess(targetAccess, workstationName)
        Catch ex As Exception
            TargetAccessManager.LogIssue("REMI API HasAccess", "e3", NotificationType.Errors, ex)
        End Try
        Return False
    End Function
#End Region

#Region "Test Records"
    <WebMethod(EnableSession:=True, Description:="GetTestRecords.")> _
    Public Function GetTestRecords(ByVal QRANumber As String, ByVal userIdentification As String) As TestRecordCollection
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Dim b As BatchView = Me.GetBatch(QRANumber)

                If (b IsNot Nothing) Then
                    Return b.TestRecords
                End If
            End If
        Catch ex As Exception
            TestRecordManager.LogIssue("REMI API GetTestRecords", "e8", NotificationType.Errors, ex, String.Format("Request: {0}" + QRANumber))
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Adds a new test record for non parametric tests.")> _
    Public Function TestRecordAdd(ByVal qranumber As String, ByVal unitNumber As Int32, ByVal userIdentification As String, ByVal testRecordStatus As TestRecordStatus, ByVal jobName As String, ByVal testStageName As String, ByVal testName As String) As Boolean
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Dim testStage As TestStage = TestStageManager.GetTestStage(testStageName, jobName)
                Dim test As Test = Nothing

                If (testStage.TestID > 0) Then
                    test = TestManager.GetTest(testStage.TestID)
                Else
                    test = TestManager.GetTestByName(testName, False)
                End If

                If (test.TestType <> TestType.Parametric) Then
                    Dim barcode As New DeviceBarcodeNumber(BatchManager.GetReqString(qranumber), unitNumber)

                    If (barcode.Validate()) Then
                        Dim testUnitID As Int32 = TestUnitManager.GetUnitID(qranumber, unitNumber)
                        Dim tr As New TestRecord

                        Dim b As BatchView = Me.GetBatch(qranumber)

                        If (b IsNot Nothing) Then
                            If (b.TestRecords.FindByTestStageTest(b.JobName, testStageName, testName).Count() > 0) Then
                                tr = b.TestRecords.FindByTestStageTest(b.JobName, testStageName, testName)(0)
                            End If
                        End If

                        If (tr Is Nothing Or tr.ID = 0) Then
                            tr = New TestRecord(barcode.BatchNumber, barcode.UnitNumber, jobName, testStageName, testName, testUnitID, userIdentification, test.ID, testStage.ID)
                        End If

                        tr.Status = testRecordStatus
                        tr.ResultSource = TestResultSource.WebService

                        Return TestRecordManager.Save(tr)
                    Else
                        Return False
                    End If
                Else
                    Return False
                End If
            End If
        Catch ex As Exception
            TestRecordManager.LogIssue("Could not add test record.", "e3", NotificationType.Errors, ex, String.Format("Request: {0}\nUnit: {1}\nStatus: {2}\nUser: {3}\nJob: {4}\nTestStage: {5}\nTest: {6}", qranumber, unitNumber, testRecordStatus, userIdentification, jobName, testStageName, testName))
        End Try
        Return False
    End Function
#End Region

#Region "Config"
    <WebMethod(Description:="Returns configuration object.")> _
    Public Function BuildConfigurationObject(ByVal srd As ScanReturnData, ByVal machineName As String) As ConfigurationReturnData
        Dim configReturnData As New ConfigurationReturnData()
        Dim config As New ProductConfiguration()
        Dim hostID As Int32 = GetHostID(machineName, srd.TrackingLocationID)

        configReturnData.HostID = hostID
        configReturnData.StationXML = TrackingLocationManager.GetStationConfigurationXML(hostID, String.Empty).ToString() 'config.GetStationConfigurationXML(hostID)
        configReturnData.TestXML = config.GetProductConfigurationXML(srd.ProductID, srd.TestID)
        configReturnData.HasProductXML = ProductGroupManager.HasProductConfigurationXML(srd.ProductID, srd.TestID, String.Empty).ToString() 'config.HasProductConfigurationXML(srd.ProductID, srd.TestID)
        configReturnData.HasCalibrationXML = CalibrationManager.HasCalibrationConfigurationXML(srd.ProductID, hostID, srd.TestID) 'config.HasCalibrationConfigurationXML(srd.ProductID, srd.TestID, hostID)
        configReturnData.HasStationXML = If(configReturnData.StationXML = "<StationConfiguration />", False, True)
        configReturnData.Calibrations = CalibrationManager.GetAllCalibrationConfigurationXML(srd.ProductID, hostID, srd.TestID) 'config.GetAllCalibrationConfigurationXML(hostID, srd.ProductID, srd.TestID)
        configReturnData.ProductConfigs = ProductGroupManager.GetAllProductConfigurationXMLs(srd.ProductID, srd.TestID, True)

        Return configReturnData
    End Function
#End Region

#Region "Exceptions"
    <WebMethod(EnableSession:=True, Description:="Delete Ex.")> _
    Public Function DeleteException(ByVal qraNumber As String, ByVal testName As String, ByVal testStageName As String, ByVal testUnitID As Int32, ByVal userIdentification As String) As Boolean
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Dim notification As Notification = ExceptionManager.DeleteException(qraNumber, testName, testStageName, testUnitID)

                If (notification.Type = NotificationType.Errors Or notification.Type = NotificationType.Fatal Or notification.Type = NotificationType.Warning) Then
                    Return False
                Else
                    Return True
                End If
            End If
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API SaveJob", "e3", NotificationType.Errors, ex)
        End Try
        Return False
    End Function

    <WebMethod(EnableSession:=True, Description:="Update Job.")> _
    Public Function AddException(ByVal qraNumber As String, ByVal testName As String, ByVal testStageName As String, ByVal testUnitID As Int32, ByVal userIdentification As String) As Boolean
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Dim exc As New TestException()
                exc.TestUnitID = testUnitID
                exc.TestStageName = testStageName
                exc.TestName = testName

                Dim barcode As New DeviceBarcodeNumber(BatchManager.GetReqString(qraNumber))

                exc.QRAnumber = barcode.BatchNumber
                exc.UnitNumber = barcode.UnitNumber

                Dim notification As Notification = ExceptionManager.AddException(exc)

                If (notification.Type = NotificationType.Errors Or notification.Type = NotificationType.Fatal Or notification.Type = NotificationType.Warning) Then
                    Return False
                Else
                    Return True
                End If
            End If
        Catch ex As Exception
            LookupsManager.LogIssue("REMI API SaveJob", "e3", NotificationType.Errors, ex)
        End Try
        Return False
    End Function
#End Region

End Class