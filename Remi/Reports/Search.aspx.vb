Imports Remi.BusinessEntities
Imports Remi.Validation
Imports Remi.Bll
Imports System.Data
Imports Remi.Contracts

Partial Class Search
    Inherits System.Web.UI.Page

#Region "Page_Load"
    Protected envds As New DataSet

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If (Not IsPostBack) Then

            Dim testCenterAdmin As Boolean = UserManager.GetCurrentUser.IsTestCenterAdmin

            If (testCenterAdmin Or UserManager.GetCurrentUser.IsAdmin) Then
                rblSearchBy.Items(3).Enabled = True 'Users
            End If

            If (testCenterAdmin Or UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.HasBatchSetupAuthority(0)) Then
                rblSearchBy.Items(2).Enabled = True 'Exceptions
            End If

            If (Not (IsPostBack)) Then
                rblSearchBy_OnSelectedIndexChanged(rblSearchBy, e)

                If (testCenterAdmin) Then
                    ddlTestCentersUser.Enabled = False
                End If
            End If

            If (Helpers.GetPostBackControl(Me.Page) IsNot Nothing) Then
                If (Not (Helpers.GetPostBackControl(Me.Page)).ID = "btnSearch" And ddlTestCenters.SelectedValue <> String.Empty) Then
                    ddlUsers.Items.Clear()
                    Dim us As New UserSearch()
                    us.TestCenterID = ddlTestCenters.SelectedValue
                    ddlUsers.DataSource = REMI.Dal.UserDB.UserSearch(us, False, False, False)
                    ddlUsers.DataBind()
                End If
            End If
        End If
    End Sub
#End Region

