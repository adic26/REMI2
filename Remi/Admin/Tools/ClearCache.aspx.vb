Imports Remi.Bll
Imports Remi.BusinessEntities

Public Class ClearCache
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            If Not UserManager.GetCurrentUser.IsAdmin Then
                Response.Redirect("~/")
            End If
        End If
    End Sub

    Protected Sub btnClearCache_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnClearCache.Click
        REMIAppCache.ClearAll()
        lblSuccess.Text = "Cache Successfully Cleared"
    End Sub
End Class