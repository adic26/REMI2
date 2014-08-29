Imports REMI.Bll

Partial Class Admin_Logs
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            If Not UserManager.GetCurrentUser.IsDeveloper Then
                Response.Redirect("~/")
            End If

            txtStart.Text = DateTime.Now
            txtEnd.Text = DateTime.Now
        End If
    End Sub

    Protected Sub btnRunReport_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnRunReport.Click
        Dim startDate As DateTime
        Dim endDate As DateTime

        DateTime.TryParse(txtStart.Text, startDate)
        DateTime.TryParse(txtEnd.Text, endDate)

        gvwApplicationLogs.DataSource = (From l In New REMI.Dal.Entities().Instance().ApplicationLogs Where l.Date >= startDate And l.Date <= endDate Select l Order By l.Date Descending).ToList
        gvwApplicationLogs.DataBind()
    End Sub
End Class