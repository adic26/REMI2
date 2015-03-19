Imports System.Configuration

Namespace RemiTimedService
    Public Class Helpers
        Public Shared Sub SendMail(ByVal subject As String, ByVal message As String)
            Try
                remi.GetInstance.SendMail(ConfigurationManager.AppSettings("DestinationEmails").ToString(), ConfigurationManager.AppSettings("FromEmail").ToString(), subject, message)
            Catch ex As Exception

            End Try
        End Sub
    End Class
End Namespace