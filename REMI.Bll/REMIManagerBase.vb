Imports REMI.BusinessEntities
Imports log4net
Imports REMI.Validation
Imports REMI.Core
Imports System.Web

Namespace REMI.Bll
    Public Class REMIManagerBase
        Protected Shared Log As log4net.ILog = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType)
        Private Shared Function GetLog4NetMessage(ByVal errNote As Notification, ByVal propertyname As String, ByVal errorCode As String) As String
            Dim log4netMessage As New Text.StringBuilder
            log4netMessage.Append("User: ")

            If errorCode.ToLower = "e22" Then 'if getting the user name is causing the exception we dont want it to loop so just use the current windows user
                log4netMessage.Append(UserManager.GetCleanedHttpContextCurrentUserName)
            Else
                log4netMessage.Append(UserManager.GetCurrentValidUserLDAPName)
            End If

            log4netMessage.Append(vbCrLf)
            log4netMessage.Append("Users Machine Name: ")
            log4netMessage.Append(REMI.Core.REMIHttpContext.GetCurrentHostname)

            log4netMessage.Append(vbCrLf)
            log4netMessage.Append("Property or Method: ")
            log4netMessage.Append(errNote.PropertyName)
            log4netMessage.Append(vbCrLf)
            log4netMessage.Append("Level: ")
            log4netMessage.Append(errNote.Type.ToString)
            log4netMessage.Append(vbCrLf)
            log4netMessage.Append("Error Code: ")
            log4netMessage.Append(errNote.ErrorCode)
            log4netMessage.Append(vbCrLf)
            log4netMessage.Append("Error Message: ")
            log4netMessage.Append(errNote.Message)
            log4netMessage.Append(vbCrLf)
            log4netMessage.Append("Additional Information: ")
            log4netMessage.AppendLine(errNote.AdditionalInformation)

            Dim browserInfo As String() = REMI.Core.REMIHttpContext.GetBrowswer

            If (Not (browserInfo Is Nothing)) Then
                For i = 0 To browserInfo.Length - 1
                    log4netMessage.AppendLine(browserInfo(i))
                Next
            End If

            For Each key As String In HttpContext.Current.Request.Form.AllKeys
                If (Not (key.Contains("__VIEWSTATE")) And Not (key.Contains("__EVENTVALIDATION"))) Then
                    log4netMessage.AppendLine(String.Format("{0}: {1}", key, HttpContext.Current.Request.Form(key)))
                End If
            Next

            Return log4netMessage.ToString
        End Function
        Public Shared Function LogIssue(ByVal PropertyName As String, ByVal errorCode As String, ByVal level As NotificationType, ByVal ex As Exception, Optional ByVal additionalInformation As String = "") As Notification
            Dim errNote As Notification
            Try
                errNote = New Notification(PropertyName, errorCode, level, additionalInformation)
                Dim eMsg As String = GetLog4NetMessage(errNote, PropertyName, errorCode)
                Select Case level
                    Case NotificationType.Errors
                        Log.Error(eMsg, ex)
                    Case NotificationType.Information
                        Log.Info(eMsg, ex)
                    Case NotificationType.Warning
                        Log.Warn(eMsg, ex)
                    Case NotificationType.Fatal
                        Log.Fatal(eMsg, ex)
                    Case NotificationType.Debug
                        Log.Debug(eMsg, ex)
                End Select
                Emailer.SendErrorEMail(errNote.Message, eMsg, level, ex)
            Catch
                errNote = New Notification("LogIssue Method", "f1", NotificationType.Fatal, "The system failed to log an error")
            End Try
            Return errNote
        End Function
        Public Shared Function LogIssue(ByVal PropertyName As String, ByVal errorCode As String, ByVal level As NotificationType, Optional ByVal additionalInformation As String = "") As Notification
            Dim errNote As New Notification(PropertyName, errorCode, level, additionalInformation)
            Dim eMsg As String = GetLog4NetMessage(errNote, PropertyName, errorCode)

            Select Case level
                Case NotificationType.Errors
                    Log.Error(eMsg)
                Case NotificationType.Information
                    Log.Info(eMsg)
                Case NotificationType.Warning
                    Log.Warn(eMsg)
                Case NotificationType.Fatal
                    Log.Fatal(eMsg)
                Case NotificationType.Debug
                    Log.Debug(eMsg)
            End Select
            Emailer.SendErrorEMail(errNote.Message, eMsg, level, Nothing)
            Return errNote
        End Function
    End Class
End Namespace