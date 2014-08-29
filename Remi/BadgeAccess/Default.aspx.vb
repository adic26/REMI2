Imports Remi.Bll
Imports Remi.BusinessEntities
Imports Remi.Core

Partial Class BadgeAccess_Default
    Inherits System.Web.UI.Page
    ''' <summary>
    ''' This method executes for a badge scan.
    ''' </summary>
    ''' <param name="sender"></param>
    ''' <param name="e"></param>
    ''' <remarks></remarks>
    Protected Sub btnSubmit_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSubmit.Click
        Dim redirectPage As String = String.Empty
        Dim i As Integer
        Int32.TryParse(Helpers.CleanInputText(txtBadgeNumber.Text, 7), i)

        If i > 0 Then
            If UserManager.SetUserToSession(i) Then
                Response.Redirect(GetRedirectPage) 'if the user was found by their badge number and added then everything is ok, send them to where they want
            ElseIf Not UserManager.GetCurrentUser.RequiresSuppAuth Then
                notMain.Notifications = UserManager.ConfirmUserCredentialsAndSave(UserManager.GetCurrentUser.UserName, String.Empty, i, 76, False)

                If Not notMain.Notifications.HasErrors Then
                    Response.Redirect(GetRedirectPage)
                End If
            Else
                notMain.Notifications.AddWithMessage("You're Badge Number Is Not Found! Use Windows Credentials Login.", REMI.Validation.NotificationType.Warning)
            End If
        Else
            notMain.Notifications.AddWithMessage("Unable To Read Badge Number! Try Windows Credentials Login.", REMI.Validation.NotificationType.Errors)
        End If
    End Sub

    Private Function GetRedirectPage() As String
        If Request.QueryString.Item("RedirectPage") IsNot Nothing Then
            Return Request.QueryString.Get("RedirectPage")
        Else
            Return REMIConfiguration.DefaultRedirectPage
        End If
    End Function

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        txtBadgeNumber.Focus()
    End Sub

    Sub UserNameValidation(ByVal source As Object, ByVal arguments As ServerValidateEventArgs)
        If (Remi.Helpers.GetPostBackControl(Me.Page).ID = "btnConfirm") Then
            If (txtUserName.Text.Trim().Length = 0) Then
                arguments.IsValid = False
                DirectCast(source, CustomValidator).ErrorMessage = "You Must Enter An UserName!"
            Else
                DirectCast(source, CustomValidator).ErrorMessage = ""
                arguments.IsValid = True
            End If
        End If
    End Sub

    Sub PasswordValidation(ByVal source As Object, ByVal arguments As ServerValidateEventArgs)
        If (Remi.Helpers.GetPostBackControl(Me.Page).ID = "btnConfirm") Then
            If (txtPassword.Text.Trim().Length = 0) Then
                arguments.IsValid = False
                DirectCast(source, CustomValidator).ErrorMessage = "You Must Enter An Password!"
            Else
                DirectCast(source, CustomValidator).ErrorMessage = ""
                arguments.IsValid = True
            End If
        End If
    End Sub

    Protected Sub btnConfirm_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnConfirm.Click
        If (Page.IsValid) Then
            Dim bNumber As Int32 'try to get the badge numer sent in. This is not sent in in some cases (just adding a user to remi).
            Dim redirectPage As String = "~/"

            Int32.TryParse(txtBadge.Text, bNumber)

            If Request.QueryString.Item("redirectpage") IsNot Nothing Then
                redirectPage = Request.QueryString.Get("redirectpage")
            End If

            notMain.Notifications = UserManager.ConfirmUserCredentialsAndSave(Helpers.CleanInputText(txtUserName.Text.ToLower, 255), txtPassword.Text, bNumber, ddlGeoLoc.SelectedValue, True)

            If Not notMain.Notifications.HasErrors Then
                Response.Redirect(GetRedirectPage)
            End If
        End If
    End Sub
End Class
