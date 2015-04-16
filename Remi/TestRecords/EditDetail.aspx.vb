Imports REMI.BusinessEntities
Imports REMI.Bll
Imports REMI.Validation
Imports REMI.Contracts

Partial Class TestRecords_EditDetail
    Inherits System.Web.UI.Page

#Region "Page Load"
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            Dim trID As Integer
            If Integer.TryParse(Request.QueryString.Get("trID"), trID) Then
                ProcessTRID(trID)
            Else
                pnlDetails.Visible = False
                notMain.Notifications.AddWithMessage("Unable to find test record.", Remi.Validation.NotificationType.Errors)
            End If
        End If
    End Sub
#End Region

#Region "Button Events"
    Protected Sub btnDetailCancel_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnDetailCancel.Click
        Response.Redirect(hdnTestRecordLink.Value)
    End Sub

    Protected Sub grdAuditLogGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdAuditLog.PreRender
        Helpers.MakeAccessable(grdAuditLog)
    End Sub

    Protected Sub grdAuditLog_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdAuditLog.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            e.Row.Cells(4).Text = System.Enum.Parse(GetType(TestRecordStatus), e.Row.Cells(4).Text).ToString()
            e.Row.Cells(10).Text = System.Enum.Parse(GetType(TestResultSource), e.Row.Cells(10).Text).ToString()
        End If
    End Sub

    Protected Sub btnDetailDone_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnDetailDone.Click
        notMain.Notifications = TestRecordManager.UpdateStatus(hdnTRID.Value, DirectCast([Enum].Parse(GetType(TestRecordStatus), ddlResultStatus.SelectedItem.Text), TestRecordStatus), txtComment.Text, chkApplyToSimilarResults.Checked)

        If (rblMFISFIAcc.Enabled) Then
            Dim testID As Int32 = hdnTestID.Value
            Dim testStageID As Int32 = hdnTestStageID.Value

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

                        TestRecordManager.InsertRelabRecordMeasurement(testID, testStageID, hdnUnitID.Value, LookupsManager.GetLookupID(type, lookup, 0), IIf(passFail = 0, False, True), rblMFISFIAcc.Enabled)
                    End If
                Next
            Next
        End If

        If Not notMain.HasErrors Then
            Response.Redirect(hdnTestRecordLink.Value)
        End If
    End Sub

    Protected Sub btnAssignAnyFailDoc_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnAssignAnyFailDoc.Click
        notMain.Notifications = TestRecordManager.AddCaterDocument(hdnTRID.Value, txtAssignAnyFailDoc.Text, txtComment.Text, chkApplyToSimilarResults.Checked)
        ProcessTRID(hdnTRID.Value)
    End Sub
#End Region

#Region "Events"
    Protected Sub ddlResultStatus_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlResultStatus.SelectedIndexChanged, rblMFISFIAcc.SelectedIndexChanged
        Dim trs As TestRecordStatus = DirectCast([Enum].Parse(GetType(TestRecordStatus), ddlResultStatus.SelectedItem.Text), TestRecordStatus)
        If (trs <> TestRecordStatus.Complete And trs <> TestRecordStatus.CompleteFail And trs <> TestRecordStatus.CompleteKnownFailure And trs <> TestRecordStatus.FARaised And trs <> TestRecordStatus.FARequired) Then
            pnlRelabMatrix.Visible = False
        Else
            Dim functionalID As Int32 = (From tlt In TestManager.GetTest(hdnTestID.Value, String.Empty, False).TrackingLocationTypes() Where tlt.Name = "Functional Station" Select tlt.ID).FirstOrDefault()

            If (functionalID > 0) Then
                gvwRelabMatrix.DataSource = RelabManager.FunctionalMatrixByTestRecord(hdnTRID.Value, hdnTestStageID.Value, hdnTestID.Value, hdnBatchID.Value, Nothing, rblMFISFIAcc.SelectedValue)
                gvwRelabMatrix.DataBind()
                pnlRelabMatrix.Visible = True

                If (gvwRelabMatrix.HeaderRow IsNot Nothing) Then
                    gvwRelabMatrix.HeaderRow.Cells(0).Visible = False
                End If
            End If
        End If

        rptFAList.DataSource = (From fd In TestRecordManager.GetFailDocs(hdnQRANumber.Value, hdnTRID.Value) Select New With {.RequestNumber = fd.Item("RequestNumber"), .RequestLink = fd.Item("Request Link"), .Summary = fd.Item("Summary")}).ToList()
        rptFAList.DataBind()
    End Sub

    Protected Sub odsTrackingLogs_Selecting(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.ObjectDataSourceSelectingEventArgs) Handles odsTrackingLogs.Selecting
        e.InputParameters("trid") = hdnTRID.Value
    End Sub

    Protected Sub rptFAList_ItemCommand(ByVal sender As Object, ByVal e As DataListCommandEventArgs) Handles rptFAList.ItemCommand
        rptFAList.SelectedIndex = e.Item.ItemIndex
        notMain.Notifications = TestRecordManager.AddCaterDocument(hdnTRID.Value, rptFAList.DataKeys(rptFAList.SelectedIndex), txtComment.Text, chkApplyToSimilarResults.Checked)
        ProcessTRID(hdnTRID.Value)

        rptFAList.DataSource = (From fd In TestRecordManager.GetFailDocs(hdnQRANumber.Value, hdnTRID.Value) Select New With {.RequestNumber = fd.Item("RequestNumber"), .RequestLink = fd.Item("Request Link"), .Summary = fd.Item("Summary")}).ToList()
        rptFAList.DataBind()
    End Sub

    Protected Sub SetGvwHeader() Handles gvwRelabMatrix.PreRender
        Helpers.MakeAccessable(gvwRelabMatrix)
    End Sub

    Protected Sub updateGridviewHeaders() Handles grdTrackingLog.PreRender
        Helpers.MakeAccessable(grdTrackingLog)
    End Sub

    Protected Sub rptDocList_ItemCommand(ByVal source As Object, ByVal e As System.Web.UI.WebControls.RepeaterCommandEventArgs) Handles rptDocList.ItemCommand
        notMain.Notifications = TestRecordManager.RemoveCaterDocument(hdnTRID.Value, e.CommandArgument, txtComment.Text, chkApplyToSimilarResults.Checked)
        ProcessTRID(hdnTRID.Value)
        rptFAList.DataSource = (From fd In TestRecordManager.GetFailDocs(hdnQRANumber.Value, hdnTRID.Value) Select New With {.RequestNumber = fd.Item("RequestNumber"), .RequestLink = fd.Item("Request Link"), .Summary = fd.Item("Summary")}).ToList()
        rptFAList.DataBind()
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
#End Region

