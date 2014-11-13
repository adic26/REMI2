Imports Remi.Bll
Imports Remi.Validation
Imports Remi.BusinessEntities
Imports Remi.Contracts

Public Class Overview
    Inherits System.Web.UI.Page

    Protected Sub updOverview_PreRender() Handles updOverview.PreRender
        upLoad.Update()
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If (Me.AjaxScriptManager1.IsInAsyncPostBack) Then
            Dim asyncPostBackID As String = Helpers.GetAsyncPostBackControlID(Me)
            Dim postBackID As String = String.Empty
            Dim Control As Control = Helpers.GetPostBackControl(Me)

            If (Control IsNot Nothing) Then
                postBackID = Control.ID

                If (postBackID Is Nothing) Then
                    postBackID = String.Empty
                End If
            End If

            If ((String.IsNullOrEmpty(asyncPostBackID) Or asyncPostBackID.Contains("ddlDepartment")) And (Not postBackID.Contains("chkShowTRS"))) Then
                Dim bs As New BatchSearch()
                bs.TestStageType = TestStageType.IncomingEvaluation
                bs.Status = BatchStatus.Received
                bs.GeoLocationID = UserManager.GetCurrentUser.TestCentreID
                bs.DepartmentID = ddlDepartment.SelectedValue

                bscMainIncoming.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))
                ViewState("incoming") = bscMainIncoming.GetGridView.DataSource
            ElseIf asyncPostBackID.Contains("bscMainIncoming") Then
                Dim a As List(Of IBatch) = DirectCast(ViewState("incoming"), List(Of IBatch))
                bscMainIncoming.SetBatches(a)
            End If

            If ((String.IsNullOrEmpty(asyncPostBackID) Or asyncPostBackID.Contains("ddlDepartment")) And (Not postBackID.Contains("chkShowTRS"))) Then
                Dim bs As New BatchSearch()
                bs.Status = BatchStatus.TestingComplete
                bs.ExcludedTestStageType = BatchSearchTestStageType.NonTestingTask + BatchSearchTestStageType.FailureAnalysis
                bs.GeoLocationID = UserManager.GetCurrentUser.TestCentreID
                bs.DepartmentID = ddlDepartment.SelectedValue
                Dim bctc As BatchCollection = BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID)

                bscMainTestingComplete.SetBatches(bctc)
                ViewState("testingcomplete") = bscMainTestingComplete.GetGridView.DataSource
            ElseIf asyncPostBackID.Contains("bscMainTestingComplete") Then
                Dim a As List(Of IBatch) = DirectCast(ViewState("testingcomplete"), List(Of IBatch))
                bscMainTestingComplete.SetBatches(a)
            End If

            If ((String.IsNullOrEmpty(asyncPostBackID) Or asyncPostBackID.Contains("ddlDepartment")) And (Not postBackID.Contains("chkShowTRS"))) Then
                Dim bs As New BatchSearch()
                bs.Status = BatchStatus.Held
                bs.GeoLocationID = UserManager.GetCurrentUser.TestCentreID
                bs.DepartmentID = ddlDepartment.SelectedValue

                Dim bc As BatchCollection = BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID)

                bs.Status = Nothing
                bs.ExcludedStatus = BatchSearchBatchStatus.Complete + BatchSearchBatchStatus.Held + BatchSearchBatchStatus.NotSavedToREMI + BatchSearchBatchStatus.Quarantined + BatchSearchBatchStatus.Received + BatchSearchBatchStatus.Rejected
                bs.TestStageType = TestStageType.NonTestingTask
                bc.AddRange(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))

                bscMainHR.SetBatches(bc)
                ViewState("heldreport") = bscMainHR.GetGridView.DataSource
            ElseIf asyncPostBackID.Contains("bscMainHR") Then
                Dim a As List(Of IBatch) = DirectCast(ViewState("heldreport"), List(Of IBatch))
                bscMainHR.SetBatches(a)
            End If

            If ((String.IsNullOrEmpty(asyncPostBackID) Or asyncPostBackID.Contains("ddlDepartment")) And (Not postBackID.Contains("chkShowTRS"))) Then
                Dim bs As New BatchSearch()
                bs.TestStageType = TestStageType.Parametric
                bs.ExcludedTestStageType = BatchSearchTestStageType.EnvironmentalStress
                bs.Status = BatchStatus.InProgress
                bs.GeoLocationID = UserManager.GetCurrentUser.TestCentreID
                bs.DepartmentID = ddlDepartment.SelectedValue

                bscMainInProgress.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))
                ViewState("inprogress") = bscMainInProgress.GetGridView.DataSource
            ElseIf asyncPostBackID.Contains("bscMainInProgress") Then
                Dim a As List(Of IBatch) = DirectCast(ViewState("inprogress"), List(Of IBatch))
                bscMainInProgress.SetBatches(a)
            End If

            If ((String.IsNullOrEmpty(asyncPostBackID) Or asyncPostBackID.Contains("ddlDepartment")) And (Not postBackID.Contains("chkShowTRS"))) Then
                Dim bs As New BatchSearch()
                bs.TestStageType = TestStageType.EnvironmentalStress
                bs.ExcludedTestStageType = BatchSearchTestStageType.Parametric
                bs.Status = BatchStatus.InProgress
                bs.TrackingLocationFunction = TrackingLocationFunction.EnvironmentalStressing
                bs.GeoLocationID = UserManager.GetCurrentUser.TestCentreID
                bs.DepartmentID = ddlDepartment.SelectedValue

                bscChamber.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))
                ViewState("chamber") = bscChamber.GetGridView.DataSource
            ElseIf asyncPostBackID.Contains("bscChamber") Then
                Dim a As List(Of IBatch) = DirectCast(ViewState("chamber"), List(Of IBatch))
                bscChamber.SetBatches(a)
            End If

            If ((String.IsNullOrEmpty(asyncPostBackID) Or asyncPostBackID.Contains("ddlDepartment")) And (Not postBackID.Contains("chkShowTRS"))) Then
                Dim bs As New BatchSearch()
                bs.TestStageType = TestStageType.FailureAnalysis
                bs.GeoLocationID = UserManager.GetCurrentUser.TestCentreID
                bs.DepartmentID = ddlDepartment.SelectedValue
                bs.ExcludedStatus = BatchSearchBatchStatus.Complete + BatchSearchBatchStatus.Held + BatchSearchBatchStatus.Received + BatchSearchBatchStatus.Quarantined

                bscMainFA.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))
                ViewState("fa") = bscMainFA.GetGridView.DataSource
            ElseIf asyncPostBackID.Contains("bscMainFA") Then
                Dim a As List(Of IBatch) = DirectCast(ViewState("fa"), List(Of IBatch))
                bscMainFA.SetBatches(a)
            End If

            If ((String.IsNullOrEmpty(asyncPostBackID) Or asyncPostBackID.Contains("ddlDepartment")) And (Not postBackID.Contains("chkShowTRS"))) Then
                Dim bs As New BatchSearch()
                bs.TestStageType = TestStageType.EnvironmentalStress
                bs.ExcludedTestStageType = BatchSearchTestStageType.Parametric
                bs.Status = BatchStatus.InProgress
                bs.DepartmentID = ddlDepartment.SelectedValue
                bs.NotInTrackingLocationFunction = TrackingLocationFunction.EnvironmentalStressing
                bs.GeoLocationID = UserManager.GetCurrentUser.TestCentreID

                bscMainReadyForStressing.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID))
                ViewState("stress") = bscMainReadyForStressing.GetGridView.DataSource
            ElseIf asyncPostBackID.Contains("bscMainReadyForStressing") Then
                Dim a As List(Of IBatch) = DirectCast(ViewState("stress"), List(Of IBatch))
                bscMainReadyForStressing.SetBatches(a)
            End If

            If ((String.IsNullOrEmpty(asyncPostBackID) Or asyncPostBackID.Contains("ddlDepartment") Or asyncPostBackID.Contains("gvwTRS") Or postBackID.Contains("chkShowTRS"))) Then
                If (chkShowTRS.Checked) Then
                    pnlShowTRS.Visible = True
                    gvwTRS.DataSource = RequestManager.GetRequestsNotInREMI(ddlDepartment.SelectedItem.Text)
                    gvwTRS.DataBind()
                Else
                    pnlShowTRS.Visible = False
                End If
            End If
        End If
    End Sub

    Protected Sub Page_PreRender() Handles Me.PreLoad
        If Not Page.IsPostBack Then
            ddlDepartment.DataSource = LookupsManager.GetLookups(LookupType.Department, 0, 0, 0)
            ddlDepartment.DataBind()

            ddlDepartment.SelectedValue = UserManager.GetCurrentUser.DepartmentID
        End If
    End Sub

    Protected Sub SetgvwTRSHeader() Handles gvwTRS.PreRender
        Helpers.MakeAccessable(gvwTRS)
    End Sub

    Protected Sub gvwTRS_DataBound(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwTRS.DataBound
        If (gvwTRS.Rows.Count > 0) Then
            gvwTRS.HeaderRow.Cells(1).Visible = False
            gvwTRS.HeaderRow.Cells(2).Visible = False

            For i As Int32 = 0 To gvwTRS.Rows.Count - 1
                gvwTRS.Rows(i).Cells(1).Visible = False
                gvwTRS.Rows(i).Cells(2).Visible = False
            Next
        End If
    End Sub

    Protected Sub gvwTRS_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwTRS.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then

            Select Case e.Row.Cells(10).Text.Trim()
                Case "New Product Qualification"
                    e.Row.Cells(10).Text = "NPQ"
                Case "Outsourced Manufacturing Qualification"
                    e.Row.Cells(10).Text = "OMQ"
                Case "Outsourced Repair Qualification"
                    e.Row.Cells(10).Text = "OQ"
                Case "Production Reliability Monitoring"
                    e.Row.Cells(10).Text = "PRM"
                Case "Design/Process/Part Change Qualification"
                    e.Row.Cells(10).Text = "PCQ"
                Case "Supplier Qualification"
                    e.Row.Cells(10).Text = "SQ"
                Case e.Row.Cells(10).Text.Trim().ToLower().Contains("internal")
                    e.Row.Cells(10).Text = "IUO"
            End Select
        End If
    End Sub
End Class