#Region "Button Events"
    Protected Sub btnDeleteAllChecked_Click(sender As Object, e As EventArgs)
        Dim exceptionDeleted As Boolean = False
        For Each rowItem As GridViewRow In gvwTestExceptions.Rows
            Dim ExceptionID As Integer = 0
            Dim processDelete As Boolean = True

            If (gvwTestExceptions.PageCount > 1) Then
                If (gvwTestExceptions.DataKeys().Count = rowItem.RowIndex) Then
                    processDelete = False
                End If
            End If

            If (processDelete) Then
                ExceptionID = IIf(CType(rowItem.Cells(0).FindControl("chk1"), CheckBox).Checked, CInt(gvwTestExceptions.DataKeys(rowItem.RowIndex).Value.ToString()), 0)
            End If

            If (ExceptionID > 0) Then
                exceptionDeleted = True
                ExceptionManager.DeleteException(ExceptionID)
            End If
        Next
        If exceptionDeleted Then
            gvwTestExceptions.DataBind()
        End If
    End Sub

    Protected Sub ClearBatchValues()
        ddlProductFilter.SelectedValue = Nothing
        txtRevision.Text = String.Empty
        ddlProductType.SelectedValue = Nothing
        ddlAccessoryGroup.SelectedValue = Nothing
        ddlRequestReason.SelectedValue = Nothing
        ddlJobs.SelectedValue = Nothing
        ddlTestStages.SelectedValue = Nothing
        txtTestStage.Text = String.Empty
        ddlTestStageType.SelectedValue = Nothing

        For i As Integer = 0 To chkTestStageType.Items.Count - 1
            chkTestStageType.Items(i).Selected = False
        Next

        For i As Integer = 0 To chkBatchStatus.Items.Count - 1
            chkBatchStatus.Items(i).Selected = False
        Next

        ddlTests.SelectedValue = Nothing
        ddlBatchStatus.SelectedValue = Nothing
        ddlPriority.SelectedValue = Nothing
        ddlUsers.SelectedValue = Nothing
        ddlTrackingLocationType.SelectedValue = Nothing
        ddlLocationFunction.SelectedValue = Nothing
        ddlNotInLocationFunction.SelectedValue = Nothing
    End Sub

    Protected Sub btn_OnClick(ByVal sender As Object, ByVal e As System.EventArgs)
        lblTopInfo.Visible = False

        Select Case sender.ID
            Case "btnTestingComplete"
                Dim bs As New BatchSearch()
                bs.Status = BatchStatus.TestingComplete
                bs.ExcludedTestStageType = BatchSearchTestStageType.NonTestingTask + BatchSearchTestStageType.FailureAnalysis
                bs.GeoLocationID = ddlTestCenters.SelectedValue

                ClearBatchValues()

                ddlTestCenters.SelectedValue = bs.GeoLocationID.ToString()
                ddlBatchStatus.SelectedValue = bs.Status.ToString()
                chkTestStageType.Items.FindByValue(TestStageType.FailureAnalysis.ToString()).Selected = True
                chkTestStageType.Items.FindByValue(TestStageType.NonTestingTask.ToString()).Selected = True

                pnlSearchUser.Visible = False
                pnlSearchExceptions.Visible = False
                pnlSearchUnits.Visible = False
                pnlTraining.Visible = False
                pnlSearchBatch.Visible = True
                rblSearchBy.SelectedValue = 1
                bscMain.DisplayMode = Controls_BatchSelectControl.BatchSelectControlMode.TestingCompleteDisplay
                bscMain.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))
            Case "btnHeld"
                Dim bs As New BatchSearch()
                bs.Status = BatchStatus.Held
                bs.GeoLocationID = ddlTestCenters.SelectedValue

                ClearBatchValues()

                ddlTestCenters.SelectedValue = bs.GeoLocationID.ToString()
                ddlBatchStatus.SelectedValue = bs.Status.ToString()

                pnlSearchUser.Visible = False
                pnlSearchExceptions.Visible = False
                pnlSearchUnits.Visible = False
                pnlTraining.Visible = False
                pnlSearchBatch.Visible = True
                rblSearchBy.SelectedValue = 1
                bscMain.DisplayMode = Controls_BatchSelectControl.BatchSelectControlMode.HeldInfoDisplay
                bscMain.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))
            Case "btnIncoming"
                Dim bs As New BatchSearch()
                bs.GeoLocationID = ddlTestCenters.SelectedValue
                bs.Status = BatchStatus.InProgress
                bs.TestStageType = TestStageType.IncomingEvaluation

                ClearBatchValues()

                ddlTestCenters.SelectedValue = bs.GeoLocationID.ToString()
                ddlTestStageType.SelectedValue = bs.TestStageType.ToString()
                ddlBatchStatus.SelectedValue = bs.Status.ToString()

                pnlSearchUser.Visible = False
                pnlSearchExceptions.Visible = False
                pnlSearchUnits.Visible = False
                pnlTraining.Visible = False
                pnlSearchBatch.Visible = True
                rblSearchBy.SelectedValue = 1
                bscMain.DisplayMode = Controls_BatchSelectControl.BatchSelectControlMode.HeldInfoDisplay
                bscMain.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))
            Case "btnReporting"
                Dim bs As New BatchSearch()
                bs.GeoLocationID = ddlTestCenters.SelectedValue
                bs.ExcludedStatus = BatchSearchBatchStatus.Complete + BatchSearchBatchStatus.Held + BatchSearchBatchStatus.NotSavedToREMI + BatchSearchBatchStatus.Quarantined + BatchSearchBatchStatus.Received + BatchSearchBatchStatus.Rejected
                bs.TestStageType = TestStageType.NonTestingTask

                ClearBatchValues()

                ddlTestCenters.SelectedValue = bs.GeoLocationID.ToString()
                ddlTestStageType.SelectedValue = bs.TestStageType.ToString()
                chkBatchStatus.Items.FindByValue(BatchStatus.Complete.ToString()).Selected = True
                chkBatchStatus.Items.FindByValue(BatchStatus.Held.ToString()).Selected = True
                chkBatchStatus.Items.FindByValue(BatchStatus.Quarantined.ToString()).Selected = True
                chkBatchStatus.Items.FindByValue(BatchStatus.Received.ToString()).Selected = True
                chkBatchStatus.Items.FindByValue(BatchStatus.Rejected.ToString()).Selected = True

                pnlSearchUser.Visible = False
                pnlSearchExceptions.Visible = False
                pnlSearchUnits.Visible = False
                pnlTraining.Visible = False
                pnlSearchBatch.Visible = True
                rblSearchBy.SelectedValue = 1
                bscMain.DisplayMode = Controls_BatchSelectControl.BatchSelectControlMode.HeldInfoDisplay
                bscMain.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))
            Case "btnSearching"
                If (pnlSearchUser.Visible) Then
                    Dim us As New UserSearch()
                    Dim testCenterID As Int32
                    Dim productID As Int32
                    Dim trainingID As Int32
                    Dim trainingLevelID As Int32
                    Dim byPass As Int32
                    Dim departmentID As Int32

                    Int32.TryParse(ddlProductFilterUser.SelectedValue, productID)
                    Int32.TryParse(ddlTestCentersUser.SelectedValue, testCenterID)
                    Int32.TryParse(ddlTraining.SelectedValue, trainingID)
                    Int32.TryParse(ddlTrainingLevel.SelectedValue, trainingLevelID)
                    Int32.TryParse(ddlDepartmentUser.SelectedValue, departmentID)

                    If (chkByPass.Checked) Then
                        byPass = 1
                    Else
                        byPass = 0
                        us.ProductID = productID
                    End If

                    us.TrainingID = trainingID
                    us.TrainingLevelID = trainingLevelID
                    us.TestCenterID = testCenterID
                    us.ByPass = byPass
                    us.DepartmentID = departmentID

                    gvwUsers.DataSource = REMI.Dal.UserDB.UserSearch(us, False, False, False)
                    gvwUsers.DataBind()

                    Helpers.MakeAccessable(gvwUsers)
                ElseIf (pnlSearchExceptions.Visible) Then
                    Dim es As New ExceptionSearch()
                    Dim accessory As Int32
                    Dim productID As Int32
                    Dim productTypeID As Int32
                    Dim testID As Int32
                    Dim testStageID As Int32
                    Dim jobName As String
                    Dim IncludeBatches As Int32 = 0
                    Dim IsMQual As Int32 = 0
                    Dim testCenterID As Int32

                    If (Page.IsValid) Then
                        jobName = ddlJobs2.SelectedValue
                        Int32.TryParse(ddlAccesssoryGroup2.SelectedValue, accessory)
                        Int32.TryParse(ddlProductFilter2.SelectedValue, productID)
                        Int32.TryParse(ddlProductType2.SelectedValue, productTypeID)
                        Int32.TryParse(ddlTests2.SelectedValue, testID)
                        Int32.TryParse(ddlTestStages2.SelectedValue, testStageID)
                        Int32.TryParse(ddlTestCentersException.SelectedValue, testCenterID)

                        If (chkIncludeBatch.Checked) Then
                            IncludeBatches = 1
                        End If

                        If (chkIsMQual.Checked) Then
                            IsMQual = 1
                        End If

                        If (ddlRequestReasonException.SelectedValue.ToLower() <> "all") Then
                            es.RequestReason = ddlRequestReasonException.SelectedValue
                        End If

                        es.AccessoryGroupID = accessory
                        es.ProductID = productID
                        es.ProductTypeID = productTypeID
                        es.TestID = testID
                        es.TestStageID = testStageID
                        es.IncludeBatches = IncludeBatches

                        If (txtQRANumber.Text.Length > 0) Then
                            es.IncludeBatches = 1
                            es.QRANumber = txtQRANumber.Text
                        End If

                        es.TestCenterID = testCenterID
                        es.IsMQual = IsMQual

                        If (jobName <> "All") Then
                            es.JobName = jobName
                        End If

                        gvwTestExceptions.DataSource = REMI.Dal.TestExceptionDB.ExceptionSearch(es)
                        gvwTestExceptions.DataBind()

                        Helpers.MakeAccessable(gvwTestExceptions)
                    Else
                        gvwTestExceptions.DataSource = Nothing
                        gvwTestExceptions.DataBind()
                    End If
                ElseIf (pnlSearchBatch.Visible) Then
                    Dim bs As New BatchSearch()
                    Dim accessory As Int32
                    Dim productID As Int32
                    Dim productTypeID As Int32
                    Dim testID As Int32
                    Dim testStageID As Int32
                    Dim userID As Int32
                    Dim departmentID As Int32
                    Dim trackingLocationID As Int32
                    Dim geoLocationID As Int32 = ddlTestCenters.SelectedValue
                    Dim _start As DateTime
                    Dim _end As DateTime
                    Dim testStage As String = txtTestStage.Text.Trim()
                    Dim revision As String = txtRevision.Text.Trim()

                    If (geoLocationID = 0) Then
                        geoLocationID = Nothing
                    End If

                    Int32.TryParse(ddlDepartment.SelectedValue, departmentID)

                    bs.GeoLocationID = geoLocationID
                    bs.JobName = ddlJobs.SelectedValue
                    bs.DepartmentID = departmentID

                    If (Not (String.IsNullOrEmpty(testStage))) Then
                        bs.TestStage = testStage
                    End If

                    If (Not (String.IsNullOrEmpty(revision))) Then
                        bs.Revision = revision
                    End If

                    bs.TestStageType = DirectCast(System.Enum.Parse(GetType(TestStageType), If(ddlTestStageType.SelectedValue.ToLower() = "all", 0, ddlTestStageType.SelectedValue)), TestStageType)

                    Dim exTestStageType As List(Of Int32)
                    If (chkTestStageType.Items(0).Selected) Then
                        exTestStageType = (From item In chkTestStageType.Items.Cast(Of ListItem)() Where item.Text <> "ALL" Select DirectCast(System.Enum.Parse(GetType(BatchSearchTestStageType), item.Value), Int32)).ToList()
                    Else
                        exTestStageType = (From item In chkTestStageType.Items.Cast(Of ListItem)() Where item.Selected = True Select DirectCast(System.Enum.Parse(GetType(BatchSearchTestStageType), item.Value), Int32)).ToList()
                    End If

                    bs.ExcludedTestStageType = (From t In exTestStageType Select t).Sum()

                    Dim exBatchStatus As List(Of Int32)
                    If (chkBatchStatus.Items(0).Selected) Then
                        exBatchStatus = (From item In chkBatchStatus.Items.Cast(Of ListItem)() Where item.Text <> "ALL" Select DirectCast(System.Enum.Parse(GetType(BatchSearchBatchStatus), item.Value), Int32)).ToList()
                    Else
                        exBatchStatus = (From item In chkBatchStatus.Items.Cast(Of ListItem)() Where item.Selected = True Select DirectCast(System.Enum.Parse(GetType(BatchSearchBatchStatus), item.Value), Int32)).ToList()
                    End If

                    bs.ExcludedStatus = (From t In exBatchStatus Select t).Sum()

                    Int32.TryParse(ddlAccessoryGroup.SelectedValue, accessory)
                    Int32.TryParse(ddlProductFilter.SelectedValue, productID)
                    Int32.TryParse(ddlProductType.SelectedValue, productTypeID)
                    Int32.TryParse(ddlTests.SelectedValue, testID)
                    Int32.TryParse(ddlTestStages.SelectedValue, testStageID)
                    Int32.TryParse(ddlUsers.SelectedValue, userID)
                    Int32.TryParse(ddlTrackingLocationType.SelectedValue, trackingLocationID)
                    DateTime.TryParse(txtStart.Text, _start)
                    DateTime.TryParse(txtEnd.Text, _end)

                    If (ddlRequestReason.SelectedValue.ToLower() <> "all") Then
                        bs.RequestReason = ddlRequestReason.SelectedValue
                    End If

                    If (ddlPriority.SelectedValue.ToLower() <> "all") Then
                        bs.Priority = ddlPriority.SelectedValue
                    End If

                    If (ddlLocationFunction.SelectedValue.ToLower() <> "all") Then
                        bs.TrackingLocationFunction = DirectCast(System.Enum.Parse(GetType(TrackingLocationFunction), ddlLocationFunction.SelectedValue), TrackingLocationFunction)
                    End If

                    If (ddlNotInLocationFunction.SelectedValue.ToLower() <> "all") Then
                        bs.NotInTrackingLocationFunction = DirectCast(System.Enum.Parse(GetType(TrackingLocationFunction), ddlNotInLocationFunction.SelectedValue), TrackingLocationFunction)
                        bs.TrackingLocationFunction = Nothing
                        ddlLocationFunction.SelectedValue = "ALL"
                    End If

                    If (ddlBatchStatus.SelectedValue.ToLower() <> "all") Then
                        bs.Status = DirectCast(System.Enum.Parse(GetType(BatchStatus), ddlBatchStatus.SelectedValue), BatchStatus)
                    End If

                    bs.AccessoryGroupID = accessory
                    bs.ProductID = productID
                    bs.ProductTypeID = productTypeID
                    bs.TestID = testID
                    bs.TestStageID = testStageID
                    bs.TrackingLocationID = trackingLocationID
                    bs.UserID = userID

                    bs.BatchEnd = _end
                    bs.BatchStart = _start

                    bscMain.DisplayMode = Controls_BatchSelectControl.BatchSelectControlMode.SearchInfoDisplay
                    bscMain.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID, False, False, False))
                    lblTopInfo.Visible = True
                ElseIf (pnlSearchUnits.Visible) Then
                    Dim us As New TestUnitCriteria()
                    Dim bsn As Int32
                    Int32.TryParse(txtBSN.Text, bsn)

                    us.BSN = bsn

                    If (bsn > 0) Then
                        gvwUnits.DataSource = REMI.Dal.TestUnitDB.UnitSearch(us)
                        gvwUnits.DataBind()
                    End If

                    Helpers.MakeAccessable(gvwUnits)
                ElseIf (pnlTraining.Visible) Then
                    Dim us As New UserSearch()
                    Dim testCenterID As Int32
                    Dim trainingID As Int32
                    Dim userID As Int32
                    Int32.TryParse(ddlTestCenterTraining.SelectedValue, testCenterID)
                    Int32.TryParse(ddlSearchTraining.SelectedValue, trainingID)
                    Int32.TryParse(ddlUserTraining.SelectedValue, userID)

                    us.TestCenterID = testCenterID
                    us.TrainingID = trainingID
                    us.UserID = userID

                    gvwTraining.DataSource = REMI.Dal.UserDB.UserSearch(us, True, False, False)
                    gvwTraining.DataBind()

                    Helpers.MakeAccessable(gvwTraining)
                End If
        End Select

        gvwTraining.Visible = pnlTraining.Visible
        gvwUsers.Visible = pnlSearchUser.Visible
        gvwUnits.Visible = pnlSearchUnits.Visible
        gvwTestExceptions.Visible = pnlSearchExceptions.Visible
        bscMain.Visible = pnlSearchBatch.Visible
    End Sub
