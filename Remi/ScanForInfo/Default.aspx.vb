Imports REMI.BusinessEntities
Imports REMI.Bll
Imports REMI.Validation
Imports REMI.Contracts

Partial Class ScanForInfo_Default
    Inherits System.Web.UI.Page

    Protected Sub btnSubmit_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSubmit.Click
        Response.Redirect(String.Format("{0}?RN={1}", Helpers.GetCurrentPageName, Helpers.CleanInputText(txtBarcodeReading.Text, 30)), True)
    End Sub

    Protected Sub grdTrackingLogGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdTrackingLog.PreRender
        Helpers.MakeAccessable(grdTrackingLog)
    End Sub

    Protected Sub grdJIRASGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdJIRAS.PreRender
        Helpers.MakeAccessable(grdJIRAS)
    End Sub

    Protected Sub gvwRequestInfoGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwRequestInfo.PreRender
        Helpers.MakeAccessable(gvwRequestInfo)
    End Sub

    Protected Sub grdDetailGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdDetail.PreRender
        Helpers.MakeAccessable(grdDetail)
    End Sub

    Protected Sub gvwTestExceptionsGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwTestExceptions.PreRender
        gvwTestExceptions.PagerSettings.Mode = PagerButtons.NumericFirstLast
        Helpers.MakeAccessable(gvwTestExceptions)
    End Sub

    Protected Sub gvwTaskAssignmentsGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwTaskAssignments.PreRender
        Helpers.MakeAccessable(gvwTaskAssignments)
    End Sub

    Protected Sub gvwDocuemntsGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwDocuemnts.PreRender
        Helpers.MakeAccessable(gvwDocuemnts)
    End Sub

    Protected Sub grdAuditLogGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdAuditLog.PreRender
        Helpers.MakeAccessable(grdAuditLog)
    End Sub

    Protected Sub SetGvwHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.PreRender
        lblNotificationHeader.Text = String.Format("Notifications ({0})", notMain.Notifications.Count)
        lblAccordionCommentsSectionHeader.Text = String.Format("Comments ({0})", rptBatchComments.Items.Count)
        lblUnitCount.Text = String.Format("Unit Info ({0})", grdDetail.Rows.Count)
    End Sub

    Protected Sub btnAddComment_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        If (txtNewCommentText.Text.Trim().Length > 0) Then
            If (BatchManager.AddNewComment(hdnQRANumber.Value, txtNewCommentText.Text).Count <= 0) Then
                rptBatchComments.DataSource = BatchManager.GetBatchComments(hdnQRANumber.Value)
                rptBatchComments.DataBind()
                lblAccordionCommentsSectionHeader.Text = String.Format("Comments ({0})", rptBatchComments.Items.Count)
                UpdatePanel1.Update()
                txtNewCommentText.Text = String.Empty
            End If
        End If
    End Sub

    Protected Sub lnkDeleteComment_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim lnkButtonClicked As LinkButton = DirectCast(sender, LinkButton)
        BatchManager.DeactivateComment(CInt(lnkButtonClicked.CommandArgument))
        rptBatchComments.DataSource = BatchManager.GetBatchComments(hdnQRANumber.Value)
        rptBatchComments.DataBind()

        lblAccordionCommentsSectionHeader.Text = String.Format("Comments ({0})", rptBatchComments.Items.Count)
        UpdatePanel1.Update()
    End Sub

    Protected Sub grdDetail_RowCommand(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.GridViewCommandEventArgs) Handles grdDetail.RowCommand
        Select Case e.CommandName.ToLower()
            Case "deleteunit"
                If (UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin) Then
                    TestUnitManager.DeleteUnit(Convert.ToInt32(e.CommandArgument))
                End If
        End Select

        Dim b As BatchView = BatchManager.GetViewBatch(Request.QueryString.Get("RN"))
        grdDetail.DataSource = b.TestUnits
        grdDetail.DataBind()
    End Sub

    Protected Sub gvwRequestInfo_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwRequestInfo.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim lblValue As Label = DirectCast(e.Row.FindControl("lblValue"), Label)
            Dim hylValue As HyperLink = DirectCast(e.Row.FindControl("hylValue"), HyperLink)
            Dim hdnType As HiddenField = DirectCast(e.Row.FindControl("hdnType"), HiddenField)

            If (DirectCast(e.Row.DataItem, REMI.BusinessEntities.RequestFields).Sibling.Count > 0) Then
                hylValue.Visible = False

                For Each s As Sibling In DirectCast(e.Row.DataItem, REMI.BusinessEntities.RequestFields).Sibling
                    If (Not String.IsNullOrEmpty(s.Value)) Then
                        If (hdnType.Value = "Link") Then
                            Dim hyp As New HyperLink
                            hyp.Text = s.Value
                            hyp.Target = "_blank"
                            hyp.NavigateUrl = s.Value
                            hyp.ID = String.Format("{0}_{1}", s.FieldSetupID, s.ID)
                            e.Row.Cells(1).Style.Add("text-align", "left")
                            e.Row.Cells(1).Controls.Add(hyp)
                            e.Row.Cells(1).Controls.Add(New LiteralControl("<br />"))
                        Else
                            Dim lbl As New Label
                            lbl.Text = s.Value
                            lbl.ID = String.Format("{0}_{1}", s.FieldSetupID, s.ID)
                            e.Row.Cells(1).Style.Add("text-align", "left")
                            e.Row.Cells(1).Controls.Add(lbl)
                            e.Row.Cells(1).Controls.Add(New LiteralControl("<br />"))
                        End If
                    End If
                Next
            Else
                If (hdnType.Value = "Link") Then
                    lblValue.Visible = False
                    hylValue.Visible = True
                Else
                    lblValue.Visible = True
                    hylValue.Visible = False
                End If
            End If
        End If
    End Sub

    Protected Sub grdAuditLog_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdAuditLog.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            e.Row.Cells(2).Text = System.Enum.Parse(GetType(BatchStatus), e.Row.Cells(2).Text).ToString()
            e.Row.Cells(8).Text = e.Row.Cells(8).Text
        End If
    End Sub

    Protected Sub grdDetail_ItemDataBound(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.RepeaterItemEventArgs) Handles rptBatchComments.ItemDataBound
        Dim lnkDeleteComment As LinkButton = DirectCast(e.Item.FindControl("lnkDeleteComment"), LinkButton)
        Dim hdnUserName As HiddenField = DirectCast(e.Item.FindControl("hdnUserName"), HiddenField)

        If (lnkDeleteComment IsNot Nothing) Then
            lnkDeleteComment.Visible = Remi.Bll.UserManager.GetCurrentUser().HasEditBatchCommentsAuthority(hdnDepartmentID.Value) Or hdnUserName.Value = Remi.Bll.UserManager.GetCurrentValidUserLDAPName
        End If
    End Sub

    Protected Sub grdDetail_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdDetail.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim lnkDelete As LinkButton = DirectCast(e.Row.FindControl("lnkDelete"), LinkButton)

            If (UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin) And DirectCast(e.Row.DataItem, Remi.BusinessEntities.TestUnit).CanDelete Then
                lnkDelete.Visible = True
            Else
                lnkDelete.Visible = False
            End If
        End If
    End Sub

    Protected Sub gvwTaskAssignment_Command(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.GridViewCommandEventArgs) Handles gvwTaskAssignments.RowCommand
        Select Case e.CommandName.ToLower()
            Case "removetaskassignment"
                TestStageManager.RemoveTaskAssignment(hdnQRANumber.Value, CInt(e.CommandArgument))
            Case "reassigntask"
                Dim currentRow As GridViewRow = DirectCast(DirectCast(e.CommandSource, Button).NamingContainer, GridViewRow)
                Dim currentTextInput As TextBox = currentRow.Cells(2).FindControl("txtAssignTaskToUser")
                TestStageManager.AddUpdateTaskAssignment(hdnQRANumber.Value, CInt(e.CommandArgument), currentTextInput.Text)
        End Select

        gvwTaskAssignments.DataSource = LoadAssignments(hdnQRANumber.Value)
        gvwTaskAssignments.DataBind()
    End Sub

    Protected Function LoadAssignments(ByVal qraNumber As String) As List(Of BaseObjectModels.TaskAssignment)
        Return TestStageManager.GetListOfTaskAssignments(qraNumber)
    End Function

    Protected Sub ProcessQRA(ByVal tmpStr As String)
        Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(tmpStr))
        Dim b As BatchView

        If bc.Validate Then
            b = BatchManager.GetViewBatch(bc.BatchNumber)

            If b IsNot Nothing And b.ID > 0 Then
                lnkCheckForUpdates2.Enabled = True
                lnkCheckForUpdates.Enabled = True
                ddlTime.Enabled = True

                If (b.ProductID = 0 And b.ProductGroup IsNot Nothing) Then
                    b.ProductID = (From l In New Remi.Dal.Entities().Instance().Lookups Where l.Values = b.ProductGroup Select l.LookupID).FirstOrDefault()
                End If

                If (UserManager.GetCurrentUser.ByPassProduct Or (From up In UserManager.GetCurrentUser.UserDetails.Rows Where up("Values") = b.ProductGroup Select up("Values")).FirstOrDefault() <> Nothing) Then
                    Dim litTitle As Literal = Master.FindControl("litPageTitle")

                    If litTitle IsNot Nothing Then
                        litTitle.Text = "REMI - " + bc.BatchNumber
                    End If

                    Dim bcol As New BatchCollection
                    bcol.Add(b)

                    If (b.Status = BatchStatus.Complete) Then
                        lblResult.Visible = True
                        lblResult.Text = RelabManager.GetOverAllPassFail(b.ID).Tables(2).Rows(0)(0).ToString()

                        Select Case lblResult.Text.ToLower
                            Case "pass"
                            Case "un-verified pass"
                                lblResult.CssClass = "ESPass"
                            Case "fail"
                            Case "un-verified fail"
                                lblResult.CssClass = "ESFail"
                            Case "no result"
                                lblResult.CssClass = "ESNoResult"
                        End Select
                    End If

                    rptBatchComments.DataSource = b.Comments
                    rptBatchComments.DataBind()
                    bscMain.SetBatches(bcol)
                    notMain.Notifications.Add(b.GetAllNotifications(True))
                    grdDetail.DataSource = b.TestUnits
                    grdDetail.DataBind()
                    lblQRANumber.Text = bc.BatchNumber
                    hdnQRANumber.Value = bc.ToString
                    hdnBatchID.Value = b.ID
                    hdnDepartmentID.Value = b.DepartmentID
                    grdTrackingLog.DataBind()

                    If b.Status = BatchStatus.Complete Then
                        lblTestingSummary.Text = "Testing Summary"

                        If b.JobName.ToLower.Contains("drop") Then
                            lblStressingSummary.Text = "Drop Summary"
                            gvwStressingSummary.EmptyDataText = "No Drop Results"
                        ElseIf b.JobName.ToLower.Contains("tumble") Then
                            lblStressingSummary.Text = "Tumble Summary"
                            gvwStressingSummary.EmptyDataText = "No Tumble Results"
                        Else
                            lblStressingSummary.Text = "Stressing Summary"
                            gvwStressingSummary.EmptyDataText = "No Stressing Results"
                        End If
                    Else
                        lblTestingSummary.Text = "Testing Status"

                        If b.JobName.ToLower.Contains("drop") Then
                            lblStressingSummary.Text = "Drop Status"
                            gvwStressingSummary.EmptyDataText = "No Drop Results"
                        ElseIf b.JobName.ToLower.Contains("tumble") Then
                            lblStressingSummary.Text = "Tumble Status"
                            gvwStressingSummary.EmptyDataText = "No Tumble Results"
                        Else
                            lblStressingSummary.Text = "Stressing Status"
                            gvwStressingSummary.EmptyDataText = "No Stressing Results"
                        End If
                    End If

                    If (b.Orientation IsNot Nothing) Then
                        lblOrientation.Text = String.Format("Orientation/Sequence: {0}", b.Orientation.Name)
                    Else
                        lblOrientation.Text = String.Empty
                    End If

                    Dim records = (From rm In New REMI.Dal.Entities().Instance().ResultsMeasurements _
                                      Where rm.Result.TestUnit.Batch.ID = b.ID And rm.Archived = False _
                                      Select New With {.RID = rm.Result.ID, .TestID = rm.Result.Test.ID, .TestStageID = rm.Result.TestStage.ID, .UN = rm.Result.TestUnit.BatchUnitNumber}).Distinct.ToArray

                    Dim rqResults As New DataTable
                    rqResults.Columns.Add("RID", GetType(Int32))
                    rqResults.Columns.Add("TestID", GetType(Int32))
                    rqResults.Columns.Add("TestStageID", GetType(Int32))
                    rqResults.Columns.Add("UN", GetType(Int32))

                    For Each rec In records
                        Dim row As DataRow = rqResults.NewRow
                        row("RID") = rec.RID
                        row("TestID") = rec.TestID
                        row("TestStageID") = rec.TestStageID
                        row("UN") = rec.UN
                        rqResults.Rows.Add(row)
                    Next

                    gvwTestingSummary.DataSource = b.GetParametricTestOverviewTable(UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID), UserManager.GetCurrentUser.IsTestCenterAdmin, rqResults, UserManager.GetCurrentUser.HasBatchSetupAuthority(b.DepartmentID), True)
                    gvwTestingSummary.DataBind()
                    gvwStressingSummary.DataSource = b.GetStressingOverviewTable(UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID), UserManager.GetCurrentUser.IsTestCenterAdmin, UserManager.GetCurrentUser.HasBatchSetupAuthority(b.DepartmentID), True, If(b.Orientation IsNot Nothing, b.Orientation.Definition, String.Empty))
                    gvwStressingSummary.DataBind()

                    setup.JobID = b.JobID
                    setup.BatchID = b.ID
                    setup.ProductID = b.ProductID
                    setup.JobName = b.JobName
                    setup.ProductName = b.ProductGroup
                    setup.QRANumber = b.QRANumber
                    setup.TestStageType = TestStageType.Parametric
                    setup.IsProjectManager = (From p In UserManager.GetCurrentUser.UserDetails Where p.Field(Of String)("Name") = "Products" And p.Field(Of String)("Values") = b.ProductGroup Select p.Field(Of Boolean)("IsProductManager")).FirstOrDefault()
                    setup.IsAdmin = UserManager.GetCurrentUser.IsAdmin
                    setup.HasEditItemAuthority = UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID) Or UserManager.GetCurrentUser.IsTestCenterAdmin Or UserManager.GetCurrentUser.HasBatchSetupAuthority(b.DepartmentID)
                    setup.OrientationID = 0
                    setup.UserID = UserManager.GetCurrentUser.ID
                    setup.RequestTypeID = b.ReqData(0).RequestTypeID
                    setup.DataBind()

                    setupStressing.JobID = b.JobID
                    setupStressing.BatchID = b.ID
                    setupStressing.ProductID = b.ProductID
                    setupStressing.JobName = b.JobName
                    setupStressing.ProductName = b.ProductGroup
                    setupStressing.QRANumber = b.QRANumber
                    setupStressing.TestStageType = TestStageType.EnvironmentalStress
                    setupStressing.IsProjectManager = (From p In UserManager.GetCurrentUser.UserDetails Where p.Field(Of String)("Name") = "Products" And p.Field(Of String)("Values") = b.ProductGroup Select p.Field(Of Boolean)("IsProductManager")).FirstOrDefault()
                    setupStressing.IsAdmin = UserManager.GetCurrentUser.IsAdmin
                    setupStressing.HasEditItemAuthority = UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID) Or UserManager.GetCurrentUser.IsTestCenterAdmin Or UserManager.GetCurrentUser.HasBatchSetupAuthority(b.DepartmentID)
                    setupStressing.OrientationID = If(b.Orientation Is Nothing, 0, b.Orientation.ID)
                    setupStressing.RequestTypeID = b.ReqData(0).RequestTypeID
                    setupStressing.UserID = UserManager.GetCurrentUser.ID
                    setupStressing.DataBind()

                    If (setup.HasEditItemAuthority) Then
                        btnEdit.Visible = True
                        btnEditStressing.Visible = True
                    Else
                        btnEdit.Visible = False
                        btnEditStressing.Visible = False
                    End If

                    txtExecutiveSummary.Text = b.ExecutiveSummary
                    Dim isExternal As Boolean = (From rd In b.ReqData Select rd.IsFromExternalSystem).FirstOrDefault()

                    If (((From p In UserManager.GetCurrentUser.UserDetails Where p.Field(Of String)("Name") = "Products" And p.Field(Of String)("Values") = b.ProductGroup Select p.Field(Of Boolean)("IsProductManager")).FirstOrDefault() Or UserManager.GetCurrentUser.IsAdmin) And Not (isExternal)) Then
                        txtExecutiveSummary.Enabled = True
                        btnExecutiveSummary.Visible = True
                    End If

                    gvwTaskAssignments.DataSource = LoadAssignments(b.QRANumber)
                    gvwTaskAssignments.DataBind()

                    gvwRequestInfo.DataSource = b.ReqData
                    gvwRequestInfo.DataBind()

                    Dim es As New ExceptionSearch()
                    es.QRANumber = b.QRANumber
                    es.IncludeBatches = 1
                    gvwTestExceptions.DataSource = REMI.Dal.TestExceptionDB.ExceptionSearch(es)
                    gvwTestExceptions.DataBind()

                    JIRABindData()

                    'sets the accordion open pane
                    accMain.SelectedIndex = 7

                    updComments.Update()
                    SetupMenuItems(b)
                End If
            Else
                notMain.Notifications.AddWithMessage(String.Format("{0} could not be found in REMI.", bc.ToString), NotificationType.Errors)
            End If
        Else
            notMain.Notifications = bc.Notifications
            Exit Sub
        End If
    End Sub

    <System.Web.Services.WebMethod()> _
    Public Shared Function AddException(ByVal jobname As String, ByVal teststagename As String, ByVal testname As String, ByVal qraNumber As String, ByVal unitcount As String, ByVal unitnumber As String) As Boolean
        Dim tex As New TestException()
        Dim nc As Notification
        Dim count As Integer = 1
        Dim hasSuccess As Boolean = True

        tex.TestStageName = teststagename
        tex.TestName = testname
        tex.JobName = jobname
        tex.QRAnumber = qraNumber

        If (unitcount = 0) Then
            tex.UnitNumber = unitnumber
            nc = ExceptionManager.AddException(tex)

            If (nc.Message <> "Exception saved ok.") Then
                hasSuccess = False
            End If
        Else
            While count <= unitcount
                tex.UnitNumber = count
                nc = ExceptionManager.AddException(tex)
                count += 1

                If (nc.Message <> "Exception saved ok.") Then
                    hasSuccess = False
                End If
            End While
        End If

        Return hasSuccess
    End Function

    Protected Sub JIRABindData()
        grdJIRAS.DataSource = BatchManager.GetBatchJIRA(hdnBatchID.Value, True)
        grdJIRAS.DataBind()
    End Sub

    Protected Sub Page_PreRender() Handles Me.PreRender
        For Each r As GridViewRow In gvwTestingSummary.Rows
            For Each c As TableCell In r.Cells
                c.Text = System.Web.HttpUtility.HtmlDecode(c.Text)
            Next
        Next

        For Each r As GridViewRow In gvwStressingSummary.Rows
            For Each c As TableCell In r.Cells
                c.Text = System.Web.HttpUtility.HtmlDecode(c.Text)
            Next
        Next
    End Sub

    Protected Sub btnExecutiveSummary_OnClick(ByVal sender As Object, ByVal e As System.EventArgs)
        BatchManager.SaveExecutiveSummary(hdnQRANumber.Value, UserManager.GetCurrentUser.UserName, txtExecutiveSummary.Text)
    End Sub

    Protected Sub Page_LoadComplete(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.LoadComplete
        If Not Page.IsPostBack Then
            notMain.Clear()
            Dim tmpStr As String = Request.QueryString.Get("RN")
            If Not String.IsNullOrEmpty(tmpStr) Then
                ProcessQRA(tmpStr)
            Else
                Dim litTitle As Literal = Master.FindControl("litPageTitle")
                If litTitle IsNot Nothing Then
                    litTitle.Text = "REMI - Batch Information"
                End If
                accMain.SelectedIndex = -1
            End If

        End If

        txtBarcodeReading.Focus()
        acpDocuments.Visible = UserManager.GetCurrentUser.HasDocumentAuthority()
    End Sub

    Protected Sub SetupMenuItems(ByVal b As BatchView)
        Dim myMenu As WebControls.Menu
        Dim mi As New MenuItem
        myMenu = CType(Master.FindControl("menuHeader"), WebControls.Menu)

        mi = New MenuItem
        mi.Text = "Request Link"
        mi.Target = "_blank"
        mi.NavigateUrl = b.RequestLink()
        myMenu.Items(0).ChildItems.Add(mi)

        mi = New MenuItem
        mi.Text = "Executive Summary"
        mi.Target = "_blank"
        mi.NavigateUrl = b.ExecutiveSummaryLink()
        myMenu.Items(0).ChildItems.Add(mi)

        mi = New MenuItem
        mi.Text = "Product Info"
        mi.Target = "_blank"
        mi.NavigateUrl = b.ProductGroupLink
        myMenu.Items(0).ChildItems.Add(mi)

        mi = New MenuItem
        mi.Text = "Test Records"
        mi.Target = "_blank"
        mi.NavigateUrl = b.TestRecordsLink
        myMenu.Items(0).ChildItems.Add(mi)

        mi = New MenuItem
        mi.Text = "Results"
        mi.Target = "_blank"
        mi.NavigateUrl = b.RelabResultLink
        myMenu.Items(0).ChildItems.Add(mi)

        hypEditExceptions.NavigateUrl = b.ExceptionManagerLink
        hypChangeStatus.NavigateUrl = b.SetStatusManagerLink
        hypChangePriority.NavigateUrl = b.SetPriorityManagerLink
        hypModifyTestDurations.NavigateUrl = b.SetTestDurationsManagerLink
        hypChangeTestStage.NavigateUrl = b.SetTestStageManagerLink
        hypTRSLink.NavigateUrl = b.RequestLink()
        hypRefresh.NavigateUrl = b.BatchInfoLink
        hpyES.NavigateUrl = b.ExecutiveSummaryLink()
        hypRelabLink.NavigateUrl = b.RelabResultLink
        hypProductGroupLink.NavigateUrl = b.ProductGroupLink
        hypTestRecords.NavigateUrl = b.TestRecordsLink

        hypRelabLink.Visible = True
        imgRelabLink.Visible = True

        Dim record As Int32 = (From r In New Remi.Dal.Entities().Instance().Results _
                        Where r.TestUnit.Batch.ID = b.ID _
                        Take 1 _
                        Select r.ID).FirstOrDefault()
        If (record < 1) Then
            hypRelabLink.Enabled = False
        End If

        imgTestRecords.Visible = True
        hypTestRecords.Visible = True
        imgProductGroupLink.Visible = True
        hypProductGroupLink.Visible = True
        hypTRSLink.Visible = True
        imgTRSLink.Visible = True

        If UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID) Or UserManager.GetCurrentUser.IsTestCenterAdmin Or UserManager.GetCurrentUser.HasBatchSetupAuthority(b.DepartmentID) Then
            mi = New MenuItem
            mi.Text = "Exceptions"
            mi.Target = "_blank"
            mi.NavigateUrl = b.ExceptionManagerLink
            myMenu.Items(0).ChildItems.Add(mi)
            liEditExceptions.Visible = True
        End If

        If UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID) Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
            liModifyPriority.Visible = True
            liModifyStage.Visible = True
            liModifyStatus.Visible = True
            liModifyTestDurations.Visible = True

            mi = New MenuItem
            mi.Text = "Modify Status"
            mi.Target = "_blank"
            mi.NavigateUrl = b.SetStatusManagerLink
            myMenu.Items(0).ChildItems.Add(mi)

            mi = New MenuItem
            mi.Text = "Modify Priority"
            mi.Target = "_blank"
            mi.NavigateUrl = b.SetPriorityManagerLink
            myMenu.Items(0).ChildItems.Add(mi)

            mi = New MenuItem
            mi.Text = "Modify Durations"
            mi.Target = "_blank"
            mi.NavigateUrl = b.SetTestDurationsManagerLink
            myMenu.Items(0).ChildItems.Add(mi)

            mi = New MenuItem
            mi.Text = "Modify Stage"
            mi.Target = "_blank"
            mi.NavigateUrl = b.SetTestStageManagerLink
            myMenu.Items(0).ChildItems.Add(mi)
        End If
    End Sub

    Protected Sub ddlTime_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTime.SelectedIndexChanged
        odsTrackingLog.DataBind()
        grdTrackingLog.DataBind()
    End Sub

    Protected Sub btnEdit_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        If (setup.Visible) Then
            gvwTestingSummary.Visible = True
            lnkCheckForUpdates.Visible = True
            setup.Visible = False
            btnEdit.Text = "Edit Setup"

            Dim b As BatchView = BatchManager.GetViewBatch(hdnQRANumber.Value)
            Dim records = (From rm In New Remi.Dal.Entities().Instance().ResultsMeasurements _
                                      Where rm.Result.TestUnit.Batch.ID = b.ID And rm.Archived = False _
                                      Select New With {.RID = rm.Result.ID, .TestID = rm.Result.Test.ID, .TestStageID = rm.Result.TestStage.ID, .UN = rm.Result.TestUnit.BatchUnitNumber}).Distinct.ToArray

            Dim rqResults As New DataTable
            rqResults.Columns.Add("RID", GetType(Int32))
            rqResults.Columns.Add("TestID", GetType(Int32))
            rqResults.Columns.Add("TestStageID", GetType(Int32))
            rqResults.Columns.Add("UN", GetType(Int32))

            For Each rec In records
                Dim row As DataRow = rqResults.NewRow
                row("RID") = rec.RID
                row("TestID") = rec.TestID
                row("TestStageID") = rec.TestStageID
                row("UN") = rec.UN
                rqResults.Rows.Add(row)
            Next

            gvwTestingSummary.DataSource = b.GetParametricTestOverviewTable(UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID), UserManager.GetCurrentUser.IsTestCenterAdmin, rqResults, UserManager.GetCurrentUser.HasBatchSetupAuthority(b.DepartmentID), True)
            gvwTestingSummary.DataBind()

            ScriptManager.RegisterStartupScript(Me, GetType(Page), Guid.NewGuid().ToString(), "gridviewScroll();ApplyTableFormatting();", True)
        Else
            btnEdit.Text = "View Summary"
            gvwTestingSummary.Visible = False
            lnkCheckForUpdates.Visible = False
            setup.Visible = True
            setup.DataBind()
        End If
    End Sub

    Protected Sub btnEditStressing_Click(ByVal sender As Object, ByVal e As System.EventArgs)
        If (setupStressing.Visible) Then
            gvwStressingSummary.Visible = True
            lnkCheckForUpdates2.Visible = True
            setupStressing.Visible = False
            btnEditStressing.Text = "Edit Setup"
            lblNote.Visible = True

            Dim b As BatchView = BatchManager.GetViewBatch(hdnQRANumber.Value)
            gvwStressingSummary.DataSource = b.GetStressingOverviewTable(UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID), UserManager.GetCurrentUser.IsTestCenterAdmin, UserManager.GetCurrentUser.HasBatchSetupAuthority(b.DepartmentID), True, If(b.Orientation IsNot Nothing, b.Orientation.Definition, String.Empty))
            gvwStressingSummary.DataBind()

            If (b.Orientation IsNot Nothing) Then
                lblOrientation.Text = String.Format("Orientation/Sequence: {0}", b.Orientation.Name)
            Else
                lblOrientation.Text = String.Empty
            End If

            ScriptManager.RegisterStartupScript(Me, GetType(Page), Guid.NewGuid().ToString(), "gridviewScroll2();ApplyTableFormatting();", True)
        Else
            Dim b As BatchView = BatchManager.GetViewBatch(hdnQRANumber.Value)
            setupStressing.OrientationID = If(b.Orientation Is Nothing, 0, b.Orientation.ID)
            btnEditStressing.Text = "View Summary"
            gvwStressingSummary.Visible = False
            lnkCheckForUpdates2.Visible = False
            lblNote.Visible = False
            setupStressing.Visible = True
            setupStressing.DataBind()
        End If
    End Sub

    Protected Sub lnkCheckForUpdates_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkCheckForUpdates.Click
        If Not String.IsNullOrEmpty(hdnQRANumber.Value) Then
            REMIAppCache.RemoveReqData(hdnQRANumber.Value)
            TestRecordManager.CheckBatchForResultUpdates(BatchManager.GetItem(hdnQRANumber.Value, False, True, True), True)

            Dim b As BatchView = BatchManager.GetViewBatch(hdnQRANumber.Value)
            Dim records = (From rm In New Remi.Dal.Entities().Instance().ResultsMeasurements _
                                      Where rm.Result.TestUnit.Batch.ID = b.ID And rm.Archived = False _
                                      Select New With {.RID = rm.Result.ID, .TestID = rm.Result.Test.ID, .TestStageID = rm.Result.TestStage.ID, .UN = rm.Result.TestUnit.BatchUnitNumber}).Distinct.ToArray

            Dim rqResults As New DataTable
            rqResults.Columns.Add("RID", GetType(Int32))
            rqResults.Columns.Add("TestID", GetType(Int32))
            rqResults.Columns.Add("TestStageID", GetType(Int32))
            rqResults.Columns.Add("UN", GetType(Int32))

            For Each rec In records
                Dim row As DataRow = rqResults.NewRow
                row("RID") = rec.RID
                row("TestID") = rec.TestID
                row("TestStageID") = rec.TestStageID
                row("UN") = rec.UN
                rqResults.Rows.Add(row)
            Next

            gvwTestingSummary.DataSource = b.GetParametricTestOverviewTable(UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID), UserManager.GetCurrentUser.IsTestCenterAdmin, rqResults, UserManager.GetCurrentUser.HasBatchSetupAuthority(b.DepartmentID), True)
            gvwTestingSummary.DataBind()
            ScriptManager.RegisterClientScriptBlock(Me, GetType(Page), Guid.NewGuid().ToString(), "gridviewScroll();ApplyTableFormatting();", True)
        End If
    End Sub

    Protected Sub lnkCheckForUpdates2_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkCheckForUpdates2.Click
        If Not String.IsNullOrEmpty(hdnQRANumber.Value) Then
            REMIAppCache.RemoveReqData(hdnQRANumber.Value)
            TestRecordManager.CheckBatchForResultUpdates(BatchManager.GetItem(hdnQRANumber.Value, False, True, True), True)

            Dim b As BatchView = BatchManager.GetViewBatch(hdnQRANumber.Value)
            gvwStressingSummary.DataSource = b.GetStressingOverviewTable(UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup, b.DepartmentID), UserManager.GetCurrentUser.IsTestCenterAdmin, UserManager.GetCurrentUser.HasBatchSetupAuthority(b.DepartmentID), True, If(b.Orientation IsNot Nothing, b.Orientation.Definition, String.Empty))
            gvwStressingSummary.DataBind()
            ScriptManager.RegisterClientScriptBlock(Me, GetType(Page), Guid.NewGuid().ToString(), "gridviewScroll2();ApplyTableFormatting();", True)
        End If
    End Sub

    Protected Sub gvwTestExceptions_OnPageIndexChanging(ByVal sender As Object, ByVal e As GridViewPageEventArgs) Handles gvwTestExceptions.PageIndexChanging
        gvwTestExceptions.PageIndex = e.NewPageIndex
        Dim es As New ExceptionSearch()
        es.QRANumber = hdnQRANumber.Value
        es.IncludeBatches = 1
        gvwTestExceptions.DataSource = Remi.Dal.TestExceptionDB.ExceptionSearch(es)

        gvwTestExceptions.DataBind()
    End Sub

    Protected Sub gvwStressingSummary_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwStressingSummary.RowDataBound
        If e.Row.RowType = DataControlRowType.Header Then
            For i = 0 To e.Row.Cells.Count - 1
                If (i > 0) Then
                    Dim hyperlink As New HyperLink()
                    hyperlink.Text = e.Row.Cells(i).Text
                    hyperlink.Target = "_blank"
                    hyperlink.NavigateUrl = Remi.Core.REMIWebLinks.GetTestRecordsLink(hdnQRANumber.Value, hyperlink.Text, Nothing, Nothing, 0)
                    e.Row.Cells(i).Text = String.Empty
                    e.Row.Cells(i).Controls.Add(hyperlink)
                End If
            Next
        End If
    End Sub

    Protected Sub gvwTestingSummary_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwTestingSummary.RowDataBound
        If e.Row.RowType = DataControlRowType.Header Then
            For i = 0 To e.Row.Cells.Count - 1
                If (i > 0) Then
                    Dim hyperlink As New HyperLink()
                    hyperlink.Text = e.Row.Cells(i).Text
                    hyperlink.Target = "_blank"
                    hyperlink.NavigateUrl = Remi.Core.REMIWebLinks.GetTestRecordsLink(hdnQRANumber.Value, hyperlink.Text, Nothing, Nothing, 0)
                    e.Row.Cells(i).Text = String.Empty
                    e.Row.Cells(i).Controls.Add(hyperlink)
                End If
            Next
        End If
    End Sub

    Protected Sub grdJIRAS_OnRowEditing(ByVal sender As Object, ByVal e As GridViewEditEventArgs)
        grdJIRAS.EditIndex = e.NewEditIndex
        JIRABindData()
        Dim lblDisplayName As Label = grdJIRAS.Rows(e.NewEditIndex).FindControl("lblDisplayName")
        Dim hypLink As HyperLink = grdJIRAS.Rows(e.NewEditIndex).FindControl("hypLink")
        Dim lblTitle As Label = grdJIRAS.Rows(e.NewEditIndex).FindControl("lblTitle")
        Dim txtDisplayName As TextBox = grdJIRAS.Rows(e.NewEditIndex).FindControl("txtDisplayName")
        Dim txtLink As TextBox = grdJIRAS.Rows(e.NewEditIndex).FindControl("txtLink")
        Dim txtTitle As TextBox = grdJIRAS.Rows(e.NewEditIndex).FindControl("txtTitle")

        lblDisplayName.Visible = False
        hypLink.Visible = False
        lblTitle.Visible = False
        txtDisplayName.Visible = True
        txtLink.Visible = True
        txtTitle.Visible = True
    End Sub

    Protected Sub grdJIRAS_OnRowCancelingEdit(ByVal sender As Object, ByVal e As GridViewCancelEditEventArgs)
        grdJIRAS.EditIndex = -1
        JIRABindData()
    End Sub

    Protected Sub grdJIRAS_RowUpdating(ByVal sender As Object, ByVal e As GridViewUpdateEventArgs)
        Dim txtDisplayName As TextBox = grdJIRAS.Rows(e.RowIndex).FindControl("txtDisplayName")
        Dim txtLink As TextBox = grdJIRAS.Rows(e.RowIndex).FindControl("txtLink")
        Dim txtTitle As TextBox = grdJIRAS.Rows(e.RowIndex).FindControl("txtTitle")
        Dim jiraID As Int32
        Dim batchID As Int32
        Int32.TryParse(grdJIRAS.DataKeys(e.RowIndex).Values(0), jiraID)
        Int32.TryParse(grdJIRAS.DataKeys(e.RowIndex).Values(1), batchID)

        Dim isSaved As Boolean = BatchManager.AddEditJira(batchID, jiraID, txtDisplayName.Text, txtLink.Text, txtTitle.Text)

        If (isSaved) Then
            notMain.Notifications.Add(New Notification("i2", NotificationType.Information, "The JIRA Was Added/Updated Successfully"))
        Else
            notMain.Notifications.Add(New Notification("e1", NotificationType.Warning, "The JIRA Was Not Added/Updated Successfully"))
        End If

        grdJIRAS.EditIndex = -1
        JIRABindData()
    End Sub
End Class