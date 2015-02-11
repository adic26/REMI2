<%@ Application Language="VB" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="REMI.BusinessEntities" %>
<%@ Import Namespace="REMI.Bll" %>
<%@ Import Namespace="REMI.Core" %>

<script RunAt="server">
    Sub Application_Start(ByVal sender As Object, ByVal e As EventArgs)
        ConfigureLogging()
    End Sub
        
    Sub Application_Error(ByVal sender As Object, ByVal e As EventArgs)
        Dim ex As Exception = HttpContext.Current.Server.GetLastError()
        
        If (Not REMIConfiguration.Debug) Then
            If (ex.GetType().Name = "HttpException") Then
                If (DirectCast(ex, HttpException).GetHttpCode() = "404") Then
                    Response.Redirect("~/")
                Else
                    LogUnhandledException(ex)
                End If
            End If
        End If
    End Sub
    
    Sub Application_AuthenticateRequest(ByVal sender As Object, ByVal e As EventArgs)
    End Sub
    
    Sub RequestHandlerExecute(ByVal sender As Object, ByVal e As EventArgs) Handles Me.PreRequestHandlerExecute
        Dim httpApp As HttpApplication = DirectCast(sender, HttpApplication) 'get the http app

        If httpApp.Context.Request.Path.Contains("/Reports/ES/Default.aspx") Then
        ElseIf httpApp.Context.Request.Path.Contains(".aspx") Then
            If Not UserManager.SessionUserIsSet Then
                If httpApp.Context.Request.Path.ToLower <> "/badgeaccess/default.aspx" AndAlso httpApp.Context.Request.Path.ToLower <> "/badgeaccess/error.aspx" Then
                    'we need to see if the current windows user can be set to the session.
                    Dim currentUser As User = UserManager.GetCurrentUser()
                    
                    If currentUser IsNot Nothing Then
                        'do they need to scan their badge?
                        If currentUser.RequiresSuppAuth() Or currentUser.ID = 0 Then
                            httpApp.Context.Response.Redirect("~/BadgeAccess/Default.aspx", True)
                        Else
                            'ok just set the user to the session. This will prevent all this crap in the future
                            UserManager.SetUserToSession(currentUser)
                            'get the user to set their test center if they havent already. They will be hounded for this. 
                            'it's omportant to have this set given all the new labs coming online.
                            If String.IsNullOrEmpty(currentUser.TestCentre) AndAlso String.IsNullOrEmpty(currentUser.Department) AndAlso Not httpApp.Context.Request.Path.EndsWith("badgeaccess/EditmyUser.aspx") Then
                                httpApp.Context.Response.Redirect("~/badgeaccess/EditmyUser.aspx?defaults=false", True)
                            Else
                                If httpApp.Context.Request.Path.ToLower = "/default.aspx" And Not (String.IsNullOrEmpty(currentUser.DefaultPage)) Then
                                    httpApp.Context.Response.Redirect(String.Format("~{0}", currentUser.DefaultPage), True)
                                End If
                            End If
                        End If
                    Else
                        'the user could not be identified via ldap/does not have access to remi.
                        httpApp.Context.Response.Redirect("~/BadgeAccess/Error.aspx", True)
                    End If
                End If
            Else
                If String.IsNullOrEmpty(UserManager.GetCurrentUser().TestCentre) AndAlso String.IsNullOrEmpty(UserManager.GetCurrentUser().Department) AndAlso Not httpApp.Context.Request.Path.EndsWith("badgeaccess/EditmyUser.aspx") Then
                    httpApp.Context.Response.Redirect("~/badgeaccess/EditmyUser.aspx?defaults=false", True)
                End If
            End If
            
            If (UserManager.GetCurrentUser() IsNot Nothing) Then
                If (REMIAppCache.GetMenuAccess(UserManager.GetCurrentUser.DepartmentID) Is Nothing) Then
                    REMIAppCache.SetMenuAccess(UserManager.GetCurrentUser.DepartmentID, SecurityManager.GetMenuAccessByDepartment(String.Empty, UserManager.GetCurrentUser.DepartmentID))
                End If
                
                Dim dtMenuAccess As DataTable = REMIAppCache.GetMenuAccess(UserManager.GetCurrentUser.DepartmentID)
                
                If ((From m As DataRow In dtMenuAccess.Rows Where m.Field(Of String)("Url").ToLower.Contains(httpApp.Context.Request.Path.ToLower) Select m).FirstOrDefault() Is Nothing) Then
                    
                    If ((From m As DataRow In SecurityManager.GetMenu().Rows Where m.Field(Of String)("Url").ToLower.Contains(httpApp.Context.Request.Path.ToLower) Select m).FirstOrDefault() IsNot Nothing) Then
                        httpApp.Context.Response.Redirect("~/badgeaccess/EditmyUser.aspx", True)
                    End If
                End If
            End If
        ElseIf httpApp.Context.Request.Path.ToLower.Contains("/requests/") Then
            Dim paths As String() = httpApp.Context.Request.Path.ToString().Split(New [Char]() {"/"c}, System.StringSplitOptions.RemoveEmptyEntries)
            
            If (paths.Count = 2) Then
                If (paths(1).Contains("-")) Then
                    Dim reqSplit As String() = paths(1).Split(New [Char]() {"-"c}, System.StringSplitOptions.RemoveEmptyEntries)
                    httpApp.Context.Response.Redirect(String.Format("~/Request/Request.aspx?type={0}&req={1}", reqSplit(0), paths(1).ToUpper), True)
                Else
                    httpApp.Context.Response.Redirect(String.Format("~/Request/Default.aspx?rt={0}", paths(1).ToUpper), True)
                End If
            Else
                httpApp.Context.Response.Redirect("~/Request/Default.aspx", True)
            End If
        End If
    End Sub

    Protected Sub LogUnhandledException(ByVal ex As Exception)
        REMIManagerBase.LogIssue(HttpContext.Current.Request.RawUrl, "f1", REMI.Validation.NotificationType.Fatal, ex)
        
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
