Imports System.Web

Namespace REMI.Core
    Public Class REMIHttpContext

        Public Shared Function GetCurrentHostname() As String
            Dim currentIP As String = System.Web.HttpContext.Current.Request.ServerVariables("remote_addr")
            Return REMI.Core.REMIWebLinks.ResolveHostName(currentIP)
        End Function

        Public Shared Function GetBrowswer() As String()
            Dim browserInfo(6) As String
            If (Not (System.Web.HttpContext.Current.Request.Browser Is Nothing)) Then
                browserInfo(0) = String.Format("Browser: {0}", System.Web.HttpContext.Current.Request.Browser.Browser.ToString())
                browserInfo(1) = String.Format("Version: {0}", System.Web.HttpContext.Current.Request.Browser.Version)
                browserInfo(2) = String.Format("Supports Cookies: {0}", System.Web.HttpContext.Current.Request.Browser.Cookies)
                browserInfo(3) = String.Format("Supports JavaScript: {0}", System.Web.HttpContext.Current.Request.Browser.EcmaScriptVersion.ToString())
                browserInfo(4) = String.Format("IsMobileDevice: {0}", System.Web.HttpContext.Current.Request.Browser.IsMobileDevice.ToString())
                browserInfo(5) = String.Format("Host: {0}", System.Web.HttpContext.Current.Request.Url.Host)
                browserInfo(6) = String.Format("Full URL: {0}", System.Web.HttpContext.Current.Request.Url.AbsoluteUri)
                Return browserInfo
            Else
                Return Nothing
            End If
        End Function
    End Class
End Namespace