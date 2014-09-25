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

        hdnJobID.Value = j.ID

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

        BindOrientations()
    End Sub

    Protected Sub FillFormFieldsforTestStage(ByVal tmpTestStage As TestStage)
        If tmpTestStage IsNot Nothing Then
            If (Not (String.IsNullOrEmpty(tmpTestStage.Name))) Then
                txtName.Enabled = False
                ddlTestStageType.Enabled = False
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
                    For Each tlt As TrackingLocationType In t.TrackingLocationTypes
                        Dim li As ListItem = lstAllTLTypes.Items.FindByValue(tlt.ID)
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
        If (tmpTestStage Is Nothing) Then
            hdnTestID.Value = 0
            hdnTestStageID.Value = 0
            lblAddEditTitle.Text = "Add a new Test Stage"
            txtProcessOrder.Text = String.Empty
            chkArchived.Checked = False
            txtName.Enabled = True
            ddlTestStageType.Enabled = True
            txtName.Text = String.Empty
            txtProcessOrder.Text = String.Empty
            lstAddedTLTypes.Items.Clear()
            pnlAddEditTestStage.Visible = True
            pnlViewAllTestStages.Visible = False
        Else
            hdnTestStageID.Value = tmpTestStage.ID
            lblAddEditTitle.Text = "Editing the " & tmpTestStage.Name & " Test Stage"

            If tmpTestStage.TestStageType = TestStageType.EnvironmentalStress Then 'set up the test fields for edit also
                pnlAddEditTest.Visible = True

                If (tmpTestStage.Tests.Count > 0) Then
                    hdnTestID.Value = tmpTestStage.Tests(0).ID
                End If
            End If

            pnlAddEditTestStage.Visible = True
            pnlViewAllTestStages.Visible = False
            End If
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
        tmpTestStage.LastUser = UserManager.GetCurrentUser.UserName

        If tmpTestStage.TestStageType = TestStageType.EnvironmentalStress Then
            Dim test As Test = (From t As Test In tmpTestStage.Tests Select t).FirstOrDefault()

            If (test Is Nothing) Then
                test = New Test()
            End If

            test.Name = Helpers.CleanInputText(txtName.Text, 255)
            test.TotalHours = txtHours.Text
            test.IsArchived = tmpTestStage.IsArchived
            test.ResultIsTimeBased = chkResultIsTimeBased.Checked
            test.TestType = TestType.EnvironmentalStress
            test.WorkInstructionLocation = Helpers.CleanInputText(txtWorkInstructionLocation.Text, 255)
            test.LastUser = UserManager.GetCurrentUser.UserName

            For Each t As TrackingLocationType In test.TrackingLocationTypes.ToList
                Dim item As ListItem = (From types As ListItem In lstAddedTLTypes.Items Where types.Text = t.Name Select types).FirstOrDefault()

                If (item Is Nothing) Then
                    test.TrackingLocationTypes.Remove(t)
                End If
            Next

            For Each li As ListItem In lstAddedTLTypes.Items
                Dim tlt As New TrackingLocationType
                tlt.ID = li.Value
                tlt.Name = li.Text

                Dim existtlt As TrackingLocationType = (From types In test.TrackingLocationTypes Where types.ID = tlt.ID And types.Name = tlt.Name Select types).FirstOrDefault()

                If (existtlt Is Nothing) Then
                    test.TrackingLocationTypes.Add(tlt)
                End If
            Next

            If ((From t As Test In tmpTestStage.Tests Where t.Name = test.Name Select t).FirstOrDefault() Is Nothing) Then
                tmpTestStage.Tests.Add(test)
            End If
        End If
    End Sub
#End Region

