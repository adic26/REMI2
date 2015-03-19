Imports System.Configuration

Namespace RemiTimedService
    Public Class Helpers
        Public Shared Sub SendMail(ByVal subject As String, ByVal message As String)
            remi.GetInstance.SendMail(ConfigurationManager.AppSettings("DestinationEmails").ToString(), ConfigurationManager.AppSettings("FromEmail").ToString(), subject, message)
        End Sub
    End Class
End Namespace