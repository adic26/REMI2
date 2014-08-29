<%@ Application Language="VB" %>

<script runat="server">
    Sub Application_Start(ByVal sender As Object, ByVal e As EventArgs)
        ConfigureLogging()
    End Sub
        
    Sub Application_Error(ByVal sender As Object, ByVal e As EventArgs)
        LogUnhandledException(HttpContext.Current.Server.GetLastError())
    End Sub

    Protected Sub LogUnhandledException(ByVal ex As Exception)
        REMI.Bll.REMIManagerBase.LogIssue(HttpContext.Current.Request.RawUrl, "f1", REMI.Validation.NotificationType.Fatal, ex)
        
        If (ex.InnerException IsNot Nothing) Then
            If (ex.Message <> ex.InnerException.Message) Then
                ex = ex.InnerException
                REMI.Bll.REMIManagerBase.LogIssue(HttpContext.Current.Request.RawUrl, "f1", REMI.Validation.NotificationType.Fatal, ex)
            End If
        End If
    End Sub
    
    Protected Sub ConfigureLogging()
        Dim logConfigFile As String = Server.MapPath("./") + "log4net.config"
        
        If (System.IO.File.Exists(logConfigFile)) Then
            log4net.Config.XmlConfigurator.ConfigureAndWatch(New System.IO.FileInfo(logConfigFile))
        End If
    End Sub
</script>