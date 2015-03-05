Imports System.Web.Services
Imports System.Web.Services.Protocols
Imports System.ComponentModel
Imports Remi.Bll
Imports Remi.Validation
Imports System.Xml.XPath
Imports System.IO
Imports System.Xml
Imports System.Configuration
Imports Remi.BusinessEntities

<System.Web.Services.WebService(Name:="Configuration", Namespace:="http://go/remi/")> _
<System.Web.Services.WebServiceBinding(ConformsTo:=WsiProfiles.None)> _
<ToolboxItem(False)> _
Public Class ProductConfiguration
    Inherits System.Web.Services.WebService

#Region "OBSOLETE"
#Region "Product"
    <Obsolete("Don't use this routine any more."), _
    WebMethod(Description:="Retrieve Product Test Configuration")> _
    Public Function GetProductConfigurationXML(ByVal productID As Int32, ByVal testID As Int32) As String
        Dim xml As String = String.Empty
        Try
            Dim record As Int32 = (From x In New Remi.Dal.Entities().Instance().ProductConfigurationUploads Where x.Test.ID = testID And x.Product.ID = productID Select x.ID).FirstOrDefault()

            If (record > 0) Then
                xml = ProductGroupManager.GetProductConfigurationXML(record).ToString()
            Else
                xml = "<PC />"
            End If
        Catch ex As Exception
            ProductGroupManager.LogIssue("Product Group Manager GetProductConfigurationXML", "e3", NotificationType.Errors, ex, String.Format("ProductID: {0} TestID: {1}", productID, testID))
        End Try
        Return xml
    End Function

    <Obsolete("Don't use this routine any more."), _
    WebMethod(Description:="Returns whether this product and test has any product configuration.")> _
    Public Function HasProductConfigurationXML(ByVal productID As Int32, ByVal testID As Int32) As Boolean
        Dim hasXML As Boolean = False
        Try
            hasXML = ProductGroupManager.HasProductConfigurationXML(productID, testID, String.Empty)
        Catch ex As Exception
            ProductGroupManager.LogIssue("Product Group Manager HasProductConfigurationXML", "e3", NotificationType.Errors, ex, String.Format("ProductID: {0} TestID: {1}", productID, testID))
        End Try
        Return hasXML
    End Function

    <Obsolete("Don't use this routine any more."), _
    WebMethod(Description:="Retrieve Product Test Configuration By Name")> _
    Public Function GetProductConfigurationXMLByName(ByVal productID As Int32, ByVal testID As Int32, ByVal name As String) As String
        Dim xml As String = String.Empty
        Try
            Dim record As Int32 = (From x In New Remi.Dal.Entities().Instance().ProductConfigurationUploads Where x.Test.ID = testID And x.Product.ID = productID And x.PCName = name Select x.ID).FirstOrDefault()

            If (record > 0) Then
                xml = ProductGroupManager.GetProductConfigurationXML(record).ToString()
            Else
                xml = "<PC />"
            End If
        Catch ex As Exception
            ProductGroupManager.LogIssue("Product Group Manager GetProductConfigurationXMLByName", "e3", NotificationType.Errors, ex, String.Format("ProductID: {0} TestID: {1} Name: {2}", productID, testID, name))
        End Try
        Return xml
    End Function

    <Obsolete("Don't use this routine any more."), _
    WebMethod(Description:="Returns whether this product and test has any product configuration.")> _
    Public Function HasProductConfigurationXMLByName(ByVal productID As Int32, ByVal testID As Int32, ByVal name As String) As Boolean
        Dim hasXML As Boolean = False
        Try
            hasXML = ProductGroupManager.HasProductConfigurationXML(productID, testID, name)
        Catch ex As Exception
            ProductGroupManager.LogIssue("Product Group Manager HasProductConfigurationXMLByName", "e3", NotificationType.Errors, ex, String.Format("ProductID: {0} TestID: {1} Name: {2}", productID, testID, name))
        End Try
        Return hasXML
    End Function

    <Obsolete("Don't use this routine any more."), _
    WebMethod(Description:="Returns all product/test config seperated by the name of the configuration")> _
    Public Function GetProductConfigurationXMLCombined(ByVal productID As Int32, ByVal testID As Int32) As String
        Dim xml As String = String.Empty
        Try
            xml = ProductGroupManager.GetProductConfigurationXMLCombined(productID, testID).ToString()
        Catch ex As Exception
            ProductGroupManager.LogIssue("Product Group Manager GetProductConfigurationXMLCombined", "e3", NotificationType.Errors, ex, String.Format("ProductID: {0} TestID: {1}", productID, testID))
        End Try
        Return xml
    End Function

    <Obsolete("Don't use this routine any more."), _
    WebMethod(Description:="Returns whether this product and test has any product configurations.")> _
    Public Function GetAllProductConfigurationXMLs(ByVal productID As Int32, ByVal testID As Int32, ByVal loadVersions As Boolean) As ProductConfigCollection
        Try
            Return ProductGroupManager.GetAllProductConfigurationXMLs(productID, testID, loadVersions)
        Catch ex As Exception
            ProductGroupManager.LogIssue("Product Group Manager GetAllProductConfigurationXMLs", "e3", NotificationType.Errors, ex, String.Format("ProductID: {0} TestID: {1} LoadVersions: {2}", productID, testID, loadVersions))
        End Try

        Return New ProductConfigCollection
    End Function
