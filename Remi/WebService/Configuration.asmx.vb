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

' To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line.
' <System.Web.Script.Services.ScriptService()> _
<System.Web.Services.WebService(Name:="Configuration", Namespace:="http://go/remi/")> _
<System.Web.Services.WebServiceBinding(ConformsTo:=WsiProfiles.BasicProfile1_1)> _
<ToolboxItem(False)> _
Public Class ProductConfiguration
    Inherits System.Web.Services.WebService

#Region "Product"
    <WebMethod(Description:="Retrieve Product Test Configuration")> _
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
            ProductGroupManager.LogIssue("Product Group Manager GetProductConfigurationXML", "e3", NotificationType.Errors, ex)
        End Try
        Return xml
    End Function

    <WebMethod(Description:="Returns whether this product and test has any product configuration.")> _
    Public Function HasProductConfigurationXML(ByVal productID As Int32, ByVal testID As Int32) As Boolean
        Dim hasXML As Boolean = False
        Try
            hasXML = ProductGroupManager.HasProductConfigurationXML(productID, testID, String.Empty)
        Catch ex As Exception
            ProductGroupManager.LogIssue("Product Group Manager HasProductConfigurationXML", "e3", NotificationType.Errors, ex)
        End Try
        Return hasXML
    End Function

    <WebMethod(Description:="Retrieve Product Test Configuration By Name")> _
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
            ProductGroupManager.LogIssue("Product Group Manager GetProductConfigurationXMLByName", "e3", NotificationType.Errors, ex)
        End Try
        Return xml
    End Function

    <WebMethod(Description:="Returns whether this product and test has any product configuration.")> _
    Public Function HasProductConfigurationXMLByName(ByVal productID As Int32, ByVal testID As Int32, ByVal name As String) As Boolean
        Dim hasXML As Boolean = False
        Try
            hasXML = ProductGroupManager.HasProductConfigurationXML(productID, testID, name)
        Catch ex As Exception
            ProductGroupManager.LogIssue("Product Group Manager HasProductConfigurationXMLByName", "e3", NotificationType.Errors, ex)
        End Try
        Return hasXML
    End Function

    <WebMethod(Description:="Returns all product/test config seperated by the name of the configuration")> _
    Public Function GetProductConfigurationXMLCombined(ByVal productID As Int32, ByVal testID As Int32) As String
        Dim xml As String = String.Empty
        Try
            xml = ProductGroupManager.GetProductConfigurationXMLCombined(productID, testID).ToString()
        Catch ex As Exception
            ProductGroupManager.LogIssue("Product Group Manager GetProductConfigurationXMLCombined", "e3", NotificationType.Errors, ex)
        End Try
        Return xml
    End Function

    <WebMethod(Description:="Returns whether this product and test has any product configurations.")> _
    Public Function GetAllProductConfigurationXMLs(ByVal productID As Int32, ByVal testID As Int32, ByVal loadVersions As Boolean) As ProductConfigCollection
        Try
            Return ProductGroupManager.GetAllProductConfigurationXMLs(productID, testID, loadVersions)
        Catch ex As Exception
            ProductGroupManager.LogIssue("Product Group Manager GetAllProductConfigurationXMLs", "e3", NotificationType.Errors, ex)
        End Try

        Return New ProductConfigCollection
    End Function
#End Region

#Region "Station"
    <WebMethod(Description:="Retrieve Station Configuration")> _
    Public Function GetStationConfigurationXML(ByVal hostID As Int32) As String
        Dim xml As String = String.Empty
        Try
            xml = GetStationConfigurationXMLProfile(hostID, String.Empty).ToString()
        Catch ex As Exception
            TrackingLocationManager.LogIssue("Get Host Station Configuration XML", "e3", NotificationType.Errors, ex)
        End Try
        Return xml
    End Function

    <WebMethod(Description:="Retrieve Station Configuration Based on Profile")> _
    Public Function GetStationConfigurationXMLProfile(ByVal hostID As Int32, ByVal profileName As String) As String
        Dim xml As String = String.Empty
        Try
            xml = TrackingLocationManager.GetStationConfigurationXML(hostID, profileName).ToString()
        Catch ex As Exception
            TrackingLocationManager.LogIssue("Get Host Station Configuration XML", "e3", NotificationType.Errors, ex)
        End Try
        Return xml
    End Function

    <WebMethod(Description:="Retrieve Multiple Station Configuration By HostName")> _
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
            TrackingLocationManager.LogIssue("Get Host Station Configuration XML", "e3", NotificationType.Errors, ex)
        End Try

        Return config
    End Function