#Region "Page User Interaction Event Handling"
    Protected Sub lnkAddTestStage_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddTestStage.Click
        ShowAddEditTestStagePanel(Nothing)
    End Sub

    Protected Sub lnkAddTestStageAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddTestStageAction.Click
        If pnlAddEditTestStage.Visible Then
            SaveTestStage()
        Else
            SaveJob()
        End If

        If (pnlOrientationAdd.Visible And Not String.IsNullOrEmpty(txtOrientationName.Text)) Then
            Dim productTypeID As Int32
            Int32.TryParse(ddlPT.SelectedValue, productTypeID)

            If (productTypeID > 0 And Not String.IsNullOrEmpty(txtDefinition.Text)) Then
                Dim success As Boolean = JobManager.SaveOrientation(hdnJobID.Value, 0, txtOrientationName.Text, productTypeID, txtOrientationDescription.Text, True, txtDefinition.Text)

                If (success) Then
                    txtOrientationName.Text = String.Empty
                    txtOrientationDescription.Text = String.Empty
                    txtDefinition.Text = String.Empty

                    notMain.Add("Successfully Created New Orientation", NotificationType.Information)
                Else
                    notMain.Add("Failed To Create New Orientation", NotificationType.Errors)
                End If
            Else
                notMain.Add("Orientation Can't Be Created. Please ensure you have entered product type and definition!", NotificationType.Warning)
            End If
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

            lstAllTLTypes.DataBind()


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

    Protected Sub gdvOrientationsGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles gdvOrientations.PreRender
        Helpers.MakeAccessable(gdvOrientations)
    End Sub

    Protected Sub gdvOrientations_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs) Handles gdvOrientations.RowCommand
        Dim xmlstr As String = e.CommandArgument

        Select Case e.CommandName.ToLower()
            Case "xml"
                Dim xml As XDocument = XDocument.Parse(xmlstr)
                Helpers.ExportToXML(Helpers.GetDateTimeFileName("XMLFile", "xml"), xml)
                Exit Select
        End Select
    End Sub

    Protected Sub gdvOrientations_OnRowEditing(ByVal sender As Object, ByVal e As GridViewEditEventArgs)
        gdvOrientations.EditIndex = e.NewEditIndex
        BindOrientations()

        Dim lblName As Label = gdvOrientations.Rows(e.NewEditIndex).FindControl("lblName")
        Dim txtName As TextBox = gdvOrientations.Rows(e.NewEditIndex).FindControl("txtName")
        Dim lblDescription As Label = gdvOrientations.Rows(e.NewEditIndex).FindControl("lblDescription")
        Dim txtDescription As TextBox = gdvOrientations.Rows(e.NewEditIndex).FindControl("txtDescription")
        Dim hdnProductTypeID As HiddenField = gdvOrientations.Rows(e.NewEditIndex).FindControl("hdnProductTypeID")
        Dim lblProductType As Label = gdvOrientations.Rows(e.NewEditIndex).FindControl("lblProductType")
        Dim ddlProductTypes As DropDownList = gdvOrientations.Rows(e.NewEditIndex).FindControl("ddlProductTypes")
        Dim chkActive As CheckBox = gdvOrientations.Rows(e.NewEditIndex).FindControl("chkActive")

        ddlProductTypes.DataSource = LookupsManager.GetLookups(LookupType.ProductType, 0, 0, 0)
        ddlProductTypes.DataBind()

        chkActive.Enabled = True
        lblDescription.Visible = False
        txtDescription.Visible = True
        lblName.Visible = False
        txtName.Visible = True
        lblProductType.Visible = False
        ddlProductTypes.Visible = True
        ddlProductTypes.SelectedValue = hdnProductTypeID.Value
    End Sub

    Protected Sub gdvOrientations_OnRowCancelingEdit(ByVal sender As Object, ByVal e As GridViewCancelEditEventArgs)
        gdvOrientations.EditIndex = -1
        BindOrientations()
    End Sub

    Protected Sub gdvOrientations_RowUpdating(ByVal sender As Object, ByVal e As GridViewUpdateEventArgs)
        Dim txtName As TextBox = gdvOrientations.Rows(e.RowIndex).FindControl("txtName")
        Dim txtDescription As TextBox = gdvOrientations.Rows(e.RowIndex).FindControl("txtDescription")
        Dim hdnProductTypeID As HiddenField = gdvOrientations.Rows(e.RowIndex).FindControl("hdnProductTypeID")
        Dim ddlProductTypes As DropDownList = gdvOrientations.Rows(e.RowIndex).FindControl("ddlProductTypes")
        Dim chkActive As CheckBox = gdvOrientations.Rows(e.RowIndex).FindControl("chkActive")
        Dim active As Int32 = 1
        Dim productTypeID As Int32 = 0

        If (Not Request.Form(chkActive.UniqueID) = "on") Then
            active = 0
        End If

        Int32.TryParse(Request.Form(ddlProductTypes.UniqueID), productTypeID)

        JobManager.SaveOrientation(hdnJobID.Value, gdvOrientations.DataKeys(e.RowIndex).Values(0), txtName.Text, productTypeID, txtDescription.Text, active, String.Empty)

        gdvOrientations.EditIndex = -1
        BindOrientations()
    End Sub

    Sub BindOrientations()
        gdvOrientations.DataSource = JobManager.GetJobOrientationLists(hdnJobID.Value)
        gdvOrientations.DataBind()

        If (gdvOrientations.Rows.Count = 0) Then
            btnAddOrientation_Click(Me, Nothing)
        End If
    End Sub

    Protected Sub btnAddOrientation_Click(ByVal sender As Object, ByVal e As EventArgs)
        pnlOrientationAdd.Visible = True
        ddlPT.DataSource = LookupsManager.GetLookups(LookupType.ProductType, 0, 0, 0)
        ddlPT.DataBind()
    End Sub

    Protected Sub gdvOrientations_RowCreated(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.GridViewRowEventArgs) Handles gdvOrientations.RowCreated
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim active As Boolean = True

            If (DataBinder.Eval(e.Row.DataItem, "IsActive") IsNot Nothing) Then
                Boolean.TryParse(DataBinder.Eval(e.Row.DataItem, "IsActive").ToString(), active)
            End If

            If (Not active) Then
                e.Row.BackColor = Drawing.Color.Yellow
            End If
        End If
    End Sub
End Class
