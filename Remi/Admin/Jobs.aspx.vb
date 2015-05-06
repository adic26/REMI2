Imports REMI.Bll
Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Contracts

Partial Class Admin_TestStages
    Inherits System.Web.UI.Page

#Region "Page Load"
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            If Not UserManager.GetCurrentUser.IsAdmin And Not UserManager.GetCurrentUser.HasAdminReadOnlyAuthority Then
                Response.Redirect("~/")
            End If

            If (UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                lnkAddTestStage.Enabled = False
                lnkSaveAction.Enabled = False
            End If

            If (UserManager.GetCurrentUser.IsTestCenterAdmin And Not (UserManager.GetCurrentUser.IsAdmin)) Then
                Hyperlink1.Enabled = False
                Hyperlink2.Enabled = False

                If (Not UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                    Hyperlink5.Enabled = False
                    Hyperlink7.Enabled = False
                    HyperLink9.Enabled = False
                End If
            End If

            ddlJobs.DataSource = JobManager.GetJobListDT(0, 0, 0)
            ddlJobs.DataBind()

            ddlTestStageType.DataSource = Helpers.GetTestStageTypes
            ddlTestStageType.DataBind()

            LoadJob()
        End If
    End Sub
#End Region

#Region "Methods"
    Protected Sub LoadJob()
        Dim jobID As Int32

        If (Request.QueryString IsNot Nothing AndAlso Not String.IsNullOrEmpty(Request.QueryString.Get("AddJob"))) Then
            jobID = 0
        ElseIf (Request.QueryString IsNot Nothing AndAlso Not String.IsNullOrEmpty(Request.QueryString.Get("JobID"))) Then
            If (ddlJobs.Items.Count > 0) Then
                Int32.TryParse(Request.QueryString("JobID"), jobID)
                ddlJobs.Items.FindByValue(jobID).Selected = True
            End If
        Else
            jobID = ddlJobs.SelectedItem.Value
        End If

        HideEditTestStagePanel()

        If (jobID > 0) Then
            lnkAddJob.Enabled = True
            lnkAddTestStage.Enabled = True
            Dim j As Job = JobManager.GetJob(String.Empty, jobID)
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
            gvwMain.DataSource = TestStageManager.GetList(TestStageType.NotSet, String.Empty, True, j.ID)
            gvwMain.DataBind()

            Dim bs As New BatchSearch()
            bs.JobID = j.ID
            bs.ExcludedStatus = BatchSearchBatchStatus.Complete

            bscJobs.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID, False, False, False, 0, False, False, False, False, False))

            hdnJobID.Value = j.ID

            JobSetup.JobID = j.ID
            JobSetup.BatchID = 0
            JobSetup.ProductID = 0
            JobSetup.JobName = j.Name
            JobSetup.ProductName = String.Empty
            JobSetup.QRANumber = String.Empty
            JobSetup.TestStageType = TestStageType.Parametric
            JobSetup.IsProjectManager = False
            JobSetup.IsAdmin = UserManager.GetCurrentUser.IsAdmin
            JobSetup.HasEditItemAuthority = UserManager.GetCurrentUser.IsAdmin
            JobSetup.RequestTypeID = 0
            JobSetup.UserID = 0
            JobSetup.DataBind()

            acpSetup.Visible = JobSetup.Visible

            JobEnvSetup.JobID = j.ID
            JobEnvSetup.BatchID = 0
            JobEnvSetup.ProductID = 0
            JobEnvSetup.JobName = j.Name
            JobEnvSetup.ProductName = String.Empty
            JobEnvSetup.QRANumber = String.Empty
            JobEnvSetup.TestStageType = TestStageType.EnvironmentalStress
            JobEnvSetup.IsProjectManager = False
            JobEnvSetup.IsAdmin = UserManager.GetCurrentUser.IsAdmin
            JobEnvSetup.HasEditItemAuthority = UserManager.GetCurrentUser.IsAdmin
            JobEnvSetup.RequestTypeID = 0
            JobEnvSetup.UserID = 0
            JobEnvSetup.DataBind()

            acpEnvSetup.Visible = JobEnvSetup.Visible

            BindOrientations()
            BindAccess()
        Else
            lnkAddJob.Enabled = False
            lnkAddTestStage.Enabled = False
            ddlJobs.Visible = False
            txtJobName.Visible = True
            txtJobWILocation.Text = String.Empty
            txtProcedureLocation.Text = String.Empty
            chkIsOperationsTest.Checked = False
            chkIsTechOperationsTest.Checked = False
            chkIsMechanicalTest.Checked = False
            chkIsActive.Checked = False
            chkNoBSN.Checked = False
            chkContinueFailure.Checked = False
            hdnJobID.Value = String.Empty
            accTestStages.Enabled = False
            gvwMain.Enabled = False
        End If
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
            lnkAddTestStage.Enabled = False
        Else
            lnkAddTestStage.Enabled = True
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
        hdnTestID.Value = 0
        hdnTestStageID.Value = 0
        lblAddEditTitle.Text = "Add a new Test Stage"
        pnlAddEditTestStage.Visible = False
        pnlViewAllTestStages.Visible = True
        pnlAddEditTest.Visible = False
        FillFormFieldsforTestStage(New TestStage)
        FillFormFieldsForTest(New TestStage)
    End Sub

    Protected Sub SaveTestStage()
        Dim tmpTestStage As TestStage
        notMain.Clear()

        If Integer.Parse(hdnTestStageID.Value) > 0 Then
            tmpTestStage = TestStageManager.GetTestStage(CInt(hdnTestStageID.Value))
        Else
            tmpTestStage = New TestStage
        End If

        SetTestStageParametersForSave(tmpTestStage)
        tmpTestStage.ID = TestStageManager.SaveTestStage(tmpTestStage) 'save
        notMain.Notifications = tmpTestStage.Notifications
    End Sub

    Protected Function SaveJob() As Int32
        Dim j As Job = New Job

        If (txtJobName.Visible) Then
            j.Name = txtJobName.Text
            j.IsActive = True
        Else
            j.Name = ddlJobs.SelectedItem.Text
            j.ID = ddlJobs.SelectedItem.Value
            j.IsActive = chkIsActive.Checked
        End If

        j.WILocation = txtJobWILocation.Text
        j.IsOperationsTest = chkIsOperationsTest.Checked
        j.IsTechOperationsTest = chkIsTechOperationsTest.Checked
        j.IsMechanicalTest = chkIsMechanicalTest.Checked
        j.ProcedureLocation = txtProcedureLocation.Text
        j.NoBSN = chkNoBSN.Checked
        j.ContinueOnFailures = chkContinueFailure.Checked

        Dim jobID As Int32 = JobManager.SaveJob(j)
        notMain.Notifications.Add(j.Notifications)

        Return jobID
    End Function

    Protected Sub SetTestStageParametersForSave(ByVal tmpTestStage As TestStage)
        tmpTestStage.Name = txtName.Text
        tmpTestStage.JobName = ddlJobs.SelectedItem.Text

        If ddlTestStageType.Visible Then
            tmpTestStage.TestStageType = DirectCast([Enum].Parse(GetType(TestStageType), ddlTestStageType.SelectedItem.Text), TestStageType)
        End If

        Dim processOrder As Int32 = 0
        Dim isArchived As Boolean = False
        Int32.TryParse(txtProcessOrder.Text, processOrder)
        Boolean.TryParse(chkArchived.Checked, isArchived)

        tmpTestStage.ProcessOrder = processOrder
        tmpTestStage.IsArchived = isArchived
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

    Protected Sub BindOrientations()
        gdvOrientations.DataSource = JobManager.GetJobOrientationLists(hdnJobID.Value, String.Empty)
        gdvOrientations.DataBind()

        If (gdvOrientations.Rows.Count = 0) Then
            btnAddOrientation_Click(Me, Nothing)
        End If
    End Sub

    Protected Sub BindAccess()
        grdAccess.DataSource = JobManager.GetJobAccess(hdnJobID.Value, False)
        grdAccess.DataBind()
    End Sub
