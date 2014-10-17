Imports System.Web.Services
Imports System.Web.Services.Protocols
Imports System.ComponentModel
Imports Remi.Bll
Imports Remi.Validation
Imports System.Xml.XPath
Imports System.IO
Imports System.Xml
Imports System.Configuration

' To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line.
' <System.Web.Script.Services.ScriptService()> _
<System.Web.Services.WebService(Name:="DataPush", Namespace:="http://go/remi/")> _
<System.Web.Services.WebServiceBinding(ConformsTo:=WsiProfiles.BasicProfile1_1)> _
<ToolboxItem(False)> _
Public Class DataPush
    Inherits System.Web.Services.WebService

    <WebMethod(Description:="Upload XML File")> _
    Public Function UploadData(ByVal xml As String, ByVal lossFile As String, ByVal xsd As String) As Boolean
        Try
            Select Case xsd
                Case "urn:xmlns:relab.rim.com/ResultFile.xsd", "relab.rim.com/ResultFile.xsd", "TsdLib.ResultsFile.xsd"
                    Return RelabManager.UploadResults(xml, lossFile)
            End Select
        Catch ex As Exception
            RelabManager.LogIssue("UploadData", "e3", NotificationType.Errors, ex)
        End Try
        Return False
    End Function

    <WebMethod(Description:="Upload Image File")> _
    Public Function UploadDataImageFile(ByVal file() As Byte, ByVal contentType As String, ByVal fileName As String, ByVal xsd As String) As Boolean
        Try
            Select Case xsd
                Case "urn:xmlns:relab.rim.com/ResultFile.xsd", "relab.rim.com/ResultFile.xsd", "TsdLib.ResultsFile.xsd"
                    Return RelabManager.UploadResultsMeasurementsFile(file, contentType, fileName)
            End Select
        Catch ex As Exception
            RelabManager.LogIssue("UploadDataImageFile", "e3", NotificationType.Errors, ex)
        End Try
        Return False
    End Function

    <WebMethod(EnableSession:=True, Description:="Sends an email via smtp. Comma delimit destinations.")> _
    Public Sub SendMail(ByVal destinations As String, ByVal sender As String, ByVal subject As String, ByVal messageBody As String)
        Try
            REMI.Core.Emailer.SendMail(destinations, sender, subject, messageBody, False)
        Catch ex As Exception
            UserManager.LogIssue("Email could not be sent via API.", "e3", NotificationType.Errors, ex, "Dest: " + destinations + "Sender: " + sender)
        End Try
    End Sub

    <WebMethod(Description:="Get All Results For A Request Based On A Test")> _
    Public Function GetResults(ByVal requestNumber As String, ByVal testName As String) As DataTable
        Try
            Return RelabManager.GetResults(requestNumber, testName)
        Catch ex As Exception
            RelabManager.LogIssue("GetResults", "e3", NotificationType.Errors, ex)
        End Try
        Return New DataTable("Results")
    End Function

    <WebMethod(Description:="Modify a result")> _
    Public Function ModifyResult(ByVal value As String, ByVal ID As Int32, ByVal passFailOverride As Boolean, ByVal currentPassFail As Boolean, ByVal passFailText As String, ByVal userIdentification As String) As Boolean
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                RelabManager.ModifyResult(value, ID, passFailOverride, currentPassFail, passFailText, userIdentification)
            End If
        Catch ex As Exception
            RelabManager.LogIssue("ModifyResult", "e3", NotificationType.Errors, ex)
        End Try
        Return False
    End Function
End Class