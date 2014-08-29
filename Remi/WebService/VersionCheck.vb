Imports System.Web
Imports System.Web.Services
Imports System.Web.Services.Protocols
Imports log4net
Imports System.ComponentModel
Imports REMI.Bll
Imports REMI.Validation

<System.Web.Services.WebService(Name:="VersionCheck", Namespace:="http://go/remi/")> _
<System.Web.Services.WebServiceBinding(ConformsTo:=WsiProfiles.BasicProfile1_1)> _
<ToolboxItem(False)> _
Public Class VersionCheck
    Inherits System.Web.Services.WebService

    <WebMethod(Description:="Compares Version to Latest Version")> _
    Public Function CheckVersion(ByVal application As String, ByVal versionNumber As String) As Int32
        Try
            Return VersionManager.CheckVersion(application, versionNumber)
        Catch ex As Exception
            VersionManager.LogIssue("Version Manager CheckVersion", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function

    <WebMethod(Description:="Get the config XML version that works with product/test/versionNumber")> _
    Public Function GetProductConfigXMLByAppVersion(ByVal application As String, ByVal versionNumber As String, ByVal productID As Int32, ByVal testID As Int32, ByVal pcName As String) As String
        Try
            Dim pcvID As Int32 = VersionManager.GetProductConfigXMLByAppVersion(application, versionNumber, productID, testID, pcName)
            Return ProductGroupManager.GetProductConfigurationXMLVersion(pcvID).ToString()
        Catch ex As Exception
            VersionManager.LogIssue("Version Manager ApplicableConfigForVersionByProductTest", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
    End Function
End Class