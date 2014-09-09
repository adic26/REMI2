Imports System.Web
Imports REMI.Bll
Imports REMI.BusinessEntities

Public Class REMIAuthModule
    Implements IHttpModule

    Public Sub Dispose() Implements IHttpModule.Dispose
    End Sub

    Public Sub Init(ByVal app As HttpApplication) Implements IHttpModule.Init
        '    AddHandler app.PreRequestHandlerExecute, AddressOf Me.PreRequestHandling 'this is the event immidately after the session object becomes available.
    End Sub

    'Private Sub PreRequestHandling(ByVal sender As Object, ByVal e As System.EventArgs)
    '    Dim httpApp As HttpApplication = DirectCast(sender, HttpApplication) 'get the http app

    '    If httpApp.Context.Request.Path.Contains("/Reports/ES/Default.aspx") Then
    '    ElseIf httpApp.Context.Request.Path.Contains(".aspx") Then
    '        If Not UserManager.SessionUserIsSet Then
    '            If httpApp.Context.Request.Path.ToLower <> "/badgeaccess/default.aspx" AndAlso httpApp.Context.Request.Path.ToLower <> "/badgeaccess/error.aspx" Then
    '                'we need to see if the current windows user can be set to the session.
    '                Dim currentUser As User = UserManager.GetCurrentUser()
    '                If currentUser IsNot Nothing Then
    '                    'do they need to scan their badge?
    '                    If currentUser.RequiresSuppAuth() Or currentUser.ID = 0 Then
    '                        httpApp.Context.Response.Redirect("~/BadgeAccess/Default.aspx", True)
    '                    Else
    '                        'ok just set the user to the session. This will prevent all this crap in the future
    '                        UserManager.SetUserToSession(currentUser)
    '                        'get the user to set their test center if they havent already. They will be hounded for this. 
    '                        'it's omportant to have this set given all the new labs coming online.
    '                        If String.IsNullOrEmpty(currentUser.TestCentre) AndAlso Not httpApp.Context.Request.Path.EndsWith("badgeaccess/EditmyUser.aspx") Then
    '                            httpApp.Context.Response.Redirect("~/badgeaccess/EditmyUser.aspx", True) 'if this user has not yet selected a test centre. make them do it!
    '                        Else
    '                            If httpApp.Context.Request.Path.ToLower = "/default.aspx" And Not (String.IsNullOrEmpty(currentUser.DefaultPage)) Then
    '                                httpApp.Context.Response.Redirect(String.Format("~{0}", currentUser.DefaultPage), True)
    '                            End If
    '                        End If
    '                    End If
    '                Else
    '                    'the user could not be identified via ldap/does not have access to remi.
    '                    httpApp.Context.Response.Redirect("~/BadgeAccess/Error.aspx", True)
    '                End If
    '            End If
    '        End If
    '    End If
    'End Sub
End Class