#End Region

#Region "Events"
    Protected Sub lnkAddTestStage_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddTestStage.Click
        ShowAddEditTestStagePanel(Nothing)
    End Sub

    Protected Sub lnkAddJob_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddJob.Click
        Response.Redirect("~\Admin\Jobs.aspx?AddJob=1")
    End Sub

    Protected Sub lnkCancelAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkCancelAction.Click
        Response.Redirect("~\Admin\Jobs.aspx")
    End Sub

    Protected Sub lnkSaveAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkSaveAction.Click
        If pnlAddEditTestStage.Visible Then
            SaveTestStage()
        Else
            Dim jobID As Int32 = SaveJob()

            If (txtJobName.Visible) Then
                Response.Redirect(String.Format("~\Admin\Jobs.aspx?JobID={0}", jobID))
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
        End If

        If Not notMain.HasErrors Then
            Response.Redirect(String.Format("~\Admin\Jobs.aspx?JobID={0}", hdnJobID.Value))
        End If
    End Sub

    Protected Sub ddlTestStageType_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTestStageType.SelectedIndexChanged
        If DirectCast([Enum].Parse(GetType(TestStageType), ddlTestStageType.SelectedItem.Text), TestStageType) = TestStageType.EnvironmentalStress Then
            pnlAddEditTest.Visible = True
            lstAllTLTypes.DataBind()
        Else
            pnlAddEditTest.Visible = False
        End If
    End Sub

    Protected Sub SetGvwHeader() Handles gvwMain.PreRender
        Helpers.MakeAccessable(gvwMain)
    End Sub

    Protected Sub gdvOrientationsGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles gdvOrientations.PreRender
        Helpers.MakeAccessable(gdvOrientations)
    End Sub

    Protected Sub grdAccessGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdAccess.PreRender
        Helpers.MakeAccessable(grdAccess)
    End Sub

    Protected Sub ddlJobs_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlJobs.SelectedIndexChanged
        Response.Redirect(String.Format("~\Admin\Jobs.aspx?JobID={0}", ddlJobs.SelectedItem.Value))
    End Sub

    Protected Sub btnAddTLType_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnAddTLType.Click
        Dim li As ListItem = lstAllTLTypes.SelectedItem
        lstAddedTLTypes.ClearSelection()
        If li IsNot Nothing Then
            lstAddedTLTypes.Items.Add(li)
            lstAllTLTypes.Items.Remove(li)
        End If
    End Sub

    Protected Sub gvMain_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs)
        Select Case e.CommandName.ToLower()
            Case "editrow"
                notMain.Clear()
                Dim tmpTestStage As TestStage = TestStageManager.GetTestStage(Convert.ToInt32(e.CommandArgument))
                ShowAddEditTestStagePanel(tmpTestStage)
                FillFormFieldsforTestStage(tmpTestStage)
            Case "deleteitem"
                notMain.Notifications.Add(TestStageManager.DeleteTestStage(Convert.ToInt32(e.CommandArgument)))
                gvwMain.DataSource = TestStageManager.GetList(TestStageType.NotSet, String.Empty, True, ddlJobs.SelectedItem.Value)
                gvwMain.DataBind()
        End Select
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

    Protected Sub grdAccess_RowCommand(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.GridViewCommandEventArgs) Handles grdAccess.RowCommand
        Select Case e.CommandName.ToLower()
            Case "deleteaccess"
                JobManager.DeleteAccess(Convert.ToInt32(e.CommandArgument))
        End Select

        BindAccess()
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

        ddlProductTypes.DataSource = LookupsManager.GetLookups("ProductType", 0, 0, String.Empty, String.Empty, 0, False, 0, False)
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

    Protected Sub btnAddOrientation_Click(ByVal sender As Object, ByVal e As EventArgs)
        pnlOrientationAdd.Visible = True
        ddlPT.DataSource = LookupsManager.GetLookups("ProductType", 0, 0, String.Empty, String.Empty, 0, False, 0, False)
        ddlPT.DataBind()
    End Sub

    Protected Sub btnAddAccess_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim departmentID As Int32 = 0
        Int32.TryParse(Request.Form(grdAccess.FooterRow.FindControl("ddlDepartments").UniqueID), departmentID)

        If (departmentID > 0) Then
            Dim success As Boolean = JobManager.SaveAccess(hdnJobID.Value, departmentID)

            If (success) Then
                notMain.Add("Successfully Created New Access", NotificationType.Information)
            Else
                notMain.Add("Failed To Create New Access", NotificationType.Errors)
            End If
        Else
            notMain.Add("Please ensure you have selected a department!", NotificationType.Warning)
        End If
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
#End Region
End Class