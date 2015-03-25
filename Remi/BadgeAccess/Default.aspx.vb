Imports Remi.Bll
Imports Remi.BusinessEntities
Imports Remi.Core

Partial Class BadgeAccess_Default
    Inherits System.Web.UI.Page

#Region "Load"
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        txtBadge.Focus()
    End Sub
#End Region

#Region "Methods"
    Private Function GetRedirectPage() As String
        If Request.QueryString.Item("RedirectPage") IsNot Nothing Then
            Return Request.QueryString.Get("RedirectPage")
        Else
            Return REMIConfiguration.DefaultRedirectPage
        End If
    End Function
#End Region

#Region "Button Events"
    Protected Sub btnCreate_Click(sender As Object, e As EventArgs)
        mvLogin.ActiveViewIndex = 1
        btnlogin.Visible = True
        btnCreate.Visible = False
    End Sub

    Protected Sub btnLogin_Click(sender As Object, e As EventArgs)
        mvLogin.ActiveViewIndex = 0
        btnCreate.Visible = True
        btnlogin.Visible = False
    End Sub

    Protected Sub btnNewUser_Click(sender As Object, e As EventArgs)
        If (Not String.IsNullOrEmpty(txtNewUserName.Text)) Then
            Dim badge As Int32 = 0
            Int32.TryParse(txtNewBadge.Text, badge)
            notMain.Notifications = UserManager.ConfirmUserCredentialsAndSave(txtNewUserName.Text.ToLower, txtNewPassword.Text, badge, ddlGeoLoc.SelectedValue, True, ddlDepartments.SelectedValue)

            If (Not notMain.Notifications.HasErrors) Then
                If UserManager.SetUserToSession(txtNewUserName.Text) Then
                    Response.Redirect(GetRedirectPage)
                End If
            End If
        End If

        txtNewBadge.Text = String.Empty
        txtNewPassword.Text = String.Empty
        txtNewUserName.Text = String.Empty
    End Sub

    Protected Sub btnReturn_Click(sender As Object, e As EventArgs)
        If (Not String.IsNullOrEmpty(txtBadge.Text)) Then
            If (UserManager.UserExists(String.Empty, txtBadge.Text)) Then
                If UserManager.SetUserToSession(txtBadge.Text) Then
                    Response.Redirect(GetRedirectPage)
                End If
            Else
                mvLogin.ActiveViewIndex = 1
            End If
        ElseIf Not String.IsNullOrEmpty(txtUserName.Text) Then
            If (UserManager.UserExists(txtUserName.Text, 0)) Then
                If UserManager.SetUserToSession(txtUserName.Text) Then
                    Response.Redirect(GetRedirectPage)
                End If
            Else
                mvLogin.ActiveViewIndex = 1
                btnCreate.Visible = False
                btnlogin.Visible = True
            End If
        End If
    End Sub
#End Region
End Class
