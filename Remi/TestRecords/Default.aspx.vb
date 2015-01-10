Imports REMI.BusinessEntities
Imports REMI.Bll
Imports Remi.Validation

Partial Class TestRecords_Default
    Inherits System.Web.UI.Page

    Protected Sub SetGvwHeaders() Handles grdTestRecords.PreRender
        Helpers.MakeAccessable(grdTestRecords)
    End Sub

    Protected Sub RefreshPage()
        Response.Redirect(Request.Url.ToString)
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            notMain.Clear()
            'get all of the query string values
            Dim QRA As String = Request.QueryString.Get("QRA")
            Dim testName As String = Request.QueryString.Get("TestName")
            Dim testStageName As String = Request.QueryString.Get("TestStageName")
            Dim jobName As String = Request.QueryString.Get("JobName")
            Dim testUnitID As Integer = Request.QueryString.Get("TestUnitID")
            'if they're ok then continue
            If Not String.IsNullOrEmpty(QRA) Then
                ProcessQRA(QRA, testName, testStageName, jobName, testUnitID)
            End If
        End If
    End Sub

    Protected Sub ProcessQRA(ByVal QRA As String, ByVal testName As String, ByVal testStageName As String, ByVal jobName As String, ByVal testUnitID As Integer)
        Try
            Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(QRA))

            If bc.Validate Then
                Dim b As Batch = BatchManager.GetItem(bc.BatchNumber)
                If b IsNot Nothing Then
                    Dim litTitle As Literal = Master.FindControl("litPageTitle")
                    If litTitle IsNot Nothing Then
                        litTitle.Text = b.QRANumber + " Test Records"
                    End If

                    hdnQRAID.Value = b.ID
                    lblPageTitle.Text = b.QRANumber + " Test Records"
                    hdnQRANumber.Value = bc.BatchNumber
                    hypBatchInfo.NavigateUrl = b.BatchInfoLink
                    hdnJobName.Value = jobName
                    hdnTestName.Value = testName
                    hdnProductGroup.Value = b.ProductGroup
                    hdnDepartmentID.Value = b.DepartmentID
                    hdnTestStageName.Value = testStageName
                    hdnTestUnitID.Value = testUnitID
                    grdTestRecords.DataSource = b.TestRecords(bc.BatchNumber, hdnTestName.Value, hdnTestStageName.Value, hdnJobName.Value, testUnitID)
                    grdTestRecords.DataBind()

                    Dim myMenu As WebControls.Menu
                    Dim mi As New MenuItem
                    myMenu = CType(Master.FindControl("menuHeader"), WebControls.Menu)

                    mi.Text = "Batch Info"
                    mi.NavigateUrl = b.BatchInfoLink
                    myMenu.Items(0).ChildItems.Add(mi)

                    mi = New MenuItem
                    mi.Text = "Add New Record"
                    mi.NavigateUrl = b.TestRecordsAddNewLink
                    myMenu.Items(0).ChildItems.Add(mi)

                    hypAddTR.Enabled = UserManager.GetCurrentUser.DepartmentID = b.DepartmentID
                    hypAddTR.NavigateUrl = b.TestRecordsAddNewLink
                End If
            Else
                notMain.Notifications = bc.Notifications
                Exit Sub
            End If
        Catch ex As Exception
            notMain.Notifications = Helpers.GetExceptionMessages(ex)
        End Try
    End Sub

    Protected Sub lnkSummaryView_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkSummaryView.Click
        RefreshPage()
    End Sub

    Protected Sub grdTestRecords_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdTestRecords.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim lnkDelete As LinkButton = DirectCast(e.Row.FindControl("lnkDelete"), LinkButton)
            Dim hypEditDetailsLink As HyperLink = DirectCast(e.Row.FindControl("hypEditDetailsLink"), HyperLink)
            Dim testID As Int32 = DataBinder.Eval(e.Row.DataItem, "TestID")
            Dim testStageID As Int32 = DataBinder.Eval(e.Row.DataItem, "TestStageID")
            Dim testUnitID As Int32 = DataBinder.Eval(e.Row.DataItem, "TestUnitID")

            If (hypEditDetailsLink IsNot Nothing) Then
                hypEditDetailsLink.Enabled = UserManager.GetCurrentUser.DepartmentID.ToString() = hdnDepartmentID.Value
            End If

            If (lnkDelete IsNot Nothing) Then
                lnkDelete.Enabled = Remi.Bll.UserManager.GetCurrentUser.IsDeveloper
                lnkDelete.Visible = Remi.Bll.UserManager.GetCurrentUser.IsDeveloper
            End If

            If (testID > 0 And testStageID > 0) Then
                Dim resultID As Int32 = (From rm In New REMI.Dal.Entities().Instance().ResultsMeasurements _
                                          Where rm.Result.TestUnit.ID = testUnitID _
                                          And rm.Result.Test.ID = testID And rm.Result.TestStage.ID = testStageID _
                                          Select rm.Result.ID).FirstOrDefault()

                If (resultID > 0) Then
                    Dim hypRQResult As HyperLink = DirectCast(e.Row.FindControl("hypRQResult"), HyperLink)
                    hypRQResult.NavigateUrl = String.Format("/Relab/Measurements.aspx?ID={0}&Batch={1}", resultID, hdnQRAID.Value)
                    hypRQResult.Target = "_blank"
                    hypRQResult.Visible = True
                End If
            End If
        End If
    End Sub

    Protected Sub grdTestRecords_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs)
        Select Case e.CommandName.ToLower()
            Case "deleteitem"
                notMain.Notifications.Add(TestRecordManager.Delete(Convert.ToInt32(e.CommandArgument)))

                REMIAppCache.ClearAllBatchData(hdnQRANumber.Value)

                Dim b As Batch = BatchManager.GetItem(hdnQRANumber.Value)
                grdTestRecords.DataSource = b.TestRecords(hdnQRANumber.Value, hdnTestName.Value, hdnTestStageName.Value, hdnJobName.Value, hdnTestUnitID.Value)
                grdTestRecords.DataBind()
        End Select
    End Sub
End Class