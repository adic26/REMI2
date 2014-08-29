Imports REMI.Bll
Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Contracts

Partial Class Admin_TestStages
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            If Not UserManager.GetCurrentUser.IsAdmin And Not UserManager.GetCurrentUser.HasAdminReadOnlyAuthority Then
                Response.Redirect("~/")
            End If

            If (UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                lnkAddTestStage.Enabled = False
                lnkAddTestStageAction.Enabled = False
            End If

            If (UserManager.GetCurrentUser.IsTestCenterAdmin And Not (UserManager.GetCurrentUser.IsAdmin)) Then
                Hyperlink1.Enabled = False
                Hyperlink2.Enabled = False

                If (Not UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                    Hyperlink5.Enabled = False
                    Hyperlink7.Enabled = False
                End If
            End If

            ddlTestStageType.DataSource = Helpers.GetTestStageTypes
            ddlTestStageType.DataBind()
            ddlJobs.DataBind()

            If (ddlJobs.Items.Count > 0) Then
                Dim jobID As Int32
                Dim jobName As String
                Int32.TryParse(Request.QueryString("JobID"), jobID)

                If (jobID > 0) Then
                    jobName = JobManager.GetJobNameByID(jobID)
                    ddlJobs.Items.FindByText(jobName).Selected = True
                Else
                    ddlJobs.Items(0).Selected = True
                    jobName = ddlJobs.SelectedItem.Text
                End If

                LoadJob(jobName)
            End If
        End If
    End Sub

#Region "Edit/View All Modes"
    Protected Sub LoadJob(ByVal jobName As String)
        HideEditTestStagePanel()
        Dim j As Job = JobManager.GetJobByName(jobName)
        gvwMain.EmptyDataText = "There are no test stages for " + j.Name
        lblViewAllTitle.Text = "Test Stages for " + j.Name
        txtJobWILocation.Text = j.WILocation
        txtProcedureLocation.Text = j.ProcedureLocation
        chkIsOperationsTest.Checked = j.IsOperationsTest
        chkIsTechOperationsTest.Checked = j.IsTechOperationsTest
        chkIsMechanicalTest.Checked = j.IsMechanicalTest
        chkIsActive.Checked = j.IsActive
        chkNoBSN.Checked = j.NoBSN
        chkContinueFailure.Checked = j.ContinueOnFailures
        gvwMain.DataBind()

        Dim bs As New BatchSearch()
        bs.JobName = jobName
        bs.ExcludedStatus = BatchSearchBatchStatus.Complete

        bscJobs.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))

        JobSetup.JobID = j.ID
        JobSetup.BatchID = 0
        JobSetup.ProductID = 0
        JobSetup.JobName = j.Name
        JobSetup.ProductName = String.Empty
        JobSetup.QRANumber = String.Empty
        JobSetup.TestStageType = TestStageType.Parametric
        JobSetup.IsProjectManager = UserManager.GetCurrentUser.IsProjectManager
        JobSetup.IsAdmin = UserManager.GetCurrentUser.IsAdmin
        JobSetup.HasEditItemAuthority = UserManager.GetCurrentUser.IsAdmin
        JobSetup.DataBind()

        JobEnvSetup.JobID = j.ID
        JobEnvSetup.BatchID = 0
        JobEnvSetup.ProductID = 0
        JobEnvSetup.JobName = j.Name
        JobEnvSetup.ProductName = String.Empty
        JobEnvSetup.QRANumber = String.Empty
        JobEnvSetup.TestStageType = TestStageType.EnvironmentalStress
        JobEnvSetup.IsProjectManager = UserManager.GetCurrentUser.IsProjectManager
        JobEnvSetup.IsAdmin = UserManager.GetCurrentUser.IsAdmin
        JobEnvSetup.HasEditItemAuthority = UserManager.GetCurrentUser.IsAdmin
        JobEnvSetup.DataBind()
    End Sub

    Protected Sub FillFormFieldsforTestStage(ByVal tmpTestStage As TestStage)
        If tmpTestStage IsNot Nothing Then
            If (Not (String.IsNullOrEmpty(tmpTestStage.Name))) Then
                txtName.Enabled = False
            End If
            txtName.Text = tmpTestStage.Name
            ddlTestStageType.ClearSelection()
            If tmpTestStage.TestStageType <> TestStageType.NotSet Then
                ddlTestStageType.Items.FindByValue(tmpTestStage.TestStageType.ToString()).Selected = True
            End If
            txtProcessOrder.Text = tmpTestStage.ProcessOrder
            chkArchived.Checked = tmpTestStage.IsArchived
            FillFormFieldsForTest(tmpTestStage)
        Else
            notMain.Notifications.AddWithMessage("The test stage could not be retreived from the database.", NotificationType.Errors)
        End If
    End Sub

    Protected Sub FillFormFieldsForTest(ByVal testStage As TestStage)
        If testStage.ID > 0 Then
            lstAddedTLTypes.Items.Clear()
            lstAllTLTypes.DataBind()
            Dim t As Test = testStage.Tests.FindByID(testStage.TestID)

            If t IsNot Nothing Then
                hdnTestID.Value = t.ID
                If t.TrackingLocationTypes.Count > 0 Then
                    For Each tlID As Integer In t.TrackingLocationTypes.Keys
                        Dim li As ListItem = lstAllTLTypes.Items.FindByValue(tlID)
                        lstAllTLTypes.Items.Remove(li)
                    Next
                    lstAddedTLTypes.DataSource = t.TrackingLocationTypes
                    lstAddedTLTypes.DataBind()
                End If
                chkResultIsTimeBased.Checked = t.ResultIsTimeBased
                txtHours.Text = t.TotalHours
                txtWorkInstructionLocation.Text = t.WorkInstructionLocation
            Else
                chkResultIsTimeBased.Checked = False
                txtHours.Text = 0
                txtWorkInstructionLocation.Text = String.Empty
                hdnTestID.Value = 0
            End If
        End If
    End Sub

    Protected Sub ShowAddEditTestStagePanel(ByVal tmpTestStage As TestStage)
        hdnTestStageID.Value = tmpTestStage.ID
        If tmpTestStage.ID > 0 Then
            lblAddEditTitle.Text = "Editing the " & tmpTestStage.Name & " Test Stage"
        Else
            lblAddEditTitle.Text = "Add a new Test Stage"
        End If
        If tmpTestStage.TestStageType = TestStageType.EnvironmentalStress Then 'set up the test fields for edit also
            pnlAddEditTest.Visible = True
        End If
        pnlAddEditTestStage.Visible = True
        pnlViewAllTestStages.Visible = False
    End Sub

    Protected Sub HideEditTestStagePanel()
        'clear the edit id
        hdnTestID.Value = 0
        hdnTestStageID.Value = 0
        lblAddEditTitle.Text = "Add a new Test Stage"
        pnlAddEditTestStage.Visible = False
        pnlViewAllTestStages.Visible = True
        pnlAddEditTest.Visible = False
        'clear the formfields
        FillFormFieldsforTestStage(New TestStage)
        FillFormFieldsForTest(New TestStage)
    End Sub
