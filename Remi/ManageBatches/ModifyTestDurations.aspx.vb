Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports REMI.Contracts

Partial Class ManageBatches_ModifyTestDurations
    Inherits System.Web.UI.Page
    Protected Sub PageLoad() Handles Me.Load
        If Not Page.IsPostBack Then
            notMain.Clear()
            Dim qra As String = Request.QueryString.Get("QRA")
            If Not String.IsNullOrEmpty(qra) Then
                ProcessQRA(qra)
            End If
        End If
    End Sub
    Protected Sub fixGridview() Handles grdOverview.PreRender
        Helpers.MakeAccessable(grdOverview)
    End Sub
    Protected Class DurationItem

        Private _name As String
        Public Property Name() As String
            Get
                Return _name
            End Get
            Set(ByVal value As String)
                _name = value
            End Set
        End Property

        Private _defaultDuration As Double
        Public Property DefaultDuration() As Double
            Get
                Return _defaultDuration
            End Get
            Set(ByVal value As Double)
                _defaultDuration = value
            End Set
        End Property

        Private _batchDuration As Double
        Public Property BatchDuration() As Double
            Get
                Return _batchDuration
            End Get
            Set(ByVal value As Double)
                _batchDuration = value
            End Set
        End Property
    End Class
    Protected Sub ProcessQRA(ByVal QRANumber As String)
        Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))
        Dim b As Batch

        If bc.Validate Then
            b = BatchManager.GetItem(bc.BatchNumber)
            hdnQRANumber.Value = b.QRANumber
            lblQRANumber.Text = b.QRANumber
            hypBatchInfo.NavigateUrl = b.BatchInfoLink
            hypCancel.NavigateUrl = b.BatchInfoLink
            hypRefresh.NavigateUrl = b.SetTestDurationsManagerLink
            ddlSelectTestStage.Items.Clear()
            Dim tsIList As New List(Of DurationItem)

            hypChangeTestStage.NavigateUrl = b.SetTestStageManagerLink
            hypChangeStatus.NavigateUrl = b.SetStatusManagerLink
            hypChangePriority.NavigateUrl = b.SetPriorityManagerLink

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
            mi.Text = "Modify Priority"
            mi.NavigateUrl = b.SetPriorityManagerLink
            myMenu.Items(0).ChildItems.Add(mi)

            For Each ts As TestStage In b.Job.TestStages.FindByType(TestStageType.EnvironmentalStress)
                If (ts.IsArchived = False) Then
                    Dim i As New ListItem(ts.Name, ts.ID)
                    ddlSelectTestStage.Items.Add(i)
                    Dim tsI As New DurationItem
                    tsI.BatchDuration = b.GetExpectedTestStageDuration(ts.ID)
                    tsI.DefaultDuration = ts.DurationInHours
                    tsI.Name = ts.Name
                    tsIList.Add(tsI)
                End If
            Next

            If tsIList.Count > 0 Then
                grdOverview.DataSource = tsIList
                grdOverview.DataBind()
            End If

            If ddlSelectTestStage.Items.Count > 0 Then
                ddlSelectTestStage.SelectedIndex = 0
            End If

            If UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID) Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                liModifyPriority.Visible = True
                liModifyStage.Visible = True
                liModifyStatus.Visible = True
            End If

            pnlEdit.Visible = True
            pnlLeftMenuActions.Visible = True
        Else
            pnlLeftMenuActions.Visible = False
            pnlEdit.Visible = False
            notMain.Notifications = bc.Notifications
            Exit Sub
        End If

    End Sub
    Protected Sub SaveDuration()
        Try
            BatchManager.ModifyBatchSpecificTestDuration(hdnQRANumber.Value, ddlSelectTestStage.SelectedValue, Double.Parse(txtDuration.Text), String.Empty)
        Catch ex As Exception
            notMain.Notifications.AddWithMessage("Unable to save. Check that the duration is valid. Error: " + ex.Message, NotificationType.Warning)
        End Try
    End Sub

    Protected Sub lkbSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lkbSave.Click
        SaveDuration()
        ProcessQRA(hdnQRANumber.Value)
    End Sub


    Protected Sub btnRevertToDefault_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnRevertToDefault.Click
        notMain.Notifications.Add(BatchManager.RevertBatchSpecificTestDuration(hdnQRANumber.Value, ddlSelectTestStage.SelectedValue, String.Empty))
        ProcessQRA(hdnQRANumber.Value)
    End Sub
End Class
