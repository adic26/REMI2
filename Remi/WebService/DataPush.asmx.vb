Imports System.Web.Services
Imports System.Web.Services.Protocols
Imports System.ComponentModel
Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports log4net
Imports REMI.Contracts
Imports System.Data
Imports System.Web.Script.Services

<System.Web.Services.WebService(Name:="DataPush", Namespace:="http://go/remi/")> _
<System.Web.Services.WebServiceBinding(ConformsTo:=WsiProfiles.BasicProfile1_1)> _
<ToolboxItem(False)> _
Public Class DataPush
    Inherits System.Web.Services.WebService

    <WebMethod(Description:="Upload XML File")> _
    Public Function UploadData(ByVal xml As String, ByVal lossFile As String, ByVal xsd As String) As Boolean
        Try
            Select Case xsd
                Case "urn:xmlns:relab.rim.com/ResultFile.xsd"
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
                Case "urn:xmlns:relab.rim.com/ResultFile.xsd"
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
    Public Function GetResults(ByVal requestNumber As String, ByVal testIDs As String, ByVal testStageName As String, ByVal unitNumber As Int32) As DataTable
        Try
            Return RelabManager.GetResults(requestNumber, testIDs, testStageName, unitNumber)
        Catch ex As Exception
            RelabManager.LogIssue("GetResults", "e3", NotificationType.Errors, ex)
        End Try
        Return New DataTable("Results")
    End Function

    <WebMethod(EnableSession:=True, Description:="Modify a result")> _
    Public Function ModifyResult(ByVal value As String, ByVal ID As Int32, ByVal passFailOverride As Boolean, ByVal currentPassFail As Boolean, ByVal passFailText As String, ByVal userIdentification As String) As Boolean
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Return RelabManager.ModifyResult(value, ID, passFailOverride, currentPassFail, passFailText, userIdentification)
            End If
        Catch ex As Exception
            RelabManager.LogIssue("ModifyResult", "e3", NotificationType.Errors, ex)
        End Try
        Return False
    End Function

    <WebMethod(Description:="Poll Unprocessed Results")> _
    Public Function PollUnProcessedResults(ByVal requestNumber As String, ByVal unit As Int32, ByVal testStageName As String, ByVal testName As String) As Boolean
        Try
            Return RelabManager.PollUnProcessedResults(requestNumber, unit, testStageName, testName)
        Catch ex As Exception
            RelabManager.LogIssue("PollUnProcessedResults", "e3", NotificationType.Errors, ex)
        End Try

        Return False
    End Function
End Class