#End Region

#Region "Actions"
    Protected Sub gvMain_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs)
        Select Case e.CommandName.ToLower()
            Case "edit"
                notMain.Clear()
                Dim tmpTestStage As TestStage = TestStageManager.GetTestStage(Convert.ToInt32(e.CommandArgument))
                ShowAddEditTestStagePanel(tmpTestStage)
                FillFormFieldsforTestStage(tmpTestStage)
            Case "deleteitem"
                notMain.Notifications.Add(TestStageManager.DeleteTestStage(Convert.ToInt32(e.CommandArgument)))
                gvwMain.DataBind()
        End Select
    End Sub
    Protected Sub SaveTestStage()
        Dim tmpTestStage As TestStage
        notMain.Clear()
        'new or edit?
        If Integer.Parse(hdnTestStageID.Value) > 0 Then
            tmpTestStage = TestStageManager.GetTestStage(CInt(hdnTestStageID.Value))
        Else
            tmpTestStage = New TestStage
        End If
        'set test stage params
        SetTestStageParametersForSave(tmpTestStage)

        If tmpTestStage.TestStageType = TestStageType.EnvironmentalStress Then ' if env test stage then set test for it
            SetParametersForTest(tmpTestStage)
        End If

        tmpTestStage.ID = TestStageManager.SaveTestStage(tmpTestStage) 'save

        notMain.Notifications = tmpTestStage.Notifications

    End Sub
    Protected Sub SaveJob()
        Dim j As Job = New Job
        j.Name = ddlJobs.SelectedItem.Text
        j.WILocation = txtJobWILocation.Text
        j.IsOperationsTest = chkIsOperationsTest.Checked
        j.IsTechOperationsTest = chkIsTechOperationsTest.Checked
        j.IsMechanicalTest = chkIsMechanicalTest.Checked
        j.ProcedureLocation = txtProcedureLocation.Text
        j.IsActive = chkIsActive.Checked
        j.NoBSN = chkNoBSN.Checked
        j.ContinueOnFailures = chkContinueFailure.Checked
        JobManager.SaveJob(j)
        notMain.Notifications.Add(j.Notifications)
    End Sub
    Protected Sub SetTestStageParametersForSave(ByVal tmpTestStage As TestStage)
        tmpTestStage.Name = txtName.Text
        tmpTestStage.JobName = ddlJobs.SelectedItem.Text
        If ddlTestStageType.Visible Then
            tmpTestStage.TestStageType = DirectCast([Enum].Parse(GetType(TestStageType), ddlTestStageType.SelectedItem.Text), TestStageType)
        End If
        tmpTestStage.ProcessOrder = txtProcessOrder.Text
        tmpTestStage.IsArchived = chkArchived.Checked
    End Sub
    Protected Sub SetParametersForTest(ByVal tmpTestStage As TestStage)
        If Not tmpTestStage.Tests.Count > 0 Then
            Dim d As New SerializableDictionary(Of Integer, String)
            For Each li As ListItem In lstAddedTLTypes.Items
                If Not d.TryGetValue(CInt(li.Value), String.Empty) Then
                    d.Add(CInt(li.Value), li.Text)
                End If
            Next
            tmpTestStage.Tests.Add(New Test(Helpers.CleanInputText(txtName.Text, 255), Helpers.CleanInputText(txtWorkInstructionLocation.Text, 255), TestType.EnvironmentalStress, d, Helpers.CleanInputText(txtHours.Text, 100)))
            tmpTestStage.Tests.Item(0).ResultIsTimeBased = chkResultIsTimeBased.Checked
            tmpTestStage.Tests.Item(0).IsArchived = tmpTestStage.IsArchived
        Else
            tmpTestStage.Tests.Item(0).Name = txtName.Text
            tmpTestStage.Tests.Item(0).TotalHours = txtHours.Text
            tmpTestStage.Tests.Item(0).TrackingLocationTypes.Clear()
            For Each li As ListItem In lstAddedTLTypes.Items
                If Not tmpTestStage.Tests.Item(0).TrackingLocationTypes.TryGetValue(CInt(li.Value), String.Empty) Then
                    tmpTestStage.Tests.Item(0).TrackingLocationTypes.Add(CInt(li.Value), li.Text)
                End If
            Next
            tmpTestStage.Tests.Item(0).IsArchived = tmpTestStage.IsArchived
            tmpTestStage.Tests.Item(0).ResultIsTimeBased = chkResultIsTimeBased.Checked
            tmpTestStage.Tests.Item(0).TestType = TestType.EnvironmentalStress
            tmpTestStage.Tests.Item(0).WorkInstructionLocation = txtWorkInstructionLocation.Text
            tmpTestStage.Tests.Item(0).LastUser = Helpers.GetCurrentUserLDAPName
        End If
    End Sub