#End Region

#Region "Station"
    <Obsolete("Don't use this routine any more."), _
    WebMethod(Description:="Retrieve Station Configuration")> _
    Public Function GetStationConfigurationXML(ByVal hostID As Int32) As String
        Dim xml As String = String.Empty
        Try
            xml = GetStationConfigurationXMLProfile(hostID, String.Empty).ToString()
        Catch ex As Exception
            TrackingLocationManager.LogIssue("Get Host Station Configuration XML", "e3", NotificationType.Errors, ex, String.Format("HostID: {0}", hostID))
        End Try
        Return xml
    End Function

    <Obsolete("Don't use this routine any more."), _
    WebMethod(Description:="Retrieve Station Configuration Based on Profile")> _
    Public Function GetStationConfigurationXMLProfile(ByVal hostID As Int32, ByVal profileName As String) As String
        Dim xml As String = String.Empty
        Try
            xml = TrackingLocationManager.GetStationConfigurationXML(hostID, profileName).ToString()
        Catch ex As Exception
            TrackingLocationManager.LogIssue("Get Host Station Configuration XML", "e3", NotificationType.Errors, ex, String.Format("HostID: {0} ProfileName: {1}", hostID, profileName))
        End Try
        Return xml
    End Function

    <Obsolete("Don't use this routine any more."), _
    WebMethod(Description:="Retrieve Multiple Station Configuration By HostName")> _
    Public Function GetAllStationConfigurationXML(ByVal hostName As String) As List(Of String)
        Dim config As New List(Of String)
        Try
            Dim tlColl As TrackingLocationCollection
            tlColl = TrackingLocationManager.GetMultipleTrackingLocationByHostName(hostName)

            If (tlColl IsNot Nothing) Then
                For Each tl As TrackingLocation In tlColl
                    Dim xml As String = String.Empty
                    Dim dt As DataTable = TrackingLocationManager.GetTrackingLocationPlugins(tl.ID)

                    For Each row As DataRow In dt.Rows
                        xml = GetStationConfigurationXMLProfile(tl.HostID, row("PluginName").ToString())

                        If (xml.ToLower().Trim() <> "<stationconfiguration />") Then
                            Dim xmlFile As XDocument = XDocument.Parse(xml)
                            Dim el As New XElement("PluginName")
                            el.Value = If(row("PluginName").ToString() Is Nothing, String.Empty, row("PluginName").ToString())
                            xmlFile.Root.Add(el)
                            xml = xmlFile.ToString()
                            config.Add(xml)
                        End If
                    Next

                    xml = GetStationConfigurationXMLProfile(tl.HostID, String.Empty)

                    If (Not (xml.Contains("<StationConfiguration />"))) Then
                        config.Add(xml)
                    End If
                Next
            End If
        Catch ex As Exception
            TrackingLocationManager.LogIssue("Get Host Station Configuration XML", "e3", NotificationType.Errors, ex, String.Format("HostName: {0}", hostName))
        End Try

        Return config
    End Function
#End Region
#End Region

