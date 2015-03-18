Imports System.Net.Mail
Imports System.Text
Imports REMI.Validation
Namespace REMI.Core
    Public Class Emailer
        Private Shared smtp As New SmtpClient(REMIConfiguration.SmtpAddress, 25)

        Public Shared Function SendErrorEMail(ByVal subject As String, ByVal ErrorText As String, ByVal ErrorLevel As NotificationType, ByVal ex As Exception) As Boolean
            Dim strBuild As New Text.StringBuilder
            strBuild.Append(ErrorText)
            strBuild.Append(Environment.NewLine)
            strBuild.Append(Environment.NewLine)

            If ex IsNot Nothing Then
                strBuild.Append(ex.Message)
                strBuild.Append(Environment.NewLine)
                strBuild.Append(Environment.NewLine)
                strBuild.Append(ex.StackTrace)
                strBuild.Append(Environment.NewLine)

                While (ex.InnerException IsNot Nothing)
                    ex = ex.InnerException
                    strBuild.Append(ex.Message)
                    strBuild.Append(Environment.NewLine)
                    strBuild.Append(Environment.NewLine)
                    strBuild.Append(ex.StackTrace)
                End While
            End If

            Dim msg As New MailMessage("WebSiteNotifications@blackberry.com", "remi@blackberry.com", subject, strBuild.ToString)

            If ErrorLevel = NotificationType.Fatal Then
                msg.Priority = MailPriority.High
                'send another msg directly to my inbox
                msg.CC.Add(New MailAddress("tsdinfrastructure@blackberry.com"))
            End If

            Try
                smtp.Send(msg)
                Return True
            Catch
                'this NEEDS to fail without raising an exception. It would loop errors infinitely otherwise.
                Return False
            End Try
        End Function
        
        ''' <summary>
        ''' sends an email
        ''' </summary>
        ''' <param name="destinations">comma delim</param>
        ''' <param name="sender">single address</param>
        ''' <param name="subject"></param>
        ''' <param name="messageBody">plain text</param>
        ''' <remarks></remarks>
        Public Shared Sub SendMail(ByVal destinations As String, ByVal sender As String, ByVal subject As String, ByVal messageBody As String, ByVal isBodyHTML As Boolean)
            Dim addresses() As String = destinations.Split(New [Char]() {","c}, StringSplitOptions.RemoveEmptyEntries)
            Dim m As New MailMessage

            For Each s As String In addresses
                If (Not s.Contains("@blackberry.com")) Then
                    s += "@blackberry.com"
                End If

                m.To.Add(New MailAddress(s))
            Next

            m.IsBodyHtml = isBodyHTML

            m.From = New MailAddress(sender)
            m.Subject = subject
            m.Body = messageBody

            smtp.Send(m)
        End Sub

        Public Shared Sub SendMail(ByVal cc As String, ByVal sender As String, ByVal subject As String, ByVal messageBody As String, ByVal isBodyHTML As Boolean, ByVal bcc As String)
            Dim ccs() As String = cc.Split(New [Char]() {","c}, StringSplitOptions.RemoveEmptyEntries)
            Dim bccs() As String = bcc.Split(New [Char]() {","c}, StringSplitOptions.RemoveEmptyEntries)

            Dim m As New MailMessage

            For Each s As String In ccs
                If (Not s.Contains("@blackberry.com")) Then
                    s += "@blackberry.com"
                End If

                m.To.Add(New MailAddress(s))
            Next

            For Each b As String In bccs
                If (Not b.Contains("@blackberry.com")) Then
                    b += "@blackberry.com"
                End If

                m.Bcc.Add(New MailAddress(b))
            Next

            m.IsBodyHtml = isBodyHTML

            m.From = New MailAddress(sender)
            m.Subject = subject
            m.Body = messageBody

            smtp.Send(m)
        End Sub
    End Class
End Namespace