Imports REMI.Bll
Imports REMI.BusinessEntities
Partial Class Inventory_InventoryReport
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

    End Sub

    Protected Sub btnGetReport_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnGetReport.Click
        notMain.Clear()
        Dim startDate As DateTime
        Dim enddate As DateTime
        If Not DateTime.TryParse(txtStartDate.Text, startDate) Then
            notMain.Add("The start date cannot be read as a date. Clear the text field and use the calandar control to select a date.", REMI.Validation.NotificationType.Errors)
            Exit Sub
        End If
        If Not DateTime.TryParse(txtEndDate.Text, enddate) Then
            notMain.Add("The end date cannot be read as a date. Clear the text field and use the calandar control to select a date.", REMI.Validation.NotificationType.Errors)
            Exit Sub
        End If
        startDate.Add(TimeSpan.FromHours(0))
        enddate = enddate.Add(New TimeSpan(23, 59, 59))
        If startDate > enddate Then
            notMain.Add("The start date cannot be later than the end date.", REMI.Validation.NotificationType.Errors)
            Exit Sub
        End If
        If startDate.Year < 2000 OrElse enddate.Year < 2000 Then
            notMain.Add("The start date and end dates must be later than 2000.", REMI.Validation.NotificationType.Errors)
            Exit Sub
        End If

        Dim ir As InventoryReportData = ProductGroupManager.InventoryReport(startDate, enddate, chkFilterByQRA.Checked, ddlTestCenter.SelectedValue)

        If (ir IsNot Nothing) Then
            lblAverageUnitsRecieved.Text = ir.AverageUnitsInBatch
            lblTotalUnitsRecieved.Text = ir.TotalUnits
            lblTotalBatchesRecieved.Text = ir.TotalBatches

            grdProductLocationReport.DataSource = ir.ProductLocationReport
            grdProductLocationReport.DataBind()
            grdProductDistribution.DataSource = ir.ProductDistribution
            grdProductDistribution.DataBind()
        End If
    End Sub
    Public Sub page_prerender() Handles Me.PreRender
        Helpers.MakeAccessable(grdProductLocationReport)
        Helpers.MakeAccessable(grdProductDistribution)
    End Sub
End Class