#Region "Configuration"
    <WebMethod(Description:="Retrieves Configuration", MessageName:="GetConfig")> _
    Public Function GetConfig(ByVal name As String, ByVal version As String, ByVal mode As Int32, ByVal type As Int32) As String
        Dim xml As String = String.Empty

        Try
            Dim verNum As New Version(version)
            xml = ConfigManager.GetConfig(Name, verNum, mode, type)
        Catch ex As Exception
            ConfigManager.LogIssue("GetConfig", "e3", NotificationType.Errors, ex, String.Format("Name: {0} Version: {1} Mode: {2} Type: {3}", Name, version.ToString(), mode, type))
        End Try

        Return xml
    End Function

    <WebMethod(Description:="Retrieves Configuration", MessageName:="GetConfigByNames")> _
    Public Function GetConfig(ByVal name As String, ByVal version As String, ByVal mode As String, ByVal type As String) As String
        Dim xml As String = String.Empty

        Try
            Dim verNum As New Version(version)
            Dim modeID As Int32 = LookupsManager.GetLookupID("ConfigModes", mode, Nothing)
            Dim typeID As Int32 = LookupsManager.GetLookupID("ConfigTypes", type, Nothing)

            xml = ConfigManager.GetConfig(Name, verNum, modeID, typeID)
        Catch ex As Exception
            ConfigManager.LogIssue("GetConfig", "e3", NotificationType.Errors, ex, String.Format("Name: {0} Version: {1} Mode: {2} Type: {3}", Name, version.ToString(), mode, type))
        End Try

        Return xml
    End Function

    <WebMethod(Description:="Saves Configuration", MessageName:="SaveConfig")> _
    Public Function SaveConfig(ByVal name As String, ByVal version As String, ByVal mode As Int32, ByVal type As Int32, ByVal definition As String) As Boolean
        Try
            Dim verNum As New Version(version)
            Return ConfigManager.SaveConfig(Name, verNum, mode, type, definition)
        Catch ex As Exception
            ConfigManager.LogIssue("SaveConfig", "e3", NotificationType.Errors, ex, String.Format("Name: {0} Version: {1} Mode: {2} Type: {3}", Name, version.ToString(), mode, type))
        End Try

        Return False
    End Function

    <WebMethod(Description:="Saves Configuration", MessageName:="SaveConfigByNames")> _
    Public Function SaveConfig(ByVal name As String, ByVal version As String, ByVal mode As String, ByVal type As String, ByVal definition As String) As Boolean
        Try
            Dim verNum As New Version(version)
            Dim modeID As Int32 = LookupsManager.GetLookupID("ConfigModes", mode, Nothing)
            Dim typeID As Int32 = LookupsManager.GetLookupID("ConfigTypes", type, Nothing)

            Return ConfigManager.SaveConfig(Name, verNum, modeID, typeID, definition)
        Catch ex As Exception
            ConfigManager.LogIssue("SaveConfig", "e3", NotificationType.Errors, ex, String.Format("Name: {0} Version: {1} Mode: {2} Type: {3}", Name, version.ToString(), mode, type))
        End Try

        Return False
    End Function

    <WebMethod(Description:="Clones Configuration", MessageName:="CloneConfigMode")> _
    Public Function CloneConfigMode(ByVal name As String, ByVal version As String, ByVal fromMode As Int32, ByVal type As Int32, ByVal toMode As Int32) As Boolean
        Dim publishSucceeded As Boolean = False

        Try
            Dim verNum As New Version(version)
            publishSucceeded = ConfigManager.CloneConfigMode(Name, verNum, fromMode, type, toMode)
        Catch ex As Exception
            ConfigManager.LogIssue("CloneConfigMode", "e3", NotificationType.Errors, ex, String.Format("Name: {0} Version: {1} From Mode: {2} Type: {3} To Mode: {4}", Name, version.ToString(), fromMode, type, toMode))
        End Try

        Return publishSucceeded
    End Function

    <WebMethod(Description:="Clones Configuration", MessageName:="CloneConfigModeByNames")> _
    Public Function CloneConfigMode(ByVal name As String, ByVal version As String, ByVal fromMode As String, ByVal type As String, ByVal toMode As String) As Boolean
        Dim publishSucceeded As Boolean = False

        Try
            Dim verNum As New Version(version)
            Dim fromModeID As Int32 = LookupsManager.GetLookupID("ConfigModes", fromMode, Nothing)
            Dim toModeID As Int32 = LookupsManager.GetLookupID("ConfigModes", toMode, Nothing)
            Dim typeID As Int32 = LookupsManager.GetLookupID("ConfigTypes", type, Nothing)

            publishSucceeded = ConfigManager.CloneConfigMode(Name, verNum, fromModeID, typeID, toModeID)
        Catch ex As Exception
            ConfigManager.LogIssue("CloneConfigMode", "e3", NotificationType.Errors, ex, String.Format("Name: {0} Version: {1} From Mode: {2} Type: {3} To Mode: {4}", Name, version.ToString(), fromMode, type, toMode))
        End Try

        Return publishSucceeded
    End Function

    <WebMethod(Description:="Clones Configuration", MessageName:="CloneConfigVersion")> _
    Public Function CloneConfigVersion(ByVal name As String, ByVal fromVersion As String, ByVal mode As Int32, ByVal type As Int32, ByVal toVersion As String) As Boolean
        Dim publishSucceeded As Boolean = False

        Try
            Dim fromVer As New Version(fromVersion)
            Dim toVer As New Version(toVersion)
            publishSucceeded = ConfigManager.CloneConfigVersion(Name, fromVer, mode, type, toVer)
        Catch ex As Exception
            ConfigManager.LogIssue("CloneConfigVersion", "e3", NotificationType.Errors, ex, String.Format("Name: {0} From Version: {1} Mode: {2} Type: {3} To Version: {4}", Name, fromVersion, mode, type, toVersion))
        End Try

        Return publishSucceeded
    End Function

    <WebMethod(Description:="Clones Configuration", MessageName:="CloneConfigVersionByNames")> _
    Public Function CloneConfigVersion(ByVal name As String, ByVal fromVersion As String, ByVal mode As String, ByVal type As String, ByVal toVersion As String) As Boolean
        Dim publishSucceeded As Boolean = False

        Try
            Dim fromVer As New Version(fromVersion)
            Dim toVer As New Version(toVersion)
            Dim modeID As Int32 = LookupsManager.GetLookupID("ConfigModes", mode, Nothing)
            Dim typeID As Int32 = LookupsManager.GetLookupID("ConfigTypes", type, Nothing)

            publishSucceeded = ConfigManager.CloneConfigVersion(Name, fromVer, modeID, typeID, toVer)
        Catch ex As Exception
            ConfigManager.LogIssue("CloneConfigVersion", "e3", NotificationType.Errors, ex, String.Format("Name: {0} From Version: {1} Mode: {2} Type: {3} To Version: {4}", Name, fromVersion, mode, type, toVersion))
        End Try

        Return publishSucceeded
    End Function
