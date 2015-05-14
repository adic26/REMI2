Imports Remi.Validation
Imports Remi.BusinessEntities
Imports Remi.Bll
Imports System.Data
Imports REMI.Contracts

Partial Class ManageBatches_ModifyPriority
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

    Protected Sub ProcessQRA(ByVal QRANumber As String)
        Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))
        Dim b As BatchView

        If bc.Validate Then
            b = BatchManager.GetBatchView(bc.BatchNumber, False, False, True, False, False, False, False, False, False, False)
            hdnQRANumber.Value = b.QRANumber
            lblQRANumber.Text = b.QRANumber
            hypBatchInfo.NavigateUrl = b.BatchInfoLink
            hypRefresh.NavigateUrl = b.SetPriorityManagerLink
            hypCancel.NavigateUrl = b.BatchInfoLink
            SetupTestStageDropDownList(b)
            hypModifyTestDurations.NavigateUrl = b.SetTestDurationsManagerLink
            hypChangeTestStage.NavigateUrl = b.SetTestStageManagerLink
            hypChangeStatus.NavigateUrl = b.SetStatusManagerLink

            Dim myMenu As WebControls.Menu
            Dim mi As New MenuItem
            myMenu = CType(Master.FindControl("menuHeader"), WebControls.Menu)

            mi.Text = "Batch Info"
            mi.NavigateUrl = b.BatchInfoLink
            myMenu.Items(0).ChildItems.Add(mi)

            mi = New MenuItem
            mi.Text = "Modify Stage"
            mi.NavigateUrl = b.SetTestStageManagerLink
            myMenu.Items(0).ChildItems.Add(mi)

            mi = New MenuItem
            mi.Text = "Modify Status"
            mi.NavigateUrl = b.SetStatusManagerLink
            myMenu.Items(0).ChildItems.Add(mi)

            mi = New MenuItem
            mi.Text = "Modify Durations"
            mi.NavigateUrl = b.SetTestDurationsManagerLink
            myMenu.Items(0).ChildItems.Add(mi)

            If UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID) Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                liModifyStage.Visible = True
                liModifyStatus.Visible = True
                liModifyTestDurations.Visible = True
            End If

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
        notMain.Notifications.Add(BatchManager.SetPriority(hdnQRANumber.Value, ddlSelection.SelectedItem.Value, ddlSelection.SelectedItem.Text))
    End Sub

    Protected Sub SetupTestStageDropDownList(ByVal b As BatchView)
        lblCurrentPriority.Text = b.Priority.ToString
        ddlSelection.DataSource = LookupsManager.GetLookups("Priority", Nothing, Nothing, String.Empty, String.Empty, 0, False, 0, False)
        ddlSelection.DataBind()
        ddlSelection.SelectedValue = ddlSelection.Items.FindByText(b.Priority).Value
    End Sub

    Protected Sub lkbSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lkbSave.Click
        SaveStatus()
        ProcessQRA(hdnQRANumber.Value)
    End Sub
End Class
