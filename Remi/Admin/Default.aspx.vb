
Partial Class Admin_Default
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        Response.Redirect("~/admin/jobs.aspx", False)
    End Sub
End Class
