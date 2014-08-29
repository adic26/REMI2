Imports REMI.Bll

Public Class Help_Default
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If (UserManager.GetCurrentUser.IsTestCenterAdmin Or UserManager.GetCurrentUser.IsAdmin) Then
            hplAdmin.CssClass = String.Empty
            hplRoles.CssClass = String.Empty
        End If
    End Sub
End Class