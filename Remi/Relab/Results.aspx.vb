Imports Remi.Bll
Imports Remi.Validation
Imports Remi.Contracts
Imports Remi.BusinessEntities

Public Class Results
    Inherits System.Web.UI.Page

    Protected Sub Page_LoadComplete() Handles Me.LoadComplete
        updLinks.Update()
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            Dim year As Int32
            Dim batchID As Int32
            Int32.TryParse(Request.QueryString("Batch"), batchID)
            If (batchID > 0) Then
                Dim qra = (From b In New Remi.Dal.Entities().Instance().Batches Where b.ID = batchID Select b.QRANumber, b.BatchStatus).FirstOrDefault()
                If (qra.BatchStatus = 5 Or qra.BatchStatus = 7) Then
                    year = qra.QRANumber.Substring(qra.QRANumber.IndexOf("-") + 1, 2)
                End If

                DisplayQRA(year, batchID)

                If (ddlBatches.Items.IndexOf(ddlBatches.Items.FindByValue(batchID)) < 0) Then
                    notMsg.Notifications.Add(New Notification("i13", NotificationType.Information, String.Format("No Results For Batch {0}", qra.QRANumber)))
                End If
            Else
                DisplayQRA(0, 0)
            End If

            For i As Int32 = DateTime.Now.Year To DateTime.Now.Year - 4 Step -1
                ddlYear.Items.Add(New ListItem(i, i.ToString().Substring(2)))
            Next
            ddlYear.SelectedIndex = ddlYear.Items.IndexOf(ddlYear.Items.FindByValue(year))
        Else
            Dim notValidBindControls As String() = New String() {"ddlYear"}
            If (Helpers.GetPostBackControl(Me.Page) IsNot Nothing) Then
                If (Not (notValidBindControls.Contains(Helpers.GetPostBackControl(Me.Page).ID))) Then
                    UpdateLinks(Request.Form(ddlBatches.UniqueID))
                End If
            End If
        End If
    End Sub

    Private Sub DisplayQRA(ByVal year As Int32, ByVal batchID As Int32)
        Dim dt As DataTable = BatchManager.GetYourActiveBatchesDataTable(UserManager.GetCurrentUser.ByPassProduct, year, True)
        ddlBatches.DataSource = dt
        ddlBatches.DataTextField = "Name"
        ddlBatches.DataValueField = "ID"
        ddlBatches.DataBind()

        If (batchID > 0) Then
            ddlBatches.SelectedIndex = ddlBatches.Items.IndexOf(ddlBatches.Items.FindByValue(batchID))
        End If

        If (ddlBatches.SelectedValue > "0") Then
            UpdateLinks(ddlBatches.SelectedValue)
            ddlBatches_SelectedIndexChanged(ddlBatches, Nothing)
        End If
    End Sub

    Private Sub UpdateLinks(ByVal batch As Int32)
        Dim batchID As Int32 = batch
        Dim isProcessed As Boolean = False
        Dim resultID As Int32 = (From r In New REMI.Dal.Entities().Instance().Results _
                                 Where r.TestUnit.Batch.ID = batchID _
                                 Select r.ID).FirstOrDefault()

        Dim instance = New REMI.Dal.Entities().Instance()
        Dim resultXml As IQueryable(Of REMI.Entities.ResultsXML)
        resultXml = (From rx In instance.ResultsXMLs Where rx.Result.ID = resultID Select rx)

        If (resultXml.FirstOrDefault() IsNot Nothing) Then
            isProcessed = (From x In New REMI.Dal.Entities().Instance().ResultsXMLs _
                                     Where x.Result.ID = resultID _
                                     Select processed = x.isProcessed).FirstOrDefault()
        End If

        If (isProcessed) Then
            lnkExportAction.Enabled = True
            hypGraph.Enabled = True
            lnkExportAction.ToolTip = "Export Results"
            hypGraph.ToolTip = "Graph The Results"
        Else
            lnkExportAction.ToolTip = "Result File Being Processed Come Back Later"
            hypGraph.ToolTip = "Result File Being Processed Come Back Later"
        End If

        If (batch > 0) Then
            hypBatch.NavigateUrl = Core.REMIWebLinks.GetBatchInfoLink(ddlBatches.SelectedItem.Text.Split(" ")(0))
            lnkExportAction.Visible = True
            imgExportAction.Visible = True

            hypGraph.NavigateUrl = String.Format("/Relab/ResultGraph.aspx?BatchID={0}", ddlBatches.SelectedItem.Value)
            imgGraph.Visible = True
            hypGraph.Visible = True
        End If
    End Sub

    Protected Sub chkTestStageSummary_SelectedCheckChanged(ByVal sender As Object, ByVal e As System.EventArgs)
        pnlTestStageSummary.Visible = Not (pnlTestStageSummary.Visible)
    End Sub

    Protected Sub ddlYear_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlYear.SelectedIndexChanged
        DisplayQRA(ddlYear.SelectedValue, 0)
    End Sub

    Protected Sub ddlBatches_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlBatches.SelectedIndexChanged
        Dim status As Int32 = (From b In New REMI.Dal.Entities().Instance().Batches Where b.ID = ddlBatches.SelectedValue Select b.BatchStatus).FirstOrDefault()
        Dim list = (From t In New REMI.Dal.Entities().Instance().Results Where t.PassFail = 0 And t.TestUnit.Batch.ID = ddlBatches.SelectedValue Select New With {.TestID = t.Test.ID, .tname = t.Test.TestName}).Distinct().OrderBy(Function(r) r.tname)
        Dim list2 = (From t In New String() {String.Empty} Select New With {.TestID = 0, .tname = "Select..."})
        Dim union = list2.Union(list)

        If (list.Count > 0) Then
            updFailureAnalysis.Visible = True
        Else
            updFailureAnalysis.Visible = False
        End If

        ddlTests.DataSource = union
        ddlTests.DataBind()
    End Sub

    Protected Sub SetGvwBatchesHeader() Handles grdResultSummary.PreRender
        Helpers.MakeAccessable(grdResultSummary)
    End Sub

    Protected Sub SetgrdFailureAnalysisHeader() Handles grdFailureAnalysis.PreRender
        Helpers.MakeAccessable(grdFailureAnalysis)
    End Sub

    Protected Sub SetGvwoverallBatchesHeader() Handles grdOverallSummary.PreRender
        Helpers.MakeAccessable(grdOverallSummary)
    End Sub

    Protected Sub lnkExportAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkExportAction.Click
        If (ddlBatches.SelectedItem.Value > 1) Then
            Helpers.ExportToExcel(Helpers.GetDateTimeFileName("ResultaSummary", "xls"), RelabManager.ResultSummaryExport(ddlBatches.SelectedItem.Value, 0))
        End If
    End Sub

    Protected Sub grdOverallSummary_DataBound(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdOverallSummary.DataBound
        If (grdOverallSummary.Rows.Count = 0) Then
            lnkExportAction.Enabled = False
            hypGraph.Enabled = False
        End If
    End Sub

    Protected Sub grdFailureAnalysis_DataBound(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdFailureAnalysis.DataBound
        If (grdFailureAnalysis.Rows.Count > 0) Then
            grdFailureAnalysis.HeaderRow.Cells(4).Visible = False
            grdFailureAnalysis.HeaderRow.Cells(5).Visible = False

            For i As Int32 = 0 To grdFailureAnalysis.Rows.Count - 1
                grdFailureAnalysis.Rows(i).Cells(4).Visible = False
                grdFailureAnalysis.Rows(i).Cells(5).Visible = False
            Next
        End If
    End Sub

    Protected Sub grdFailureAnalysis_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdFailureAnalysis.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            If (String.IsNullOrEmpty(e.Row.Cells(4).Text) Or e.Row.Cells(4).Text = "&nbsp;") Then
                Dim hplDetail As HyperLink = DirectCast(e.Row.FindControl("hplDetail"), HyperLink)
                hplDetail.Visible = False
            End If

            For Each dc As DataControlFieldCell In e.Row.Cells
                Dim num As Int32
                Int32.TryParse(dc.Text, num)

                If (num > 0) Then
                    Dim link As New HyperLink()
                    link.ID = "hplBatch"
                    link.Text = "1"
                    link.Target = "_blank"
                    link.NavigateUrl = String.Format("/Relab/Measurements.aspx?ID={0}&Batch={1}", num, ddlBatches.SelectedValue)
                    link.ForeColor = Drawing.Color.Red
                    link.Font.Bold = True

                    dc.Controls.Add(link)
                End If
            Next
        End If
    End Sub

    Protected Sub grdOverallSummary_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdOverallSummary.RowDataBound
        If e.Row.RowType = DataControlRowType.Header Then
            e.Row.Cells(1).Visible = False
        End If

        If e.Row.RowType = DataControlRowType.DataRow Then
            e.Row.Cells(2).CssClass = "removeStyle"
            e.Row.Cells(1).Visible = False

            Dim batchInfo = (From b In New Remi.Dal.Entities().Instance().Batches Where b.ID = ddlBatches.SelectedValue Select b.Product.Lookup.Values, b.DepartmentID).FirstOrDefault()
            Dim hasEditAuthority As Boolean = UserManager.GetCurrentUser.HasEditItemAuthority(batchInfo.Values, batchInfo.DepartmentID)

            For Each dc As DataControlFieldCell In e.Row.Cells
                Dim text As String = String.Empty
                Dim replaceText As Boolean = False

                If (dc.Text.Contains("Y (") Or dc.Text.Contains("P (") Or dc.Text = "Y" Or dc.Text = "P" Or dc.Text = "P *") Then
                    dc.ForeColor = Drawing.Color.Green
                    dc.Font.Bold = True
                    replaceText = True
                ElseIf (dc.Text.Contains("N/S")) Then
                    dc.ForeColor = Drawing.Color.DarkGray
                    replaceText = True
                ElseIf (dc.Text.Contains("N (") Or dc.Text.Contains("F (") Or dc.Text = "N" Or dc.Text = "F" Or dc.Text = "F *") Then
                    dc.ForeColor = Drawing.Color.Red
                    dc.Font.Bold = True
                    replaceText = True
                End If

                If (dc.Text.Contains("*")) Then
                    dc.BackColor = Drawing.Color.Yellow
                End If

                If (replaceText) Then
                    dc.Text = dc.Text.Replace(" *", String.Empty)
                    If (hasEditAuthority) Then
                        text = dc.Text
                    Else
                        If (dc.Text.IndexOf(" ") > 0) Then
                            text = dc.Text.Substring(0, dc.Text.IndexOf(" "))
                        Else
                            text = dc.Text
                        End If
                    End If

                    dc.Text = text
                End If
            Next

            Dim testID As Int32 = e.Row.Cells(1).Text
            Dim resultID As Int32 = (From r In New REMI.Dal.Entities().Instance().Results Where r.TestUnit.Batch.ID = ddlBatches.SelectedItem.Value And r.Test.ID = testID Select r.ID).FirstOrDefault()

            Dim hplVersions As HyperLink = DirectCast(e.Row.FindControl("hplVersions"), HyperLink)

            If (hplVersions IsNot Nothing) Then
                hplVersions.NavigateUrl = String.Format("/Relab/Versions.aspx?TestID={0}&Batch={1}", DirectCast(e.Row.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(e.Row.RowIndex).Values(0).ToString(), ddlBatches.SelectedItem.Value)

                If (resultID < 1) Then
                    hplVersions.Visible = False
                End If
            End If
        End If
    End Sub

    Protected Sub grdResultSummary_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdResultSummary.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim hplDetail As HyperLink = DirectCast(e.Row.FindControl("hplDetail"), HyperLink)
            hplDetail.NavigateUrl = String.Format("/Relab/Measurements.aspx?ID={0}&Batch={1}", DirectCast(e.Row.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(e.Row.RowIndex).Values(0).ToString(), ddlBatches.SelectedItem.Value)

            If (DataBinder.Eval(e.Row.DataItem, "PassFail").ToString() = "Pass") Then
                e.Row.Cells(4).ForeColor = Drawing.Color.Green
                e.Row.Cells(4).Font.Bold = True
            Else
                e.Row.Cells(4).ForeColor = Drawing.Color.Red
                e.Row.Cells(4).Font.Bold = True
            End If
        End If
    End Sub
End Class