#End Region

#Region "Calibration/LossFile"
    <WebMethod(Description:="Retrieve Product/Station/Test Calibration/LossFile")> _
    Public Function GetAllCalibrationConfigurationXML(ByVal hostID As Int32, ByVal productID As Int32, ByVal testID As Int32) As CalibrationCollection
        Dim xml As New CalibrationCollection

        Try
            Return CalibrationManager.GetAllCalibrationConfigurationXML(productID, hostID, testID)
        Catch ex As Exception
            CalibrationManager.LogIssue("GetAllCalibrationConfigurationXML", "e3", NotificationType.Errors, ex, String.Format("HostID: {0} ProductID: {1} TestID: {2} ", hostID, productID, testID))
        End Try

        Return xml
    End Function

    <WebMethod(Description:="Returns whether this product, test and host has any calibration configuration.")> _
    Public Function HasCalibrationConfigurationXML(ByVal productID As Int32, ByVal hostID As Int32, ByVal testID As Int32) As Boolean
        Dim hasXML As Boolean = False
        Try
            hasXML = CalibrationManager.HasCalibrationConfigurationXML(productID, hostID, testID)
        Catch ex As Exception
            CalibrationManager.LogIssue("Calibration Manager HasCalibrationConfigurationXML", "e3", NotificationType.Errors, ex, String.Format("HostID: {0} ProductID: {1} TestID: {2} ", hostID, productID, testID))
        End Try

        Return hasXML
    End Function

    <WebMethod(Description:="Returns whether this product, test and host calibration configuration was saved correctly.")> _
    Public Function SaveCalibrationConfigurationXML(ByVal productID As Int32, ByVal hostID As Int32, ByVal testID As Int32, ByVal name As String, ByVal xml As String) As Boolean
        Dim saved As Boolean = False
        Try
            saved = CalibrationManager.SaveCalibrationConfigurationXML(productID, hostID, testID, name, xml)
        Catch ex As Exception
            CalibrationManager.LogIssue("Calibration Manager SaveCalibrationConfigurationXML", "e3", NotificationType.Errors, ex, String.Format("HostID: {0} ProductID: {1} TestID: {2} Name: {3}", hostID, productID, testID, name))
        End Try

        Return saved
    End Function
