Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports System.Data
Partial Class ManageBatches_ModifyTestStage
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            notMain.Clear()
            Dim qra As String = Request.QueryString.Get("QRA")
            If Not String.IsNullOrEmpty(qra) Then
                ProcessQRA(qra)
            End If
        End If
    End Sub
#Region "Change Test Stage Methods"

    Protected Sub ProcessQRA(ByVal QRANumber As String)
        Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))
        Dim b As Batch

        If bc.Validate Then
            b = BatchManager.GetItem(bc.BatchNumber)
            hdnQRANumber.Value = b.QRANumber
            lblQRANumber.Text = b.QRANumber
            hypBatchInfo.NavigateUrl = b.BatchInfoLink
            hypCancel.NavigateUrl = b.BatchInfoLink
            hypRefresh.NavigateUrl = b.SetTestStageManagerLink
            SetupTestStageDropDownList(b)
            hypModifyTestDurations.NavigateUrl = b.SetTestDurationsManagerLink
            hypChangeStatus.NavigateUrl = b.SetStatusManagerLink
            hypChangePriority.NavigateUrl = b.SetPriorityManagerLink

            If UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID) Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                liModifyPriority.Visible = True
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
        notMain.Notifications.Add(BatchManager.ChangeTestStage(hdnQRANumber.Value, ddlSelection.SelectedItem.Text))

    End Sub

    Protected Sub SetupTestStageDropDownList(ByVal b As Batch)
        ddlSelection.DataSource = TestStageManager.GetTestStagesNameByBatch(b.ID)
        ddlSelection.DataBind()
        lblCurrentTestStage.Text = b.TestStageName
    End Sub
#End Region

    Protected Sub lkbSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lkbSave.Click
        SaveStatus()
        ProcessQRA(hdnQRANumber.Value)
    End Sub
End Class
