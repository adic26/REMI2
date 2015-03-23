Imports System.Configuration

Namespace RemiTimedService
    Public Class Helpers
        Public Shared Sub SendMail(ByVal subject As String, ByVal message As String)
            Try
                DBControl.Helpers.Notify.SendNofitication(ConfigurationManager.AppSettings("DestinationEmails").ToString(), ConfigurationManager.AppSettings("FromEmail").ToString(), subject, message, True, String.Empty)
            Catch ex As Exception
            End Try
        End Sub
    End Class
End Namespace