#End Region

#Region "Calibration/LossFile"
    <WebMethod(Description:="Retrieve Product/Station/Test Calibration/LossFile")> _
    Public Function GetAllCalibrationConfigurationXML(ByVal hostID As Int32, ByVal productID As Int32, ByVal testID As Int32) As CalibrationCollection
        Dim xml As New CalibrationCollection

        Try
            Return CalibrationManager.GetAllCalibrationConfigurationXML(productID, hostID, testID)
        Catch ex As Exception
            CalibrationManager.LogIssue("GetAllCalibrationConfigurationXML", "e3", NotificationType.Errors, ex)
        End Try

        Return xml
    End Function

    <WebMethod(Description:="Returns whether this product, test and host has any calibration configuration.")> _
    Public Function HasCalibrationConfigurationXML(ByVal productID As Int32, ByVal hostID As Int32, ByVal testID As Int32) As Boolean
        Dim hasXML As Boolean = False
        Try
            hasXML = CalibrationManager.HasCalibrationConfigurationXML(productID, hostID, testID)
        Catch ex As Exception
            CalibrationManager.LogIssue("Calibration Manager HasCalibrationConfigurationXML", "e3", NotificationType.Errors, ex)
        End Try

        Return hasXML
    End Function

    <WebMethod(Description:="Returns whether this product, test and host calibration configuration was saved correctly.")> _
    Public Function SaveCalibrationConfigurationXML(ByVal productID As Int32, ByVal hostID As Int32, ByVal testID As Int32, ByVal name As String, ByVal xml As String) As Boolean
        Dim saved As Boolean = False
        Try
            saved = CalibrationManager.SaveCalibrationConfigurationXML(productID, hostID, testID, name, xml)
        Catch ex As Exception
            CalibrationManager.LogIssue("Calibration Manager SaveCalibrationConfigurationXML", "e3", NotificationType.Errors, ex)
        End Try

        Return saved
    End Function
#End Region

#Region "Request"
    <WebMethod(Description:="Gets The Fields Setup Definition")> _
    Public Function GetRequestFieldSetup(ByVal requestName As String, ByVal includeArchived As Boolean, ByVal requestNumber As String) As RequestFieldsCollection
        Try
            Return RequestManager.GetRequestFieldSetup(requestName, includeArchived, requestNumber)
        Catch ex As Exception
            RequestManager.LogIssue("GetRequestFieldSetup", "e3", NotificationType.Errors, ex)
        End Try

        Return Nothing
    End Function

    <WebMethod(Description:="Get the setup information for the batch for stage and test")> _
    Public Function GetBatchTestSetupInfo(ByVal batchID As Int32, ByVal jobID As Int32, ByVal productID As Int32, ByVal testStageType As Int32, ByVal blankSelected As Int32) As DataTable
        Try
            Return RequestManager.GetRequestSetupInfo(productID, jobID, batchID, testStageType, blankSelected)
        Catch ex As Exception
            RequestManager.LogIssue("GetBatchTestSetupInfo", "e3", NotificationType.Errors, ex)
        End Try

        Return New DataTable("RequestSetupInfo")
    End Function

    <WebMethod(EnableSession:=True, Description:="Gets All RequestTypes Based On User")> _
    Public Function GetRequestTypes(ByVal userIdentification As String) As List(Of String)
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Return RequestManager.GetRequestTypes()
            End If
        Catch ex As Exception
            RequestManager.LogIssue("GetRequestTypes", "e3", NotificationType.Errors, ex)
        End Try

        Return New List(Of String)
    End Function
#End Region

End Class