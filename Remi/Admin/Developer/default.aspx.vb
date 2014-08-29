Imports Remi.Bll

Partial Class Developer_Default
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            If Not UserManager.GetCurrentUser.IsDeveloper Then
                Response.Redirect("~/")
            End If
        End If
    End Sub

End Class