#End Region

#Region "Events"
    Protected Sub lnkExportAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkExportAction.Click
        If (pnlSearchUser.Visible) Then
            Dim us As New UserSearch()
            Dim testCenterID As Int32
            Dim productID As Int32
            Dim trainingID As Int32
            Dim trainingLevelID As Int32
            Dim departmentID As Int32
            Dim byPass As Int32

            Int32.TryParse(ddlProductFilterUser.SelectedValue, productID)
            Int32.TryParse(ddlTestCentersUser.SelectedValue, testCenterID)
            Int32.TryParse(ddlTraining.SelectedValue, trainingID)
            Int32.TryParse(ddlTrainingLevel.SelectedValue, trainingLevelID)
            Int32.TryParse(ddlDepartmentUser.SelectedValue, departmentID)

            If (chkByPass.Checked) Then
                byPass = 1
            Else
                byPass = 0
                us.ProductID = productID
            End If

            us.TrainingID = trainingID
            us.TrainingLevelID = trainingLevelID
            us.TestCenterID = testCenterID
            us.ByPass = byPass
            us.DepartmentID = departmentID

            Helpers.ExportToExcel(Helpers.GetDateTimeFileName("SearchUser", "xls"), REMI.Dal.UserDB.UserSearch(us, False, False, False))
        ElseIf (pnlSearchExceptions.Visible) Then
            Dim es As New ExceptionSearch()
            Dim accessory As Int32
            Dim productID As Int32
            Dim productTypeID As Int32
            Dim testID As Int32
            Dim testStageID As Int32
            Dim jobName As String
            Dim IncludeBatches As Int32 = 0
            Dim IsMQual As Int32 = 0
            Dim testCenterID As Int32

            jobName = ddlJobs2.SelectedValue
            Int32.TryParse(ddlAccesssoryGroup2.SelectedValue, accessory)
            Int32.TryParse(ddlProductFilter2.SelectedValue, productID)
            Int32.TryParse(ddlProductType2.SelectedValue, productTypeID)
            Int32.TryParse(ddlTests2.SelectedValue, testID)
            Int32.TryParse(ddlTestStages2.SelectedValue, testStageID)
            Int32.TryParse(ddlTestCentersException.SelectedValue, testCenterID)

            If (chkIncludeBatch.Checked) Then
                IncludeBatches = 1
            End If

            If (chkIsMQual.Checked) Then
                IsMQual = 1
            End If

            If (ddlRequestReasonException.SelectedValue.ToLower() <> "all") Then
                es.RequestReason = ddlRequestReasonException.SelectedValue
            End If

            es.AccessoryGroupID = accessory
            es.ProductID = productID
            es.ProductTypeID = productTypeID
            es.TestID = testID
            es.TestStageID = testStageID
            es.IncludeBatches = IncludeBatches

            If (txtQRANumber.Text.Length > 0) Then
                es.IncludeBatches = 1
                es.QRANumber = txtQRANumber.Text
            End If

            es.TestCenterID = testCenterID
            es.IsMQual = IsMQual

            If (jobName <> "All") Then
                es.JobName = jobName
            End If

            gvwTestExceptions.DataSource = REMI.Dal.TestExceptionDB.ExceptionSearch(es)
            gvwTestExceptions.DataBind()

            Helpers.ExportToExcel(Helpers.GetDateTimeFileName("SearchExceptions", "xls"), gvwTestExceptions)
        ElseIf (pnlSearchBatch.Visible) Then
            Dim bs As New BatchSearch()
            Dim accessory As Int32
            Dim productID As Int32
            Dim productTypeID As Int32
            Dim testID As Int32
            Dim testStageID As Int32
            Dim userID As Int32
            Dim trackingLocationID As Int32
            Dim geoLocationID As Int32 = ddlTestCenters.SelectedValue
            Dim _start As DateTime
            Dim _end As DateTime
            Dim departmentID As Int32
            Dim testStage As String = txtTestStage.Text.Trim()
            Dim revision As String = txtRevision.Text.Trim()

            If (geoLocationID = 0) Then
                geoLocationID = Nothing
            End If

            bs.GeoLocationID = geoLocationID
            bs.JobName = ddlJobs.SelectedValue

            If (Not (String.IsNullOrEmpty(testStage))) Then
                bs.TestStage = testStage
            End If

            If (Not (String.IsNullOrEmpty(revision))) Then
                bs.Revision = revision
            End If

            bs.TestStageType = DirectCast(System.Enum.Parse(GetType(TestStageType), If(ddlTestStageType.SelectedValue.ToLower() = "all", 0, ddlTestStageType.SelectedValue)), TestStageType)

            Dim exTestStageType As List(Of Int32)
            If (chkTestStageType.Items(0).Selected) Then
                exTestStageType = (From item In chkTestStageType.Items.Cast(Of ListItem)() Where item.Text <> "ALL" Select DirectCast(System.Enum.Parse(GetType(BatchSearchTestStageType), item.Value), Int32)).ToList()
            Else
                exTestStageType = (From item In chkTestStageType.Items.Cast(Of ListItem)() Where item.Selected = True Select DirectCast(System.Enum.Parse(GetType(BatchSearchTestStageType), item.Value), Int32)).ToList()
            End If

            bs.ExcludedTestStageType = (From t In exTestStageType Select t).Sum()

            Dim exBatchStatus As List(Of Int32)
            If (chkBatchStatus.Items(0).Selected) Then
                exBatchStatus = (From item In chkBatchStatus.Items.Cast(Of ListItem)() Where item.Text <> "ALL" Select DirectCast(System.Enum.Parse(GetType(BatchSearchBatchStatus), item.Value), Int32)).ToList()
            Else
                exBatchStatus = (From item In chkBatchStatus.Items.Cast(Of ListItem)() Where item.Selected = True Select DirectCast(System.Enum.Parse(GetType(BatchSearchBatchStatus), item.Value), Int32)).ToList()
            End If

            bs.ExcludedStatus = (From t In exBatchStatus Select t).Sum()

            Int32.TryParse(ddlDepartment.SelectedValue, departmentID)
            Int32.TryParse(ddlAccessoryGroup.SelectedValue, accessory)
            Int32.TryParse(ddlProductFilter.SelectedValue, productID)
            Int32.TryParse(ddlProductType.SelectedValue, productTypeID)
            Int32.TryParse(ddlTests.SelectedValue, testID)
            Int32.TryParse(ddlTestStages.SelectedValue, testStageID)
            Int32.TryParse(ddlUsers.SelectedValue, userID)
            Int32.TryParse(ddlTrackingLocationType.SelectedValue, trackingLocationID)
            DateTime.TryParse(txtStart.Text, _start)
            DateTime.TryParse(txtEnd.Text, _end)

            If (ddlRequestReason.SelectedValue.ToLower() <> "all") Then
                bs.RequestReason = ddlRequestReason.SelectedValue
            End If

            If (ddlPriority.SelectedValue.ToLower() <> "all") Then
                bs.Priority = ddlPriority.SelectedValue
            End If

            If (ddlLocationFunction.SelectedValue.ToLower() <> "all") Then
                bs.TrackingLocationFunction = DirectCast(System.Enum.Parse(GetType(TrackingLocationFunction), ddlLocationFunction.SelectedValue), TrackingLocationFunction)
            End If

            If (ddlNotInLocationFunction.SelectedValue.ToLower() <> "all") Then
                bs.NotInTrackingLocationFunction = DirectCast(System.Enum.Parse(GetType(TrackingLocationFunction), ddlNotInLocationFunction.SelectedValue), TrackingLocationFunction)
                bs.TrackingLocationFunction = Nothing
                ddlLocationFunction.SelectedValue = "ALL"
            End If

            If (ddlBatchStatus.SelectedValue.ToLower() <> "all") Then
                bs.Status = DirectCast(System.Enum.Parse(GetType(BatchStatus), ddlBatchStatus.SelectedValue), BatchStatus)
            End If

            bs.AccessoryGroupID = accessory
            bs.ProductID = productID
            bs.ProductTypeID = productTypeID
            bs.TestID = testID
            bs.TestStageID = testStageID
            bs.TrackingLocationID = trackingLocationID
            bs.UserID = userID
            bs.DepartmentID = departmentID
            bs.BatchEnd = _end
            bs.BatchStart = _start

            bscMain.DisplayMode = Controls_BatchSelectControl.BatchSelectControlMode.SearchInfoDisplay
            bscMain.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))

            Helpers.ExportToExcel(Helpers.GetDateTimeFileName("UnitSearch", "xls"), bscMain.GetGridView)
        ElseIf (pnlSearchUnits.Visible) Then
            Dim us As New TestUnitCriteria()
            Dim bsn As Int32
            Int32.TryParse(txtBSN.Text, bsn)

            us.BSN = bsn

            If (bsn > 0) Then
                Helpers.ExportToExcel(Helpers.GetDateTimeFileName("UnitSearch", "xls"), REMI.Dal.TestUnitDB.UnitSearch(us))
            End If
        ElseIf (pnlTraining.Visible) Then
            Dim us As New UserSearch()
            Dim testCenterID As Int32
            Dim trainingID As Int32
            Dim userID As Int32
            Int32.TryParse(ddlTestCenterTraining.SelectedValue, testCenterID)
            Int32.TryParse(ddlSearchTraining.SelectedValue, trainingID)
            Int32.TryParse(ddlUserTraining.SelectedValue, userID)

            us.TestCenterID = testCenterID
            us.TrainingID = trainingID
            us.UserID = userID

            Helpers.ExportToExcel(Helpers.GetDateTimeFileName("SearchTraining", "xls"), REMI.Dal.UserDB.UserSearch(us, True, False, False))
        End If
    End Sub

    Protected Sub ddlTestCenterTraining_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTestCenterTraining.SelectedIndexChanged
        ddlUserTraining.Items.Clear()
        Dim us As New UserSearch()
        us.TestCenterID = ddlTestCenterTraining.SelectedValue

        Dim uc As UserCollection = UserManager.UserSearchList(us, False, False, False, False, False, False)
        uc.Insert(0, New User())

        ddlUserTraining.DataSource = uc
        ddlUserTraining.DataBind()
    End Sub

    Sub QRAValidation(ByVal source As Object, ByVal arguments As ServerValidateEventArgs)
        If (txtQRANumber.Text.Trim().Length > 0) Then
            Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(txtQRANumber.Text))

            If (Not bc.Validate() Or (bc.Validate() And bc.DetailAvailable <> QRANumberType.BatchOnly)) Then
                arguments.IsValid = False
                DirectCast(source, CustomValidator).ErrorMessage = "You Must Enter A Request Number!"
            Else
                arguments.IsValid = True
            End If
        Else
            DirectCast(source, CustomValidator).ErrorMessage = ""
            arguments.IsValid = True
        End If
    End Sub

    Protected Sub ddlJobs_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlJobs.SelectedIndexChanged
        ddlTestStages.Items.Clear()
        ddlTestStages.Items.Add(New ListItem("All", 0))
        ddlTestStages.DataSource = TestStageManager.GetList(0, ddlJobs.SelectedValue, False)
        ddlTestStages.DataBind()
    End Sub

    Protected Sub ddlJobs2_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlJobs2.SelectedIndexChanged
        ddlTestStages2.Items.Clear()
        ddlTestStages2.Items.Add(New ListItem("All", 0))
        ddlTestStages2.DataSource = TestStageManager.GetList(0, ddlJobs2.SelectedValue, False)
        ddlTestStages2.DataBind()

        gvwTestExceptions.DataSource = Nothing
        gvwTestExceptions.DataBind()
    End Sub

    Protected Sub ddlTestStages2_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTestStages2.SelectedIndexChanged
        gvwTestExceptions.DataSource = Nothing
        gvwTestExceptions.DataBind()
    End Sub

    Protected Sub ddlTestCentersException_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTestCentersException.SelectedIndexChanged
        gvwTestExceptions.DataSource = Nothing
        gvwTestExceptions.DataBind()
    End Sub

    Protected Sub ddlTests2_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTests2.SelectedIndexChanged
        gvwTestExceptions.DataSource = Nothing
        gvwTestExceptions.DataBind()
    End Sub

    Protected Sub chkShowArchived_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles chkShowArchived.CheckedChanged
        Dim prodList As DataTable = ProductGroupManager.GetProductList(UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID, chkShowArchived.Checked)
        Dim newRow As DataRow = prodList.NewRow
        newRow("ID") = 0
        newRow("ProductGroupName") = "All Products"
        prodList.Rows.InsertAt(newRow, 0)

        ddlProductFilter.Items.Clear()
        ddlProductFilter.DataSource = prodList
        ddlProductFilter.DataBind()
    End Sub

    Protected Sub rblSearchBy_OnSelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs)
        lblTopInfo.Visible = False
        Dim val As String = DirectCast(sender, System.Web.UI.WebControls.RadioButtonList).SelectedIndex

        Dim dtProductType As DataTable = LookupsManager.GetLookups("ProductType", 0, 0, String.Empty, String.Empty, 0, False, 0)
        Dim drProductType() As DataRow = dtProductType.Select("LookupType = ''")
        drProductType.ElementAt(0).Item("LookupType") = "ALL"

        Dim dtAccessoryType As DataTable = LookupsManager.GetLookups("AccessoryType", 0, 0, String.Empty, String.Empty, 0, False, 0)
        Dim drAccessoryType() As DataRow = dtAccessoryType.Select("LookupType = ''")
        drAccessoryType.ElementAt(0).Item("LookupType") = "ALL"

        Dim prodList As DataTable = ProductGroupManager.GetProductList(UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID, False)
        Dim newRow As DataRow = prodList.NewRow
        newRow("ID") = 0
        newRow("ProductGroupName") = "All Products"
        prodList.Rows.InsertAt(newRow, 0)

        Select Case val
            Case "0"
                'Batch
                pnlSearchBatch.Visible = True
                pnlSearchExceptions.Visible = False
                pnlSearchUser.Visible = False
                pnlSearchUnits.Visible = False
                pnlTraining.Visible = False

                ddlProductType.Items.Clear()
                ddlProductType.DataSource = dtProductType
                ddlProductType.DataBind()

                ddlAccessoryGroup.Items.Clear()
                ddlAccessoryGroup.DataSource = dtAccessoryType
                ddlAccessoryGroup.DataBind()

                ddlPriority.Items.Clear()
                ddlPriority.DataSource = LookupsManager.GetLookups("Priority", Nothing, Nothing, String.Empty, String.Empty, 0, False, 0)
                ddlPriority.DataBind()

                ddlDepartment.Items.Clear()
                ddlDepartment.DataSource = LookupsManager.GetLookups("Department", Nothing, Nothing, String.Empty, String.Empty, 0, False, 0)
                ddlDepartment.DataBind()

                Dim ld As ListItem = New ListItem(UserManager.GetCurrentUser.Department, UserManager.GetCurrentUser.DepartmentID)
                If (ddlDepartment.Items.Contains(ld)) Then
                    ddlDepartment.SelectedValue = UserManager.GetCurrentUser.DepartmentID
                End If

                ddlBatchStatus.Items.Clear()
                ddlBatchStatus.Items.Add("ALL")
                ddlBatchStatus.DataSource = Helpers.GetBatchStatus()
                ddlBatchStatus.DataBind()

                chkBatchStatus.Items.Clear()
                chkBatchStatus.Items.Add("ALL")
                chkBatchStatus.DataSource = Helpers.GetBatchStatus()
                chkBatchStatus.DataBind()

                ddlProductFilter.Items.Clear()
                ddlProductFilter.DataSource = prodList
                ddlProductFilter.DataBind()

                ddlTestStageType.Items.Clear()
                ddlTestStageType.Items.Add("ALL")
                ddlTestStageType.DataSource = Helpers.GetTestStageTypes
                ddlTestStageType.DataBind()

                chkTestStageType.Items.Clear()
                chkTestStageType.Items.Add("ALL")
                chkTestStageType.DataSource = Helpers.GetTestStageTypes
                chkTestStageType.DataBind()

                Dim locType As TrackingLocationTypeCollection = TrackingLocationManager.GetTrackingLocationTypes()
                locType.Insert(0, New TrackingLocationType())
                ddlTrackingLocationType.DataSource = locType
                ddlTrackingLocationType.DataBind()

                ddlLocationFunction.Items.Clear()
                ddlLocationFunction.Items.Add("ALL")
                ddlLocationFunction.DataSource = Helpers.GetTrackingLocationFunctions()
                ddlLocationFunction.DataBind()

                ddlNotInLocationFunction.Items.Clear()
                ddlNotInLocationFunction.Items.Add("ALL")
                ddlNotInLocationFunction.DataSource = Helpers.GetTrackingLocationFunctions()
                ddlNotInLocationFunction.DataBind()

                ddlRequestReason.Items.Clear()
                ddlRequestReason.Items.Add("ALL")
                ddlRequestReason.DataSource = LookupsManager.GetLookups("RequestPurpose", 0, 0, String.Empty, String.Empty, 0, False, 0)
                ddlRequestReason.DataBind()

                txtStart.Text = DateTime.Now.Subtract(TimeSpan.FromDays(7)).ToShortDateString()
                txtEnd.Text = DateTime.Now.ToShortDateString()

                ddlTestCenters.Items.Clear()
                ddlTestCenters.DataSource = Remi.Bll.LookupsManager.GetLookups("TestCenter", 0, 0, String.Empty, String.Empty, 0, False, 0)
                ddlTestCenters.DataBind()

                Dim l As ListItem = New ListItem(UserManager.GetCurrentUser.TestCentre, UserManager.GetCurrentUser.TestCentreID)
                If (ddlTestCenters.Items.Contains(l)) Then
                    ddlTestCenters.SelectedValue = UserManager.GetCurrentUser.TestCentreID
                End If
            Case "2"
                'Exceptions
                pnlTraining.Visible = False
                pnlSearchBatch.Visible = False
                pnlSearchExceptions.Visible = True
                pnlSearchUser.Visible = False
                pnlSearchUnits.Visible = False

                ddlJobs2.Items.Clear()
                ddlJobs2.Items.Add("ALL")
                ddlJobs2.DataSource = JobManager.GetJobList
                ddlJobs2.DataBind()

                ddlProductType2.Items.Clear()
                ddlProductType2.DataSource = dtProductType
                ddlProductType2.DataBind()

                ddlAccesssoryGroup2.Items.Clear()
                ddlAccesssoryGroup2.DataSource = dtAccessoryType
                ddlAccesssoryGroup2.DataBind()

                ddlProductFilter2.Items.Clear()
                ddlProductFilter2.DataSource = prodList
                ddlProductFilter2.DataBind()

                ddlRequestReasonException.Items.Clear()
                ddlRequestReasonException.Items.Add("ALL")
                ddlRequestReasonException.DataSource = LookupsManager.GetLookups("RequestPurpose", 0, 0, String.Empty, String.Empty, 0, False, 0)
                ddlRequestReasonException.DataBind()
            Case "3"
                'User
                pnlTraining.Visible = False
                pnlSearchBatch.Visible = False
                pnlSearchExceptions.Visible = False
                pnlSearchUser.Visible = True
                pnlSearchUnits.Visible = False

                ddlProductFilterUser.Items.Clear()
                ddlProductFilterUser.DataSource = prodList
                ddlProductFilterUser.DataBind()

                ddlTestCentersUser.Items.Clear()
                ddlTestCentersUser.DataSource = Remi.Bll.LookupsManager.GetLookups("TestCenter", 0, 0, String.Empty, String.Empty, 0, False, 0)
                ddlTestCentersUser.DataBind()

                ddlDepartmentUser.Items.Clear()
                ddlDepartmentUser.DataSource = Remi.Bll.LookupsManager.GetLookups("Department", 0, 0, String.Empty, String.Empty, 0, False, 0)
                ddlDepartmentUser.DataBind()

                Dim l As ListItem = New ListItem(UserManager.GetCurrentUser.TestCentre, UserManager.GetCurrentUser.TestCentreID)
                If (ddlTestCentersUser.Items.Contains(l)) Then
                    ddlTestCentersUser.SelectedValue = UserManager.GetCurrentUser.TestCentreID
                End If

                Dim ld As ListItem = New ListItem(UserManager.GetCurrentUser.Department, UserManager.GetCurrentUser.DepartmentID)
                If (ddlDepartmentUser.Items.Contains(ld)) Then
                    ddlDepartmentUser.SelectedValue = UserManager.GetCurrentUser.DepartmentID
                End If
            Case "1" 'Search Units
                pnlTraining.Visible = False
                pnlSearchUnits.Visible = True
                pnlSearchBatch.Visible = False
                pnlSearchExceptions.Visible = False
                pnlSearchUser.Visible = False
            Case "4"
                'Training
                pnlSearchBatch.Visible = False
                pnlSearchExceptions.Visible = False
                pnlSearchUser.Visible = False
                pnlSearchUnits.Visible = False
                pnlTraining.Visible = True

                ddlTestCenterTraining.Items.Clear()
                ddlTestCenterTraining.DataSource = Remi.Bll.LookupsManager.GetLookups("TestCenter", 0, 0, String.Empty, String.Empty, 0, False, 0)
                ddlTestCenterTraining.DataBind()

                Dim l As ListItem = New ListItem(UserManager.GetCurrentUser.TestCentre, UserManager.GetCurrentUser.TestCentreID)
                If (ddlTestCenterTraining.Items.Contains(l)) Then
                    ddlTestCenterTraining.SelectedValue = UserManager.GetCurrentUser.TestCentreID
                    ddlTestCenterTraining_SelectedIndexChanged(sender, e)
                End If

                ddlSearchTraining.Items.Clear()
                ddlSearchTraining.DataSource = Remi.Bll.LookupsManager.GetLookups("Training", 0, 0, String.Empty, String.Empty, 0, False, 0)
                ddlSearchTraining.DataBind()
            Case Else
                pnlTraining.Visible = False
                pnlSearchBatch.Visible = True
                pnlSearchExceptions.Visible = False
                pnlSearchUser.Visible = False
                pnlSearchUnits.Visible = False
        End Select

        gvwTraining.DataSource = Nothing
        gvwUsers.DataSource = Nothing
        gvwUnits.DataSource = Nothing
        gvwTestExceptions.DataSource = Nothing
        bscMain.Datasource = Nothing

        gvwTraining.DataBind()
        gvwUsers.DataBind()
        gvwUnits.DataBind()
        gvwTestExceptions.DataBind()
        bscMain.DataBind()

        gvwTraining.Visible = pnlTraining.Visible
        gvwUsers.Visible = pnlSearchUser.Visible
        gvwUnits.Visible = pnlSearchUnits.Visible
        gvwTestExceptions.Visible = pnlSearchExceptions.Visible
        bscMain.Visible = pnlSearchBatch.Visible
    End Sub

    Protected Sub ddlProductType_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs)
        Dim selectedValue As String = (CType(sender, System.Web.UI.WebControls.DropDownList)).SelectedItem.Text
        Dim validSelection() As String = {"accessory", "all"}
        Dim result As Integer = (From l As String In validSelection Where selectedValue.ToLower().Contains(l) Select l).Count

        If (result > 0) Then
            ddlAccessoryGroup.Enabled = True
        Else
            ddlAccessoryGroup.Enabled = False
        End If
    End Sub

    Protected Sub ddlProductType2_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs)
        Dim selectedValue As String = (CType(sender, System.Web.UI.WebControls.DropDownList)).SelectedItem.Text
        Dim validSelection() As String = {"accessory", "all"}
        Dim result As Integer = (From l As String In validSelection Where selectedValue.ToLower().Contains(l) Select l).Count

        If (result > 0) Then
            ddlAccesssoryGroup2.Enabled = True
        Else
            ddlAccesssoryGroup2.Enabled = False
        End If

        gvwTestExceptions.DataSource = Nothing
        gvwTestExceptions.DataBind()
    End Sub

    Protected Sub gvwUsers_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwUsers.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim hplUser As HyperLink = DirectCast(e.Row.FindControl("hplUser"), HyperLink)
            Dim hplAdmin As HyperLink = DirectCast(e.Row.FindControl("hplAdmin"), HyperLink)

            hplUser.NavigateUrl = String.Format("/ManageUser/Default.aspx?userid={0}", DirectCast(e.Row.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(e.Row.RowIndex).Values(0).ToString())
            hplAdmin.NavigateUrl = String.Format("/Admin/Users.aspx?userid={0}", DirectCast(e.Row.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(e.Row.RowIndex).Values(0).ToString())
        End If
    End Sub

    Protected Sub gvwTestExceptions_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwTestExceptions.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim lnkDelete As LinkButton = DirectCast(e.Row.FindControl("lnkDelete"), LinkButton)
            Dim chk1 As CheckBox = DirectCast(e.Row.FindControl("chk1"), CheckBox)

            If (lnkDelete IsNot Nothing And Not (UserManager.GetCurrentUser.IsAdmin)) Then
                lnkDelete.Visible = If(UserManager.GetCurrentUser.IsTestCenterAdmin And e.Row.Cells(2).Text = UserManager.GetCurrentUser.TestCentre, True, False)
            End If

            If (chk1 IsNot Nothing And Not (UserManager.GetCurrentUser.IsAdmin)) Then
                chk1.Visible = If(UserManager.GetCurrentUser.IsTestCenterAdmin And e.Row.Cells(2).Text = UserManager.GetCurrentUser.TestCentre, True, False)
            End If
        End If
    End Sub

    Protected Sub gvwTraining_DataBound(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwTraining.DataBound
        If (gvwTraining.HeaderRow IsNot Nothing) Then
            Dim row As GridViewRow = gvwTraining.HeaderRow

            For Each cell As TableCell In row.Cells
                cell.Text = "<div>" & cell.Text & "</div>"
            Next
        End If
    End Sub

    Protected Sub gvwTestExceptions_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs) Handles gvwTestExceptions.RowCommand
        Dim ID As Integer
        Integer.TryParse(e.CommandArgument, ID)
        Select Case e.CommandName.ToLower()
            Case "deleteitem"
                ExceptionManager.DeleteException(ID)
                gvwTestExceptions.DataBind()
        End Select
    End Sub
#End Region
End Class