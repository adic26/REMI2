Imports Remi.BusinessEntities
Imports Remi.Bll
Imports Remi.Contracts

Partial Class TestRecords_Add
    Inherits System.Web.UI.Page

#Region "Methods"
    Protected Sub ProcessQRA(ByVal qraNumber As String)
        hdnQRANumber.Value = qraNumber
        Dim b As Batch = BatchManager.GetItem(qraNumber)
        hdnBatchID.Value = b.ID

        If b IsNot Nothing Then
            notMain.Clear()
            pnlDetails.Visible = True
            lblTitle.Text = "Add Test Record for " + b.QRANumber
            lblJobName.Text = b.Job.Name
            cblUnit.Items.Add("All")
            cblUnit.DataSource = (From t As TestUnit In b.TestUnits Order By t.BatchUnitNumber Select t.ID, t.BatchUnitNumber)
            cblUnit.DataBind()
            cblUnit.Items(0).Selected = True
            ddlTestStage.DataSource = TestStageManager.GetTestStagesNameByBatch(b.ID, b.JobName)
            ddlTestStage.DataBind()

            If (ddlTestStage.Items.Count > 0) Then
                Dim tests As Object = TestManager.GetTestsByBatchStage(b.ID, ddlTestStage.Items(0).Text, True)
                Dim testID As Int32
                ddlTest.Items.Clear()

                If (tests.Count > 1) Then
                    ddlTest.Items.Add(String.Empty)
                End If

                ddlTest.DataSource = tests
                ddlTest.DataBind()
                Int32.TryParse(ddlTest.SelectedValue, testID)

                If (testID > 0) Then
                    Dim functionalID As Int32 = (From tlt In TestManager.GetTest(testID).TrackingLocationTypes() Where tlt.Name = "Functional Station" Select tlt.ID).FirstOrDefault()

                    If (functionalID > 0) Then
                        rblMFISFIAcc.Enabled = True
                    Else
                        rblMFISFIAcc.Enabled = False
                    End If
                Else
                    rblMFISFIAcc.Enabled = False
                End If
            Else
                'Dim projectManagers = (From ps In New Remi.Dal.Entities().Instance().aspnet_Roles Where ps.KeyName.StartsWith("M") And ps.Product.ID = Me.hdnProductID.Value Select ps.KeyName, ps.ValueText).ToList()
                Dim contacts As DataTable = ProductGroupManager.GetProductContacts(b.ProductID)
                Dim projectManagers As String = String.Empty

                For Each row As DataRow In contacts.Rows
                    If row("ProductManager").ToString() <> String.Empty Then
                        projectManagers = row("ProductManager").ToString() + "@blackberry.com,"
                    End If
                Next

                If (projectManagers = String.Empty) Then
                    projectManagers = "tsdinfrastructure@blackberry.com"
                End If

                notMain.Notifications.AddWithMessage(String.Format("This batch is missing stages. The product managers {0} have been emailed.", projectManagers), Validation.NotificationType.Warning)

                Remi.Core.Emailer.SendMail(projectManagers, "remi@blackebrry.com", String.Format("Batch {0} Test Stages Missing", b.QRANumber), String.Format("Please ensure the setup is done for this batch and product {0}.", b.ProductGroup), False)
            End If

            hypBatchInfo.NavigateUrl = b.BatchInfoLink
            hdnTestRecordLink.Value = b.TestRecordsLink
            hypTestRecords.NavigateUrl = b.TestRecordsLink

            Dim myMenu As WebControls.Menu
            Dim mi As New MenuItem
            myMenu = CType(Master.FindControl("menuHeader"), WebControls.Menu)

            mi.Text = "Batch Info"
            mi.NavigateUrl = b.BatchInfoLink
            myMenu.Items(0).ChildItems.Add(mi)

            mi = New MenuItem
            mi.Text = "Test Records"
            mi.NavigateUrl = b.TestRecordsLink
            myMenu.Items(0).ChildItems.Add(mi)

            rblMFISFIAcc.SelectedValue = 1
        End If
    End Sub

    Private Function AddRecord(ByVal QRANumber As String, ByVal tuID As Integer, ByVal tr As TestRecord) As Boolean
        'save tr
        If tr Is Nothing Then
            Dim testID As Int32 = ddlTest.SelectedValue
            Dim testStageID As Int32 = ddlTestStage.SelectedValue
            tr = New TestRecord(lblJobName.Text, ddlTestStage.SelectedItem.Text, ddlTest.SelectedItem.Text, tuID, UserManager.GetCurrentValidUserLDAPName, testID, testStageID)
            tr.Comments = txtComment.Text
            tr.QRANumber = QRANumber
            tr.Status = DirectCast([Enum].Parse(GetType(TestRecordStatus), ddlResultStatus.SelectedItem.Text), TestRecordStatus)
            tr.ResultSource = TestResultSource.Manual

            If tr.Validate AndAlso TestRecordManager.Save(tr) > 0 Then
                Return True
            Else
                notMain.Notifications.Add(tr.Notifications)
            End If
        Else
            notMain.Notifications.AddWithMessage(String.Format("A test record already exists for unit {0}. You must edit the existing record.", tuID), REMI.Validation.NotificationType.Errors)
        End If
        Return False
    End Function
