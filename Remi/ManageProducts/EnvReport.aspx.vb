Imports REMI.Bll

Partial Class ManageProducts_EnvReport
    Inherits System.Web.UI.Page

    Protected envds As New DataSet

    Protected Sub PageLoad() Handles Me.Load
        If Not Page.IsPostBack Then
            txtStart.Text = DateTime.Today.Subtract(TimeSpan.FromDays(7)).ToString("d")
            txtEnd.Text = DateTime.Today.ToString("d")
        End If

        If (ddlTestCenters.Items.Count = 0) Then
            ddlTestCenters.DataSource = Remi.Bll.LookupsManager.GetLookups(Contracts.LookupType.TestCenter, 0, 0, 1)
            ddlTestCenters.DataBind()
            ddlTestCenters.SelectedValue = UserManager.GetCurrentUser.TestCentreID
        End If
    End Sub

    Protected Sub setgridViewHeaders() Handles grdMain.PreRender
        Helpers.MakeAccessable(grdMain)
    End Sub

    Protected Sub btnRunReport_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnRunReport.Click
        Dim startDate As DateTime = txtStart.Text
        Dim endDate As DateTime = txtEnd.Text
        Dim years As Int32 = DateDiff(DateInterval.Year, startDate, endDate, Microsoft.VisualBasic.FirstDayOfWeek.Monday)

        If (years < 2) Then
            envds = Remi.Bll.ProductGroupManager.GetTestCountByType(startDate, endDate, ddlReportBasedOn.SelectedValue, ddlTestCenters.SelectedValue, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID)

            grdMain.DataSource = Remi.Bll.ProductGroupManager.GetEnvironmentalReport(startDate, endDate, ddlReportBasedOn.SelectedValue, ddlTestCenters.SelectedValue, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID, 0)
            grdMain.DataBind()
        Else
            notifications.Notifications.Add("", Validation.NotificationType.Information, "Date Range Too Great.")
        End If
    End Sub

    Protected Sub grdMain_RowDataBound(sender As Object, e As GridViewRowEventArgs) Handles grdMain.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim gvDetails As New GridView
            Dim dt As New DataTable

            For Each table As DataTable In envds.Tables
                If (table.Rows.Count > 0) Then
                    If (e.Row.Cells(1).Text = table.Rows(0).Item(0).ToString()) Then
                        dt = table
                        Exit For
                    End If
                End If
            Next

            gvDetails.DataSource = dt.DefaultView
            gvDetails.ID = "gvDetails_" & e.Row.RowIndex
            gvDetails.AutoGenerateColumns = True

            Dim btn As Web.UI.WebControls.Image = New Web.UI.WebControls.Image
            btn.ID = "btnDetail"
            btn.ImageUrl = "/Design/Icons/png/16x16/link.png"
            btn.Attributes.Add("onclick", "javascript: gvrowtoggle(" & e.Row.RowIndex + (e.Row.RowIndex + 2) & ")")

            Dim tbl As Table = DirectCast(e.Row.Parent, Table)
            Dim tr As New GridViewRow(e.Row.RowIndex + 1, -1, DataControlRowType.EmptyDataRow, DataControlRowState.Normal)
            tr.CssClass = "hidden"
            Dim tc As New TableCell()
            tc.ColumnSpan = e.Row.Cells.Count
            tc.BorderStyle = BorderStyle.None
            tc.BackColor = Drawing.Color.AliceBlue
            tc.Controls.Add(gvDetails)
            tr.Cells.Add(tc)
            tr.Cells(0).ColumnSpan = e.Row.Cells.Count
            tbl.Rows.Add(tr)
            e.Row.Cells(0).Controls.Add(btn)
            gvDetails.DataBind()
            Helpers.MakeAccessable(gvDetails)
        End If
    End Sub
End Class