#Region "Methods"
    Protected Sub ProcessTRID(ByVal trID As Integer)
        hdnTRID.Value = trID
        Dim tr As TestRecord
        tr = TestRecordManager.GetItemByID(trID)

        If tr IsNot Nothing Then
            pnlDetails.Visible = True
            hdnTestRecordLink.Value = tr.TestRecordsLink
            rptDocList.DataSource = (From fd In tr.FailDocs Select New With {.RequestNumber = fd.Item("RequestNumber"), .RequestLink = fd.Item("Request Link")}).ToList()
            rptDocList.DataBind()

            rptFAList.DataSource = (From fd In TestRecordManager.GetFailDocs(tr.QRANumber, tr.ID) Select New With {.RequestNumber = fd.Item("RequestNumber"), .RequestLink = fd.Item("Request Link"), .Summary = fd.Item("Summary")}).ToList()
            rptFAList.DataBind()
            hdnQRANumber.Value = tr.QRANumber
            lblResultText.Text = tr.TestIdentificationString
            txtComment.Text = tr.Comments
            hypBatchInfo.NavigateUrl = tr.BatchInfoLink
            hypTestRecords.NavigateUrl = tr.TestRecordsLink
            ddlResultStatus.SelectedValue = tr.Status.ToString
            hdnTestID.Value = tr.TestID
            hdnTestStageID.Value = tr.TestStageID
            odsTrackingLogs.DataBind()
            hdnUnitID.Value = tr.TestUnitID
            hdnBatchID.Value = BatchManager.GetItem(tr.QRANumber).ID
            lblReTestCount.Text = tr.CurrentRelabResultVersion

            Dim myMenu As WebControls.Menu
            Dim mi As New MenuItem
            myMenu = CType(Master.FindControl("menuHeader"), WebControls.Menu)

            mi.Text = "Batch Info"
            mi.NavigateUrl = tr.BatchInfoLink
            myMenu.Items(0).ChildItems.Add(mi)

            mi = New MenuItem
            mi.Text = "Test Records"
            mi.NavigateUrl = tr.TestRecordsLink
            myMenu.Items(0).ChildItems.Add(mi)

            Dim functionalID As Int32 = (From tlt In TestManager.GetTest(tr.TestID, String.Empty, False).TrackingLocationTypes() Where tlt.Name = "Functional Station" Select tlt.ID).FirstOrDefault()

            If (functionalID > 0) Then
                rblMFISFIAcc.Enabled = True
            End If

            If (Not UserManager.GetCurrentUser.IsAdmin And Not UserManager.GetCurrentUser.IsTestCenterAdmin) Then
                rblMFISFIAcc.Enabled = False
            End If

            If (tr.FunctionalType = 0) Then
                rblMFISFIAcc.SelectedValue = 1
            Else
                rblMFISFIAcc.SelectedValue = tr.FunctionalType
            End If

            If (rblMFISFIAcc.Enabled) Then
                gvwRelabMatrix.DataSource = RelabManager.FunctionalMatrixByTestRecord(tr.ID, tr.TestStageID, tr.TestID, hdnBatchID.Value, Nothing, tr.FunctionalType)
                gvwRelabMatrix.DataBind()
                pnlRelabMatrix.Visible = True

                If (gvwRelabMatrix.HeaderRow IsNot Nothing) Then
                    gvwRelabMatrix.HeaderRow.Cells(0).Visible = False
                End If
            Else
                pnlRelabMatrix.Visible = False
                gvwRelabMatrix.DataSource = Nothing
                gvwRelabMatrix.DataBind()
            End If
        End If
    End Sub
#End Region
End Class