#End Region

#Region "Page Load"
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            Dim qraNumber As String = Request.QueryString.Get("RN")
            If Not String.IsNullOrEmpty(qraNumber) Then
                ProcessQRA(qraNumber)
            Else
                pnlDetails.Visible = False
                notMain.Notifications.AddWithMessage("Unable to locate batch.", Remi.Validation.NotificationType.Errors)
            End If
        End If
    End Sub
#End Region

#Region "Events"
    Protected Sub ddlTestStage_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTestStage.SelectedIndexChanged
        Dim j As Job = JobManager.GetJobByName(lblJobName.Text)
        Dim tests As Object = TestManager.GetTestsByBatchStage(hdnBatchID.Value, ddlTestStage.SelectedItem.Text, True)
        Dim testID As Int32
        ddlTest.Items.Clear()

        If (tests.Count > 1) Then
            ddlTest.Items.Add(String.Empty)
        End If

        ddlTest.DataSource = tests
        ddlTest.DataBind()

        Int32.TryParse(ddlTest.SelectedValue, testID)

        If (testID > 0) Then
            Dim functionalID As Int32 = (From tlt In TestManager.GetTest(testID).TrackingLocationTypes() Where tlt.Name = "Functional Station" Select tlt.ID).FirstOrDefault()
            If (functionalID > 0) Then
                rblMFISFIAcc.Enabled = True
            Else
                rblMFISFIAcc.Enabled = False
            End If
        Else
            rblMFISFIAcc.Enabled = False
        End If

        If (rblMFISFIAcc.Enabled) Then
            gvwLoad(ddlTestStage.SelectedValue, Convert.ToInt32(ddlTest.SelectedItem.Value))
            pnlRelabMatrix.Visible = True
        Else
            pnlRelabMatrix.Visible = False
            gvwRelabMatrix.DataSource = Nothing
            gvwRelabMatrix.DataBind()
        End If
    End Sub

    Protected Sub ddlResultStatus_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlResultStatus.SelectedIndexChanged, rblMFISFIAcc.SelectedIndexChanged
        Dim trs As TestRecordStatus = DirectCast([Enum].Parse(GetType(TestRecordStatus), ddlResultStatus.SelectedItem.Text), TestRecordStatus)
        If (trs <> TestRecordStatus.Complete And trs <> TestRecordStatus.CompleteFail And trs <> TestRecordStatus.CompleteKnownFailure And trs <> TestRecordStatus.FARaised And trs <> TestRecordStatus.FARequired) Then
            pnlRelabMatrix.Visible = False
        Else
            Dim functionalID As Int32 = (From tlt In TestManager.GetTest(ddlTest.SelectedValue).TrackingLocationTypes() Where tlt.Name = "Functional Station" Select tlt.ID).FirstOrDefault()

            If (functionalID > 0) Then
                pnlRelabMatrix.Visible = True
                gvwLoad(ddlTestStage.SelectedValue, ddlTest.SelectedItem.Value)
            End If
        End If
    End Sub

    Protected Sub cblUnit_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles cblUnit.SelectedIndexChanged
        ddlTest_SelectedIndexChanged(sender, e)
    End Sub

    Protected Sub ddlTest_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTest.SelectedIndexChanged
        If (Not String.IsNullOrEmpty(ddlTest.SelectedValue)) Then
            Dim functionalID As Int32 = (From tlt In TestManager.GetTest(ddlTest.SelectedValue).TrackingLocationTypes() Where tlt.Name = "Functional Station" Select tlt.ID).FirstOrDefault()

            If (functionalID > 0) Then
                rblMFISFIAcc.Enabled = True
            Else
                rblMFISFIAcc.Enabled = False
            End If

            If (rblMFISFIAcc.Enabled) Then
                gvwLoad(ddlTestStage.SelectedValue, Convert.ToInt32(ddlTest.SelectedItem.Value))
                pnlRelabMatrix.Visible = True
            Else
                pnlRelabMatrix.Visible = False
                gvwRelabMatrix.DataSource = Nothing
                gvwRelabMatrix.DataBind()
            End If
        End If
    End Sub

    Protected Sub gvwLoad(ByVal testStageID As Int32, ByVal testID As Int32)
        Dim units As List(Of Int32)

        If (cblUnit.Items(0).Selected) Then
            units = (From item In cblUnit.Items.Cast(Of ListItem)() Where item.Text <> "All" Select Convert.ToInt32(item.Value)).ToList()
        Else
            units = (From item In cblUnit.Items.Cast(Of ListItem)() Where item.Selected = True Select Convert.ToInt32(item.Value)).ToList()
        End If

        If (units.Count > 0) Then
            gvwRelabMatrix.DataSource = RelabManager.FunctionalMatrixByTestRecord(Nothing, testStageID, testID, BatchManager.GetItem(Request.QueryString.Get("RN")).ID, String.Join(",", units.ConvertAll(Of String)(Function(j As Integer) j.ToString()).ToArray()), rblMFISFIAcc.SelectedValue)
            gvwRelabMatrix.DataBind()

            If (gvwRelabMatrix.HeaderRow IsNot Nothing) Then
                gvwRelabMatrix.HeaderRow.Cells(0).Visible = False
            End If
        End If
    End Sub

    Protected Sub gvwRelabMatrix_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwRelabMatrix.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            e.Row().Cells(0).Visible = False

            For i As Integer = 2 To e.Row().Cells.Count - 1
                Dim chkPass As New CheckBox()
                Dim chkFail As New CheckBox()
                chkPass.BackColor = Drawing.Color.Green
                chkFail.BackColor = Drawing.Color.Red
                chkPass.ID = String.Format("Pass{0}{1}", e.Row().Cells(1).Text, Me.gvwRelabMatrix.HeaderRow().Cells(i).Text)
                chkFail.ID = String.Format("Fail{0}{1}", e.Row().Cells(1).Text, Me.gvwRelabMatrix.HeaderRow().Cells(i).Text)

                If (e.Row().Cells(i).Text = "1") Then
                    chkPass.Checked = True
                End If
                If (e.Row().Cells(i).Text = "0") Then
                    chkFail.Checked = True
                End If

                e.Row().Cells(i).Controls.Add(chkPass)
                e.Row().Cells(i).Controls.Add(chkFail)

                Dim chkP As CheckBox = DirectCast(e.Row().Cells(i).Controls(0), System.Web.UI.WebControls.CheckBox)
                Dim chkF As CheckBox = DirectCast(e.Row().Cells(i).Controls(1), System.Web.UI.WebControls.CheckBox)
                chkP.InputAttributes.Add("onclick", "JavaScript: uncheck('" + chkF.ClientID + "');")
                chkF.InputAttributes.Add("onclick", "JavaScript: uncheck('" + chkP.ClientID + "');")
            Next
        End If
    End Sub

    Protected Sub btnDetailCancel_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnDetailCancel.Click
        Response.Redirect(hdnTestRecordLink.Value)
    End Sub

    Protected Sub SetGvwHeader() Handles gvwRelabMatrix.PreRender
        Helpers.MakeAccessable(gvwRelabMatrix)
    End Sub

    Protected Sub btnDetailDone_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnDetailDone.Click
        'Adding test record here.
        Try
            Dim b As Batch = BatchManager.GetItem(hdnQRANumber.Value)
            If b.TestUnits.Count > 0 Then
                Dim units As List(Of Int32)

                If (cblUnit.Items(0).Selected) Then
                    units = (From item In cblUnit.Items.Cast(Of ListItem)() Where item.Text <> "All" Select Convert.ToInt32(item.Value)).ToList()
                Else
                    units = (From item In cblUnit.Items.Cast(Of ListItem)() Where item.Selected = True Select Convert.ToInt32(item.Value)).ToList()
                End If

                If (units.Count > 0) Then
                    For Each id As Int32 In units
                        Dim tmptr As TestRecord = (From tr In b.TestRecords Where tr.JobName = lblJobName.Text AndAlso tr.TestStageID = ddlTestStage.SelectedValue _
                                    AndAlso tr.TestID = ddlTest.SelectedValue AndAlso tr.TestUnitID = id Select tr).SingleOrDefault

                        If AddRecord(b.QRANumber, id, tmptr) Then
                            notMain.Notifications.AddWithMessage(String.Format("The record for {0} was saved ok.", id), REMI.Validation.NotificationType.Information)
                        End If
                    Next

                    If (rblMFISFIAcc.Enabled) Then
                        Dim testID As Int32 = ddlTest.SelectedValue
                        Dim testStageID As Int32 = ddlTestStage.SelectedValue

                        Dim gv As GridView = DirectCast(Me.FindControl(gvwRelabMatrix.UniqueID), GridView)
                        For i As Int32 = 0 To gvwRelabMatrix.Rows.Count - 1
                            For j As Integer = 2 To gvwRelabMatrix.Rows(i).Cells.Count - 1
                                Dim testUnitNum As Int32 = Me.gvwRelabMatrix.Rows(i).Cells(1).Text
                                Dim lookup As String = Me.gvwRelabMatrix.HeaderRow().Cells(j).Text
                                Dim passFail As Int32 = -1
                                Dim idP As String = String.Format("{0}$Pass{1}{2}", gvwRelabMatrix.Rows(i).UniqueID, testUnitNum, lookup)
                                Dim idF As String = String.Format("{0}$Fail{1}{2}", gvwRelabMatrix.Rows(i).UniqueID, testUnitNum, lookup)

                                If (Request.Form(idP) = "on") Then
                                    passFail = 1
                                ElseIf (Request.Form(idF) = "on") Then
                                    passFail = 0
                                Else
                                    passFail = -1
                                End If

                                If (passFail > -1) Then
                                    Dim type As String

                                    Select Case rblMFISFIAcc.SelectedValue
                                        Case 1
                                            type = "SFIFunctionalMatrix"
                                        Case 2
                                            type = "MFIFunctionalMatrix"
                                        Case 3
                                            type = "AccFunctionalMatrix"
                                        Case Else
                                            type = "SFIFunctionalMatrix"
                                    End Select

                                    TestRecordManager.InsertRelabRecordMeasurement(testID, testStageID, (From tu In b.TestUnits Where tu.BatchUnitNumber = testUnitNum Select tu.ID).FirstOrDefault(), LookupsManager.GetLookupID(type, lookup, 0), IIf(passFail = 0, False, True), rblMFISFIAcc.Enabled)
                                End If
                            Next
                        Next
                    End If
                Else
                    notMain.Notifications.AddWithMessage("Please Select Units.", REMI.Validation.NotificationType.Information)
                End If
            Else
                notMain.Notifications.AddWithMessage("Unable to save the test record: No units in this batch.", REMI.Validation.NotificationType.Errors)
            End If
        Catch ex As Exception
            notMain.Notifications.AddWithMessage("Unable to save the test record: " + ex.Message, REMI.Validation.NotificationType.Errors)
        End Try

        If Not notMain.HasErrors Then
            Response.Redirect(hdnTestRecordLink.Value)
        End If
    End Sub
#End Region
End Class