#End Region

#Region "Request"
    <WebMethod(EnableSession:=True, Description:="Gets The Fields Setup Definition")> _
    Public Function GetRequestFieldSetup(ByVal requestName As String, ByVal includeArchived As Boolean, ByVal requestNumber As String, ByVal useridentification As String) As RequestFieldsCollection
        Try
            If UserManager.SetUserToSession(useridentification) Then
                Return RequestManager.GetRequestFieldSetup(requestName, includeArchived, requestNumber)
            End If
        Catch ex As Exception
            RequestManager.LogIssue("GetRequestFieldSetup", "e3", NotificationType.Errors, ex, String.Format("RequestName: {0} IncludeArchived: {1} RequestNumber: {2} User: {3}", requestName, includeArchived, requestNumber, useridentification))
        End Try

        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Get the setup information for the batch for stage and test")> _
    Public Function GetBatchTestSetupInfo(ByVal batchID As Int32, ByVal jobID As Int32, ByVal productID As Int32, ByVal testStageType As Int32, ByVal blankSelected As Int32, ByVal useridentification As String, ByVal requestTypeID As Int32) As DataTable
        Try
            If UserManager.SetUserToSession(useridentification) Then
                Return RequestManager.GetRequestSetupInfo(productID, jobID, batchID, testStageType, blankSelected, requestTypeID, UserManager.GetCurrentUser.ID)
            End If
        Catch ex As Exception
            RequestManager.LogIssue("GetBatchTestSetupInfo", "e3", NotificationType.Errors, ex, String.Format("BatchID: {0} JobID: {1} ProductID: {2} TestStageType: {3} BlankSelected: {4}", batchID, jobID, productID, testStageType, blankSelected))
        End Try

        Return New DataTable("RequestSetupInfo")
    End Function

    <WebMethod(Description:="Saves the setup information for the batch for stage, test, TestStageType")> _
    Public Function SaveBatchTestSetupInfo(ByVal batchID As Int32, ByVal jobID As Int32, ByVal productID As Int32, ByVal testStageType As Int32, ByVal setupInfo As List(Of String)) As NotificationCollection
        Try
            Return RequestManager.SaveRequestSetupBatchOnly(productID, jobID, batchID, testStageType, setupInfo)
        Catch ex As Exception
            RequestManager.LogIssue("SaveBatchTestSetupInfo", "e1", NotificationType.Errors, ex, String.Format("BatchID: {0} JobID: {1} ProductID: {2} TestStageType: {3} BlankSelected: {4}", batchID, jobID, productID, testStageType))
        End Try

        Return New NotificationCollection()
    End Function

    <WebMethod(EnableSession:=True, Description:="Gets All RequestTypes Based On User")> _
    Public Function GetRequestTypes(ByVal userIdentification As String) As DataTable
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Return RequestManager.GetRequestTypes()
            End If
        Catch ex As Exception
            RequestManager.LogIssue("GetRequestTypes", "e3", NotificationType.Errors, ex, String.Format("User: {0}", userIdentification))
        End Try

        Return New DataTable("RequestTypes")
    End Function

    <WebMethod(EnableSession:=True, Description:="Save Raised Request")> _
    Public Function SaveRequest(ByVal requestName As String, ByRef request As RequestFieldsCollection, ByVal userIdentification As String) As Boolean
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Return RequestManager.SaveRequest(requestName, request, userIdentification, Nothing)
            End If
        Catch ex As Exception
            RequestManager.LogIssue("SaveRequest", "e1", NotificationType.Errors, ex, String.Format("RequestName: {0} User: {1}", requestName, userIdentification))
        End Try

        Return False
    End Function
#End Region

End Class