#End Region

#Region "Page User Interaction Event Handling"

    Protected Sub lnkAddTestStage_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddTestStage.Click
        ShowAddEditTestStagePanel(New TestStage)
    End Sub
    Protected Sub lnkAddTestStageAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddTestStageAction.Click
        If pnlAddEditTestStage.Visible Then
            SaveTestStage()
        Else
            SaveJob()
        End If
        If Not notMain.HasErrors Then
            HideEditTestStagePanel()
            LoadJob(ddlJobs.SelectedItem.Text)
        End If
    End Sub
    Protected Sub lnkCancelAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkCancelAction.Click
        HideEditTestStagePanel()
    End Sub
    Protected Sub lnkViewTestStages_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkViewTestStages.Click
        HideEditTestStagePanel()
    End Sub
    Protected Sub ddlTestStageType_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTestStageType.SelectedIndexChanged
        If DirectCast([Enum].Parse(GetType(TestStageType), ddlTestStageType.SelectedItem.Text), TestStageType) = TestStageType.EnvironmentalStress Then
            pnlAddEditTest.Visible = True
        Else
            pnlAddEditTest.Visible = False
        End If
    End Sub
    Protected Sub ddlJobs_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlJobs.SelectedIndexChanged
        LoadJob(ddlJobs.SelectedItem.Text)
    End Sub
    Protected Sub SetGvwHeader() Handles gvwMain.PreRender
        Helpers.MakeAccessable(gvwMain)
    End Sub
#End Region


    Protected Sub btnAddTLType_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnAddTLType.Click
        Dim li As ListItem = lstAllTLTypes.SelectedItem
        lstAddedTLTypes.ClearSelection()
        If li IsNot Nothing Then
            lstAddedTLTypes.Items.Add(li)
            lstAllTLTypes.Items.Remove(li)
        End If
    End Sub

    Protected Sub btnRemoveTLType_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnRemoveTLType.Click
        Dim li As ListItem = lstAddedTLTypes.SelectedItem
        lstAllTLTypes.ClearSelection()
        If li IsNot Nothing Then
            lstAllTLTypes.Items.Add(li)
            lstAddedTLTypes.Items.Remove(li)
        End If
    End Sub

    Protected Sub gvwMain_RowCreated(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.GridViewRowEventArgs) Handles gvwMain.RowCreated
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim archived As Boolean = False

            If (DataBinder.Eval(e.Row.DataItem, "IsArchived") IsNot Nothing) Then
                Boolean.TryParse(DataBinder.Eval(e.Row.DataItem, "IsArchived").ToString(), archived)
            End If

            If (archived) Then
                e.Row.BackColor = Drawing.Color.Yellow
            End If
        End If
    End Sub
End Class
