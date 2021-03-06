﻿Imports Remi.BusinessEntities
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
                rblSearchBy.Items.FindByValue("4").Enabled = True 'Users
            End If

            If (testCenterAdmin Or UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.HasBatchSetupAuthority(0)) Then
                rblSearchBy.Items.FindByValue("3").Enabled = True 'Exceptions
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

    Protected Sub Page_PreRender() Handles Me.PreLoad
        If Not Page.IsPostBack Then
            ddlRequestType.DataSource = UserManager.GetCurrentUser.RequestTypes
            ddlRequestType.DataBind()

            If (ddlRequestType.Items.Count > 0 And ddlRequestType.SelectedIndex = -1) Then
                ddlRequestType.SelectedIndex = 0
            End If

            If (ddlRequestType.Items.Count = 1) Then
                ddlRequestType.Enabled = False
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
        txtRevision.Text = String.Empty
        txtTestStage.Text = String.Empty
        txtStart.Text = String.Empty
        txtEnd.Text = String.Empty
        ddlProductFilter.SelectedValue = Nothing
        ddlProductType.SelectedValue = Nothing
        ddlAccessoryGroup.SelectedValue = Nothing
        ddlRequestReason.SelectedValue = Nothing
        ddlJobs.SelectedValue = Nothing
        ddlTestStages.SelectedValue = Nothing
        ddlTestStageType.SelectedValue = Nothing
        ddlDepartment.SelectedValue = Nothing
        ddlTests.SelectedValue = Nothing
        ddlBatchStatus.SelectedValue = Nothing
        ddlPriority.SelectedValue = Nothing
        ddlUsers.SelectedValue = Nothing
        ddlTrackingLocationType.SelectedValue = Nothing
        ddlLocationFunction.SelectedValue = Nothing
        ddlNotInLocationFunction.SelectedValue = Nothing
        ddlTestCenters.SelectedValue = Nothing

        For i As Integer = 0 To chkTestStageType.Items.Count - 1
            chkTestStageType.Items(i).Selected = False
        Next

        For i As Integer = 0 To chkBatchStatus.Items.Count - 1
            chkBatchStatus.Items(i).Selected = False
        Next
    End Sub

    Protected Sub btn_OnClick(ByVal sender As Object, ByVal e As System.EventArgs)
        lblTopInfo.Visible = False

        Select Case sender.ID
            Case "btnSearching"
                If (pnlSearchUser.Visible) Then
                    Dim us As New UserSearch()
                    Dim testCenterID As Int32
                    Dim productID As Int32
                    Dim trainingID As Int32
                    Dim trainingLevelID As Int32
                    Dim byPass As Int32
                    Dim isProductManager As Int32
                    Dim isAdmin As Int32
                    Dim isTestCenterAdmin As Int32
                    Dim isTSDContact As Int32
                    Dim departmentID As Int32

                    Int32.TryParse(ddlProductFilterUser.SelectedValue, productID)
                    Int32.TryParse(ddlTestCentersUser.SelectedValue, testCenterID)
                    Int32.TryParse(ddlTraining.SelectedValue, trainingID)
                    Int32.TryParse(ddlTrainingLevel.SelectedValue, trainingLevelID)
                    Int32.TryParse(ddlDepartmentUser.SelectedValue, departmentID)

                    If (rdoByPassYes.Checked) Then
                        byPass = 1
                    ElseIf (rdoByPassNo.Checked) Then
                        byPass = 2
                    Else
                        byPass = 0
                    End If

                    If (rdoProductManagerYes.Checked) Then
                        isProductManager = 1
                    ElseIf (rdoProductManagerNo.Checked) Then
                        isProductManager = 2
                    Else
                        isProductManager = 0
                    End If

                    If (rdoTSDContacYes.Checked) Then
                        isTSDContact = 1
                    ElseIf (rdoTSDContacNo.Checked) Then
                        isTSDContact = 2
                    Else
                        isTSDContact = 0
                    End If

                    If (rdoIsAdminYes.Checked) Then
                        isAdmin = 1
                    ElseIf (rdoIsAdminNo.Checked) Then
                        isAdmin = 2
                    Else
                        isAdmin = 0
                    End If

                    If (rdoIsTestCenterAdminYes.Checked) Then
                        isTestCenterAdmin = 1
                    ElseIf (rdoIsTestCenterAdminNo.Checked) Then
                        isTestCenterAdmin = 2
                    Else
                        isTestCenterAdmin = 0
                    End If

                    us.IsTestCenterAdmin = isTestCenterAdmin
                    us.IsAdmin = isAdmin
                    us.IsProductManager = isProductManager
                    us.IsTSDContact = isTSDContact
                    us.ProductID = productID
                    us.TrainingID = trainingID
                    us.TrainingLevelID = trainingLevelID
                    us.TestCenterID = testCenterID
                    us.ByPass = byPass
                    us.DepartmentID = departmentID

                    gvwUsers.DataSource = Remi.Dal.UserDB.UserSearch(us, False, False, False)
                    gvwUsers.DataBind()

                    Helpers.MakeAccessable(gvwUsers)
                ElseIf (pnlSearchExceptions.Visible) Then
                    Dim es As New ExceptionSearch()
                    Dim accessory As Int32
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

                        gvwTestExceptions.DataSource = Remi.Dal.TestExceptionDB.ExceptionSearch(es)
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
                    Dim jobID As Int32
                    Dim testStageID As Int32
                    Dim userID As Int32
                    Dim departmentID As Int32
                    Dim trackingLocationTypeID As Int32
                    Dim geoLocationID As Int32 = ddlTestCenters.SelectedValue
                    Dim _start As DateTime
                    Dim _end As DateTime
                    Dim testStage As String = txtTestStage.Text.Trim()
                    Dim revision As String = txtRevision.Text.Trim()

                    If (geoLocationID = 0) Then
                        geoLocationID = Nothing
                    End If

                    Int32.TryParse(ddlDepartment.SelectedValue, departmentID)
                    Int32.TryParse(ddlJobs.SelectedValue, jobID)
                    bs.GeoLocationID = geoLocationID
                    bs.JobID = jobID
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
                    Int32.TryParse(ddlTrackingLocationType.SelectedValue, trackingLocationTypeID)
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
                    bs.TrackingLocationTypeID = trackingLocationTypeID
                    bs.UserID = userID

                    bs.BatchEnd = _end
                    bs.BatchStart = _start

                    bscMain.DisplayMode = Controls_BatchSelectControl.BatchSelectControlMode.SearchInfoDisplay
                    bscMain.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID, False, False, False, 0, False, False, False, False, False))
                    lblTopInfo.Visible = True
                ElseIf (pnlSearchUnits.Visible) Then
                    Dim us As New TestUnitCriteria()
                    Dim bsn As Int32
                    Int32.TryParse(txtBSN.Text, bsn)

                    us.BSN = bsn
                    us.IMEI = txtIMEI.Text

                    If (bsn > 0 Or txtIMEI.Text.Length > 0) Then
                        gvwUnits.DataSource = Remi.Dal.TestUnitDB.UnitSearch(us)
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

                    gvwTraining.DataSource = Remi.Dal.UserDB.UserSearch(us, True, False, False)
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
            Dim isProductManager As Int32
            Dim isTSDContact As Int32
            Dim isAdmin As Int32
            Dim isTestCenterAdmin As Int32

            Int32.TryParse(ddlProductFilterUser.SelectedValue, productID)
            Int32.TryParse(ddlTestCentersUser.SelectedValue, testCenterID)
            Int32.TryParse(ddlTraining.SelectedValue, trainingID)
            Int32.TryParse(ddlTrainingLevel.SelectedValue, trainingLevelID)
            Int32.TryParse(ddlDepartmentUser.SelectedValue, departmentID)

            If (rdoByPassYes.Checked) Then
                byPass = 1
            ElseIf (rdoByPassNo.Checked) Then
                byPass = 2
            Else
                byPass = 0
            End If

            If (rdoProductManagerYes.Checked) Then
                isProductManager = 1
            ElseIf (rdoProductManagerNo.Checked) Then
                isProductManager = 2
            Else
                isProductManager = 0
            End If

            If (rdoTSDContacYes.Checked) Then
                isTSDContact = 1
            ElseIf (rdoTSDContacNo.Checked) Then
                isTSDContact = 2
            Else
                isTSDContact = 0
            End If

            If (rdoIsAdminYes.Checked) Then
                isAdmin = 1
            ElseIf (rdoIsAdminNo.Checked) Then
                isAdmin = 2
            Else
                isAdmin = 0
            End If

            If (rdoIsTestCenterAdminYes.Checked) Then
                isTestCenterAdmin = 1
            ElseIf (rdoIsTestCenterAdminNo.Checked) Then
                isTestCenterAdmin = 2
            Else
                isTestCenterAdmin = 0
            End If

            us.IsTestCenterAdmin = isTestCenterAdmin
            us.IsAdmin = isAdmin
            us.IsProductManager = isProductManager
            us.IsTSDContact = isTSDContact

            us.ProductID = productID
            us.TrainingID = trainingID
            us.TrainingLevelID = trainingLevelID
            us.TestCenterID = testCenterID
            us.ByPass = byPass
            us.DepartmentID = departmentID

            Helpers.ExportToExcel(Helpers.GetDateTimeFileName("SearchUser", "xls"), REMI.Dal.UserDB.UserSearch(us, False, False, False))
        ElseIf (pnlSearchExceptions.Visible) Then
            Dim es As New ExceptionSearch()
            Dim accessory As Int32
            Dim productTypeID As Int32
            Dim testID As Int32
            Dim testStageID As Int32
            Dim jobName As String
            Dim IncludeBatches As Int32 = 0
            Dim IsMQual As Int32 = 0
            Dim testCenterID As Int32

            jobName = ddlJobs2.SelectedValue
            Int32.TryParse(ddlAccesssoryGroup2.SelectedValue, accessory)
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
            Dim jobID As Int32
            Dim userID As Int32
            Dim trackingLocationTypeID As Int32
            Dim geoLocationID As Int32 = ddlTestCenters.SelectedValue
            Dim _start As DateTime
            Dim _end As DateTime
            Dim departmentID As Int32
            Dim testStage As String = txtTestStage.Text.Trim()
            Dim revision As String = txtRevision.Text.Trim()
            Int32.TryParse(ddlJobs.SelectedValue, jobID)

            If (geoLocationID = 0) Then
                geoLocationID = Nothing
            End If

            bs.GeoLocationID = geoLocationID
            bs.JobID = jobID

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
            Int32.TryParse(ddlTrackingLocationType.SelectedValue, trackingLocationTypeID)
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
            bs.TrackingLocationTypeID = trackingLocationTypeID
            bs.UserID = userID
            bs.DepartmentID = departmentID
            bs.BatchEnd = _end
            bs.BatchStart = _start

            bscMain.DisplayMode = Controls_BatchSelectControl.BatchSelectControlMode.SearchInfoDisplay
            bscMain.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID, False, False, False, 0, False, False, False, False, False))

            Helpers.ExportToExcel(Helpers.GetDateTimeFileName("UnitSearch", "xls"), bscMain.GetGridView)
        ElseIf (pnlSearchUnits.Visible) Then
            Dim us As New TestUnitCriteria()
            Dim bsn As Int32
            Int32.TryParse(txtBSN.Text, bsn)

            us.BSN = bsn
            us.IMEI = txtIMEI.Text

            If (bsn > 0 Or txtIMEI.Text.Length > 0) Then
                Helpers.ExportToExcel(Helpers.GetDateTimeFileName("UnitSearch", "xls"), Remi.Dal.TestUnitDB.UnitSearch(us))
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

        Dim uc As UserCollection = UserManager.UserSearchList(us, False, False, False, False, False)
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
        Dim jobID As Int32
        Int32.TryParse(ddlJobs.SelectedValue.ToString(), jobID)

        ddlTestStages.DataSource = TestStageManager.GetList(0, String.Empty, False, jobID)
        ddlTestStages.DataBind()
    End Sub

    Protected Sub ddlJobs2_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlJobs2.SelectedIndexChanged
        ddlTestStages2.Items.Clear()
        ddlTestStages2.Items.Add(New ListItem("All", 0))
        ddlTestStages2.DataSource = TestStageManager.GetList(0, ddlJobs2.SelectedValue, False, 0)
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
        Dim prodList As DataTable = LookupsManager.GetLookups("Products", 0, 0, String.Empty, String.Empty, 0, False, 1, chkShowArchived.Checked)
        Dim newRow As DataRow = prodList.NewRow
        newRow("LookupID") = 0
        newRow("LookupType") = "All Products"
        prodList.Rows.InsertAt(newRow, 0)

        ddlProductFilter.Items.Clear()
        ddlProductFilter.DataSource = prodList
        ddlProductFilter.DataBind()
    End Sub

    Protected Sub ddlRequestType_SelectedIndexChanged(sender As Object, e As EventArgs)
        If (pnlSearchBatch.Visible) Then
            ddlJobs.Items.Clear()
            ddlJobs.Items.Add("ALL")
            ddlJobs.DataSource = JobManager.GetJobListDT(ddlRequestType.SelectedValue, UserManager.GetCurrentUser.ID, 0)
            ddlJobs.DataBind()
        ElseIf (pnlSearchExceptions.Visible) Then
            ddlJobs2.Items.Clear()
            ddlJobs2.Items.Add("ALL")
            ddlJobs2.DataSource = JobManager.GetJobListDT(ddlRequestType.SelectedValue, UserManager.GetCurrentUser.ID, 0)
            ddlJobs2.DataBind()
        End If
    End Sub

    Protected Sub rblSearchBy_OnSelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs)
        lblTopInfo.Visible = False
        Dim val As String = DirectCast(sender, System.Web.UI.WebControls.RadioButtonList).SelectedValue

        Dim dtProductType As DataTable = LookupsManager.GetLookups("ProductType", 0, 0, String.Empty, String.Empty, 0, False, 0, False)
        Dim drProductType() As DataRow = dtProductType.Select("LookupType = ''")
        drProductType.ElementAt(0).Item("LookupType") = "ALL"

        Dim dtAccessoryType As DataTable = LookupsManager.GetLookups("AccessoryType", 0, 0, String.Empty, String.Empty, 0, False, 0, False)
        Dim drAccessoryType() As DataRow = dtAccessoryType.Select("LookupType = ''")
        drAccessoryType.ElementAt(0).Item("LookupType") = "ALL"

        Dim prodList As DataTable = LookupsManager.GetLookups("Products", 0, 0, String.Empty, String.Empty, 0, False, 1, chkShowArchived.Checked)
        Dim newRow As DataRow = prodList.NewRow
        newRow("LookupID") = 0
        newRow("LookupType") = "All Products"
        prodList.Rows.InsertAt(newRow, 0)

        Select Case val
            Case "1"
                'Batch
                pnlSearchBatch.Visible = True
                pnlSearchExceptions.Visible = False
                pnlSearchUser.Visible = False
                pnlSearchUnits.Visible = False
                pnlTraining.Visible = False
                ddlRequestType.Visible = True

                ddlJobs.Items.Clear()
                ddlJobs.Items.Add("ALL")
                ddlJobs.DataSource = JobManager.GetJobListDT(ddlRequestType.SelectedValue, UserManager.GetCurrentUser.ID, 0)
                ddlJobs.DataBind()

                ddlProductType.Items.Clear()
                ddlProductType.DataSource = dtProductType
                ddlProductType.DataBind()

                ddlAccessoryGroup.Items.Clear()
                ddlAccessoryGroup.DataSource = dtAccessoryType
                ddlAccessoryGroup.DataBind()

                ddlPriority.Items.Clear()
                ddlPriority.DataSource = LookupsManager.GetLookups("Priority", Nothing, Nothing, String.Empty, String.Empty, 0, False, 0, False)
                ddlPriority.DataBind()

                ddlDepartment.Items.Clear()
                ddlDepartment.DataSource = LookupsManager.GetLookups("Department", Nothing, Nothing, String.Empty, String.Empty, 0, False, 0, False)
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
                ddlRequestReason.DataSource = LookupsManager.GetLookups("RequestPurpose", 0, 0, String.Empty, String.Empty, 0, False, 0, False)
                ddlRequestReason.DataBind()

                txtStart.Text = DateTime.Now.Subtract(TimeSpan.FromDays(7)).ToShortDateString()
                txtEnd.Text = DateTime.Now.ToShortDateString()

                ddlTestCenters.Items.Clear()
                ddlTestCenters.DataSource = REMI.Bll.LookupsManager.GetLookups("TestCenter", 0, 0, String.Empty, String.Empty, 0, False, 0, False)
                ddlTestCenters.DataBind()

                Dim l As ListItem = New ListItem(UserManager.GetCurrentUser.TestCentre, UserManager.GetCurrentUser.TestCentreID)
                If (ddlTestCenters.Items.Contains(l)) Then
                    ddlTestCenters.SelectedValue = UserManager.GetCurrentUser.TestCentreID
                End If
            Case "3"
                'Exceptions
                pnlTraining.Visible = False
                pnlSearchBatch.Visible = False
                pnlSearchExceptions.Visible = True
                pnlSearchUser.Visible = False
                pnlSearchUnits.Visible = False
                ddlRequestType.Visible = True

                ddlJobs2.Items.Clear()
                ddlJobs2.Items.Add("ALL")
                ddlJobs2.DataSource = JobManager.GetJobListDT(ddlRequestType.SelectedValue, UserManager.GetCurrentUser.ID, 0)
                ddlJobs2.DataBind()

                ddlProductType2.Items.Clear()
                ddlProductType2.DataSource = dtProductType
                ddlProductType2.DataBind()

                ddlAccesssoryGroup2.Items.Clear()
                ddlAccesssoryGroup2.DataSource = dtAccessoryType
                ddlAccesssoryGroup2.DataBind()

                ddlRequestReasonException.Items.Clear()
                ddlRequestReasonException.Items.Add("ALL")
                ddlRequestReasonException.DataSource = LookupsManager.GetLookups("RequestPurpose", 0, 0, String.Empty, String.Empty, 0, False, 0, False)
                ddlRequestReasonException.DataBind()
            Case "4"
                'User
                pnlTraining.Visible = False
                pnlSearchBatch.Visible = False
                pnlSearchExceptions.Visible = False
                pnlSearchUser.Visible = True
                pnlSearchUnits.Visible = False
                ddlRequestType.Visible = False

                ddlProductFilterUser.Items.Clear()
                ddlProductFilterUser.DataSource = prodList
                ddlProductFilterUser.DataBind()

                ddlTestCentersUser.Items.Clear()
                ddlTestCentersUser.DataSource = REMI.Bll.LookupsManager.GetLookups("TestCenter", 0, 0, String.Empty, String.Empty, 0, False, 0, False)
                ddlTestCentersUser.DataBind()

                ddlDepartmentUser.Items.Clear()
                ddlDepartmentUser.DataSource = REMI.Bll.LookupsManager.GetLookups("Department", 0, 0, String.Empty, String.Empty, 0, False, 0, False)
                ddlDepartmentUser.DataBind()

                Dim l As ListItem = New ListItem(UserManager.GetCurrentUser.TestCentre, UserManager.GetCurrentUser.TestCentreID)
                If (ddlTestCentersUser.Items.Contains(l)) Then
                    ddlTestCentersUser.SelectedValue = UserManager.GetCurrentUser.TestCentreID
                End If

                Dim ld As ListItem = New ListItem(UserManager.GetCurrentUser.Department, UserManager.GetCurrentUser.DepartmentID)
                If (ddlDepartmentUser.Items.Contains(ld)) Then
                    ddlDepartmentUser.SelectedValue = UserManager.GetCurrentUser.DepartmentID
                End If
            Case "2" 'Search Units
                pnlTraining.Visible = False
                pnlSearchUnits.Visible = True
                pnlSearchBatch.Visible = False
                pnlSearchExceptions.Visible = False
                pnlSearchUser.Visible = False
                ddlRequestType.Visible = False
            Case "5"
                'Training
                pnlSearchBatch.Visible = False
                pnlSearchExceptions.Visible = False
                pnlSearchUser.Visible = False
                pnlSearchUnits.Visible = False
                pnlTraining.Visible = True
                ddlRequestType.Visible = False

                ddlTestCenterTraining.Items.Clear()
                ddlTestCenterTraining.DataSource = REMI.Bll.LookupsManager.GetLookups("TestCenter", 0, 0, String.Empty, String.Empty, 0, False, 0, False)
                ddlTestCenterTraining.DataBind()

                Dim l As ListItem = New ListItem(UserManager.GetCurrentUser.TestCentre, UserManager.GetCurrentUser.TestCentreID)
                If (ddlTestCenterTraining.Items.Contains(l)) Then
                    ddlTestCenterTraining.SelectedValue = UserManager.GetCurrentUser.TestCentreID
                    ddlTestCenterTraining_SelectedIndexChanged(sender, e)
                End If

                ddlSearchTraining.Items.Clear()
                ddlSearchTraining.DataSource = REMI.Bll.LookupsManager.GetLookups("Training", 0, 0, String.Empty, String.Empty, 0, False, 0, False)
                ddlSearchTraining.DataBind()
            Case Else
                pnlTraining.Visible = False
                pnlSearchBatch.Visible = True
                pnlSearchExceptions.Visible = False
                pnlSearchUser.Visible = False
                pnlSearchUnits.Visible = False
                ddlRequestType.Visible = False
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