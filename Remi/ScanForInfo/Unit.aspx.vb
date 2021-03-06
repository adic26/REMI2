﻿Imports REMI.BusinessEntities
Imports REMI.Bll
Imports REMI.Validation
Imports Remi.Core

Partial Class ScanUnit
    Inherits System.Web.UI.Page

    Protected Sub btnSubmit_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSubmit.Click
        Response.Redirect(String.Format("{0}?RN={1}", Helpers.GetCurrentPageName, Helpers.CleanInputText(txtBarcodeReading.Text, 30)))
    End Sub

    Protected Sub SetGvwHeaders() Handles grdTrackingLog.PreRender, grdDetail.PreRender
        Helpers.MakeAccessable(grdTrackingLog)
        Helpers.MakeAccessable(grdDetail)
    End Sub

    Protected Sub ProcessQRA(ByVal tmpStr As String)
        Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(tmpStr))
        Dim b As BatchView

        If bc.Validate Then
            If bc.HasTestUnitNumber Then
                b = BatchManager.GetBatchView(bc.BatchNumber, True, False, True, False, True, False, True, False, False, False)
            Else
                notMain.Notifications.AddWithMessage("The barcode must have a unit number to get the information.", NotificationType.Warning)
                Exit Sub
            End If
        Else
            notMain.Notifications = bc.Notifications
            Exit Sub
        End If

        If b IsNot Nothing Then
            Dim tu As TestUnit = (From u As TestUnit In b.TestUnits Where u.BatchUnitNumber = bc.UnitNumber Select u).FirstOrDefault()

            If (tu IsNot Nothing) Then
                Dim litTitle As Literal = Master.FindControl("litPageTitle")
                If litTitle IsNot Nothing Then
                    litTitle.Text = "REMI - " + bc.ToString
                End If

                Dim tColl As New TestUnitCollection
                tColl.Add(tu)

                grdDetail.DataSource = tColl
                grdDetail.DataBind()
                hypTestRecords.NavigateUrl = REMIWebLinks.GetTestRecordsLink(bc.ToString, String.Empty, String.Empty, String.Empty, 0)
                hypMFG.NavigateUrl = tu.MfgWebLink
                lblQRANumber.Text = bc.ToString
                notMain.Notifications.Add(b.GetAllTestUnitNotifications(bc.UnitNumber))
                hypBatchInfo.NavigateUrl = b.BatchInfoLink
                hypRefresh.NavigateUrl = tu.UnitInfoLink
                hdnQRANumber.Value = bc.ToString
                hdnTestUnitID.Value = tu.ID
                grdTrackingLog.DataBind()

                Dim myMenu As WebControls.Menu
                Dim mi As New MenuItem
                myMenu = CType(Master.FindControl("menuHeader"), WebControls.Menu)

                mi = New MenuItem
                mi.Text = "Batch Info"
                mi.Target = "_blank"
                mi.NavigateUrl = b.BatchInfoLink
                myMenu.Items(0).ChildItems.Add(mi)

                mi = New MenuItem
                mi.Text = "Test Records"
                mi.Target = "_blank"
                mi.NavigateUrl = REMIWebLinks.GetTestRecordsLink(bc.ToString, String.Empty, String.Empty, String.Empty, 0)
                myMenu.Items(0).ChildItems.Add(mi)

                mi = New MenuItem
                mi.Text = "MfgWeb History"
                mi.Target = "_blank"
                mi.NavigateUrl = tu.MfgWebLink
                myMenu.Items(0).ChildItems.Add(mi)
            Else
                notMain.Notifications.AddWithMessage(String.Format("{0} could not be found in REMI.", bc.UnitNumber), NotificationType.Warning)
            End If
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
            Dim tmpStr As String = Request.QueryString.Get("RN")
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