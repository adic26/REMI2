﻿Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports System.Data
Partial Class ManageBatches_ModifyTestStage
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            notMain.Clear()
            Dim qra As String = Request.QueryString.Get("RN")
            If Not String.IsNullOrEmpty(qra) Then
                ProcessQRA(qra)
            End If
        End If
    End Sub
#Region "Change Test Stage Methods"

    Protected Sub ProcessQRA(ByVal QRANumber As String)
        Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))
        Dim b As BatchView

        If bc.Validate Then
            b = BatchManager.GetBatchView(bc.BatchNumber, False, False, True, False, False, False, False, False, False, False)

            hdnQRANumber.Value = b.QRANumber
            lblQRANumber.Text = b.QRANumber
            hypBatchInfo.NavigateUrl = b.BatchInfoLink
            hypCancel.NavigateUrl = b.BatchInfoLink
            hypRefresh.NavigateUrl = b.SetTestStageManagerLink
            SetupTestStageDropDownList(b)
            hypModifyTestDurations.NavigateUrl = b.SetTestDurationsManagerLink

            If UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID) Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                liModifyTestDurations.Visible = True
            End If

            Dim myMenu As WebControls.Menu
            Dim mi As New MenuItem
            myMenu = CType(Master.FindControl("menuHeader"), WebControls.Menu)

            mi.Text = "Batch Info"
            mi.NavigateUrl = b.BatchInfoLink
            myMenu.Items(0).ChildItems.Add(mi)

            mi = New MenuItem
            mi.Text = "Modify Duration"
            mi.NavigateUrl = b.SetTestDurationsManagerLink
            myMenu.Items(0).ChildItems.Add(mi)

            pnlEditExceptions.Visible = True
            pnlLeftMenuActions.Visible = True
        Else
            pnlLeftMenuActions.Visible = False
            pnlEditExceptions.Visible = False
            notMain.Notifications = bc.Notifications
            Exit Sub
        End If
    End Sub

    Public Sub SaveStatus()
        notMain.Notifications.Add(BatchManager.ChangeTestStage(hdnQRANumber.Value, ddlSelection.SelectedItem.Text))
    End Sub

    Protected Sub SetupTestStageDropDownList(ByVal b As BatchView)
        ddlSelection.DataSource = TestStageManager.GetTestStagesNameByBatch(b.ID, b.JobName)
        ddlSelection.DataBind()
        lblCurrentTestStage.Text = b.TestStageName
    End Sub
#End Region

    Protected Sub lkbSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lkbSave.Click
        SaveStatus()
        ProcessQRA(hdnQRANumber.Value)
    End Sub
End Class