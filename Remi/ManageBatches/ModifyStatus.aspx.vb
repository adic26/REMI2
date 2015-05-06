Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports System.Data
Imports REMI.Contracts
Partial Class ManageBatches_ModifyStatus
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
#Region "Test Exceptions methods"

    Protected Sub ProcessQRA(ByVal QRANumber As String)
        Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))
        Dim b As BatchView

        If bc.Validate Then
            b = BatchManager.GetBatchView(bc.BatchNumber, False, False, True, False, False, False, False, False, False, False)
            hdnQRANumber.Value = b.QRANumber
            lblQRANumber.Text = b.QRANumber
            hypBatchInfo.NavigateUrl = b.BatchInfoLink
            hypCancel.NavigateUrl = b.BatchInfoLink
            hypRefresh.NavigateUrl = b.SetStatusManagerLink
            SetupTestStageDropDownList(b.Status.ToString)
            hypModifyTestDurations.NavigateUrl = b.SetTestDurationsManagerLink
            hypChangeTestStage.NavigateUrl = b.SetTestStageManagerLink
            hypChangePriority.NavigateUrl = b.SetPriorityManagerLink

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

            mi = New MenuItem
            mi.Text = "Modify Stage"
            mi.NavigateUrl = b.SetTestStageManagerLink
            myMenu.Items(0).ChildItems.Add(mi)

            mi = New MenuItem
            mi.Text = "Modify Priority"
            mi.NavigateUrl = b.SetPriorityManagerLink
            myMenu.Items(0).ChildItems.Add(mi)

            If UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID) Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                liModifyPriority.Visible = True
                liModifyStage.Visible = True
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
        notMain.Notifications.Add(BatchManager.SetStatus(hdnQRANumber.Value, DirectCast([Enum].Parse(GetType(BatchStatus), ddlSelection.SelectedItem.Text), BatchStatus)))

    End Sub

    Protected Sub SetupTestStageDropDownList(ByVal currentStatus As String)
        ddlSelection.DataSource = Helpers.GetBatchStatus
        ddlSelection.DataBind()
        lblCurrentStatus.Text = currentStatus
    End Sub
#End Region

    Protected Sub lkbSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lkbSave.Click
        SaveStatus()
        ProcessQRA(hdnQRANumber.Value)
    End Sub
End Class
