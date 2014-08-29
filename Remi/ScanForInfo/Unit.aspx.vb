Imports REMI.BusinessEntities
Imports REMI.Bll
Imports REMI.Validation
Imports Remi.Core

Partial Class ScanUnit
    Inherits System.Web.UI.Page

    Protected Sub btnSubmit_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSubmit.Click
        Response.Redirect(String.Format("{0}?QRA={1}", Helpers.GetCurrentPageName, Helpers.CleanInputText(txtBarcodeReading.Text, 30)))
    End Sub

    Protected Sub SetGvwHeaders() Handles grdTrackingLog.PreRender, grdDetail.PreRender
        Helpers.MakeAccessable(grdTrackingLog)
        Helpers.MakeAccessable(grdDetail)
    End Sub

    Protected Sub ProcessQRA(ByVal tmpStr As String)
        Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(tmpStr))
        Dim b As Batch

        If bc.Validate Then
            If bc.HasTestUnitNumber Then
                b = BatchManager.GetItem(bc.BatchNumber)
            Else
                notMain.Notifications.AddWithMessage("The barcode must have a unit number to get the information.", NotificationType.Warning)
                Exit Sub
            End If
        Else
            notMain.Notifications = bc.Notifications
            Exit Sub
        End If

        If b IsNot Nothing AndAlso b.GetUnit(bc.UnitNumber) IsNot Nothing Then
            Dim litTitle As Literal = Master.FindControl("litPageTitle")
            If litTitle IsNot Nothing Then
                litTitle.Text = "REMI - " + bc.ToString
            End If

            Dim tColl As New TestUnitCollection
            tColl.Add(b.GetUnit(bc.UnitNumber))
            grdDetail.DataSource = tColl
            grdDetail.DataBind()
            hypTestRecords.NavigateUrl = REMIWebLinks.GetTestRecordsLink(bc.ToString, String.Empty, String.Empty, String.Empty, 0)
            hypMFG.NavigateUrl = b.GetUnit(bc.UnitNumber).MfgWebLink
            lblQRANumber.Text = bc.ToString
            notMain.Notifications.Add(b.GetAllTestUnitNotifications(bc.UnitNumber))
            hypBatchInfo.NavigateUrl = b.BatchInfoLink
            hypRefresh.NavigateUrl = b.GetUnit(bc.UnitNumber).UnitInfoLink
            hdnQRANumber.Value = bc.ToString
            hdnTestUnitID.Value = b.GetUnit(bc.UnitNumber).ID
            grdTrackingLog.DataBind()
        Else
            notMain.Notifications.AddWithMessage(String.Format("{0} could not be found in REMI.", bc.ToString), NotificationType.Warning)
        End If
    End Sub

    Protected Sub grdProgress_RowDatabound(ByVal sender As Object, ByVal e As GridViewRowEventArgs)
        If (e.Row.RowType = DataControlRowType.DataRow) Then
            Dim cells As TableCellCollection = e.Row.Cells

            For Each cell As TableCell In cells
                cell.Text = Server.HtmlDecode(cell.Text)
                If cell.Text.EndsWith("Pass</a>") Then
                    cell.CssClass = "Pass"
                ElseIf cell.Text.EndsWith("Fail</a>") Then
                    cell.CssClass = "Fail"
                End If
            Next
        End If
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            notMain.Clear()
            Dim tmpStr As String = Request.QueryString.Get("QRA")
            If Not String.IsNullOrEmpty(tmpStr) Then
                ProcessQRA(tmpStr)
            Else
                Dim litTitle As Literal = Master.FindControl("litPageTitle")
                If litTitle IsNot Nothing Then
                    litTitle.Text = "REMI - Unit Information"
                End If
            End If
        End If

        If System.Web.HttpContext.Current.Session Is Nothing Then
            REMI.Bll.REMIManagerBase.LogIssue("Session is null", "e1", REMI.Validation.NotificationType.Information)
        End If

        txtBarcodeReading.Focus()
    End Sub

    Protected Sub ShowSummary()
        pnlSummary.Visible = True
    End Sub

    Protected Sub ddlTime_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTime.SelectedIndexChanged
        odsTrackingLog.DataBind()
        grdTrackingLog.DataBind()
    End Sub
End Class