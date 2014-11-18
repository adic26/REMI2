Imports Remi.BusinessEntities
Imports Remi.Validation
Imports Remi.Bll
Imports System.Data
Imports Remi.Contracts
Imports System.Drawing

Partial Class ES_Default
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Dim qra As String = Request.QueryString.Get("QRA")
        Dim b As BatchView = BatchManager.GetViewBatch(qra)
        Dim instance = New Remi.Dal.Entities().Instance()

        lblES.Text = b.ExecutiveSummary

        Dim tRow As New TableRow()
        Dim tCell As New TableCell()
        tCell.Text = "Test Details"
        tCell.CssClass = "executiveSummaryQRALeft"
        tCell.RowSpan = 4
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Requested Test"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.ColumnSpan = 2
        tCell.Text = b.JobName
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Request #"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        Dim trs As New HyperLink()
        trs.Target = "_blank"
        trs.Text = b.QRANumber
        trs.NavigateUrl = b.RequestLink
        tCell.Controls.Add(trs)
        tCell.ColumnSpan = 2
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Purpose"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.ColumnSpan = 2
        tCell.Text = b.RequestPurpose
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Requestor"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = b.Requestor
        tCell.ColumnSpan = 2
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Reason For Request"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Wrap = True
        tCell.Width = 400
        tCell.Text = Server.HtmlDecode((From r In b.ReqData Where r.IntField = "ReasonForRequest" Select r.Value).FirstOrDefault()).Replace(vbCr, "").Replace(vbLf, "</br>")
        tCell.ColumnSpan = 5
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Associated FA, TDA and MIL"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")

        Dim list As List(Of String) = (From tr In b.TestRecords Where tr.FailDocCSVList.Count > 0 Select tr.FailDocLiteralHTMLLinkList).ToList

        For Each fa In list
            If (Not tCell.Text.Contains(fa)) Then
                tCell.Text += String.Format("{0}<br/>", fa)
            End If
        Next
        tCell.ColumnSpan = 5
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Text = "Test Conditions"
        tCell.CssClass = "executiveSummaryQRALeft"
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Test Procedure"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        Dim proc As New HyperLink()
        proc.Target = "_blank"
        proc.Text = (From j In instance.Jobs Where j.JobName = b.JobName Select j.ProcedureLocation).FirstOrDefault().Replace("http://hwqaweb.rim.net/pls/trs/rim_rts?req=", String.Empty)
        proc.NavigateUrl = (From j In instance.Jobs Where j.JobName = b.JobName Select j.ProcedureLocation).FirstOrDefault()
        tCell.Controls.Add(proc)
        tCell.ColumnSpan = 5
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Text = "Product Details"
        tCell.CssClass = "executiveSummaryQRALeft"
        tCell.RowSpan = 3
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Group"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.ColumnSpan = 2
        tCell.Text = b.ProductGroup
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Type"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = b.ProductType
        tCell.ColumnSpan = 2
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Part under test"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = String.Empty 'b.PartName
        tCell.ColumnSpan = 5
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Part Number"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = String.Empty 'b.AssemblyNumber
        tCell.ColumnSpan = 5
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Text = "Submission Details"
        tCell.CssClass = "executiveSummaryQRALeft"
        tCell.RowSpan = 4
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Sample Size"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.ColumnSpan = 2
        tCell.Text = b.NumberOfUnits
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "CPR #"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = b.CPRNumber
        tCell.ColumnSpan = 2
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Board Revision"
        tCell.Font.Bold = True
        tCell.RowSpan = 2
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Major"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = String.Empty ' b.TRSData.BoardRevision
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Mechanical Tools Revision"
        tCell.Font.Bold = True
        tCell.RowSpan = 2
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Major"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = String.Empty 'b.TRSData.MechanicalToolsRevisionMajor
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Minor"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = String.Empty ' b.TRSData.BoardRevisionMinor
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Minor"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = String.Empty 'b.TRSData.MechanicalToolsRevisionMinor
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "POP"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = String.Empty 'b.TRSData.POPNumber
        tCell.ColumnSpan = 2
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "ASY"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = String.Empty ' String.Format("{0} {1}", b.AssemblyNumber, b.AssemblyRevision)
        tCell.ColumnSpan = 2
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Text = "Test Dates"
        tCell.CssClass = "executiveSummaryQRALeft"
        tCell.RowSpan = 2
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Test Submitted"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = String.Empty
        tCell.ColumnSpan = 2
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Samples Received"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = String.Empty '((From r In b.ReqData Where r.IntField = "SampleAvailableDate" Select r.Value).FirstOrDefault()).ToString("MMM d yyyy")
        tCell.ColumnSpan = 2
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        tRow = New TableRow()
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Test Start"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = String.Empty 'b.TRSData.ActualStartDate.ToString("MMM d yyyy")
        tCell.ColumnSpan = 2
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = "Test Complete"
        tCell.Font.Bold = True
        tRow.Cells.Add(tCell)
        tCell = New TableCell()
        tCell.Style.Add("text-align", "left")
        tCell.Text = String.Empty 'b.TRSData.ActualEndDate.ToString("MMM d yyyy")
        tCell.ColumnSpan = 2
        tRow.Cells.Add(tCell)
        tblInfo.Rows.Add(tRow)

        grdOverallSummary.DataSource = RelabManager.OverallResultSummary(b.ID)
        grdOverallSummary.DataBind()

        For Each tst In (From r In instance.Results Where r.TestUnit.Batch.ID = b.ID And r.PassFail = 0 Select r.Test).Distinct()
            Dim gv As New GridView()
            gv.ID = String.Format("grdFailureAnalysis{0}", tst.ID)
            AddHandler gv.DataBound, AddressOf Me.grdFailureAnalysis_DataBound
            AddHandler gv.RowDataBound, AddressOf Me.grdFailureAnalysis_RowDataBound
            gv.DataSource = RelabManager.FailureAnalysis(tst.ID, b.ID)
            gv.DataBind()

            Helpers.MakeAccessable(gv)

            Dim lbl As New Label()
            lbl.Font.Bold = True
            lbl.Text = String.Format("{0}:", tst.TestName)

            pnlFailures.Controls.Add(lbl)
            pnlFailures.Controls.Add(gv)
            'tr.Status = TestRecordStatus.FARaised And 
            For Each record In (From tr In b.TestRecords Where tr.TestID = tst.ID Select tr)
                Dim lblStage As New Label()
                lblStage.Text = String.Format("<b>Test Stage:</b> {0} <br/>", record.TestStageName)

                Dim lblUnit As New Label()
                lblUnit.Text = String.Format("<b>Unit:</b> {0} <br/>", record.BatchUnitNumber)

                Dim lblDescription As New Label()
                lblDescription.Text = String.Format("<b>Failure Description:</b> {0} <br/>", record.Comments)

                Dim measurement = (From m In instance.ResultsMeasurements Where m.Result.TestStage.ID = record.TestStageID And m.Result.Test.ID = record.TestID And m.Result.TestUnit.ID = record.TestUnitID And m.PassFail = 0 And m.Archived = False Select New With {.value = m.MeasurementValue, .ID = m.ID, .Name = m.Lookup.Values})

                For Each measure In measurement
                    Dim dt As DataTable = RelabManager.GetMeasurementParameterCommaSeparated(measure.ID)
                    lblDescription.Text += String.Format("{0} {1} {2}<br/>", measure.Name, If(dt.Rows.Count > 0, String.Format("{0}", If(dt.Rows(0)(0) IsNot DBNull.Value, dt(0)(0) + " " + dt(0)(1) + ":", String.Empty)), String.Empty), measure.value)
                Next

                lblDescription.Text += "<br/>"

                Dim lblFA As New Label()

                For Each rec In record.FailDocs
                    Dim fa As Dictionary(Of String, String) = Remi.Dal.RequestDB.GetExternalRequestNotLinked(rec.Item("RequestNumber"), "Oracle")
                    lblFA.Text += String.Format("<a href=""{0}"" target=""_blank"">{1}</a> - <b>Root Cause</b> {2}<br/>", rec.Item("Request Link"), rec.Item("RequestNumber"), Remi.Dal.RequestDB.GetProperty("RootCause", fa))
                Next

                pnlFailures.Controls.Add(lblFA)
                pnlFailures.Controls.Add(lblStage)
                pnlFailures.Controls.Add(lblUnit)
                pnlFailures.Controls.Add(lblDescription)

                If (tst.ID = 1073) Then
                    Dim count As Int32 = 1
                    For Each i In (From image In instance.ResultsMeasurementsFiles Where image.ResultsMeasurement.Result.Test.ID = record.TestID And image.ResultsMeasurement.Result.TestUnit.ID = record.TestUnitID And image.ResultsMeasurement.Result.TestStage.ID = record.TestStageID Select image)
                        Dim img As New System.Web.UI.WebControls.Image
                        img.Width = 200
                        img.Height = 200
                        img.ImageUrl = "data:image/" + i.ContentType + ";base64," + Convert.ToBase64String(i.File)

                        If (count Mod 5 = 0) Then
                            pnlFailures.Controls.Add(New Label() With {.Text = "<br/>"})
                        End If

                        count += 1
                        pnlFailures.Controls.Add(img)
                    Next

                    pnlFailures.Controls.Add(New Label() With {.Text = "<br/>"})
                End If
            Next
        Next

        If (pnlFailures.Controls.Count > 1) Then
            pnlFailures.Visible = True
        End If
    End Sub

    Protected Sub grdFailureAnalysis_DataBound(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim grid As GridView = DirectCast(sender, GridView)

        If (grid.Rows.Count > 0) Then
            grid.HeaderRow.Cells(3).Visible = False
            grid.HeaderRow.Cells(4).Visible = False

            For i As Int32 = 0 To grid.Rows.Count - 1
                grid.Rows(i).Cells(3).Visible = False
                grid.Rows(i).Cells(4).Visible = False
            Next
        End If
    End Sub

    Protected Sub grdFailureAnalysis_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs)
        If e.Row.RowType = DataControlRowType.DataRow Then
            For Each dc As DataControlFieldCell In e.Row.Cells
                Dim num As Int32
                Int32.TryParse(dc.Text, num)

                If (num > 0) Then
                    dc.ForeColor = Drawing.Color.Red
                    dc.Font.Bold = True
                End If
            Next
        End If
    End Sub

    Protected Sub SetGvwoverallBatchesHeader() Handles grdOverallSummary.PreRender
        Helpers.MakeAccessable(grdOverallSummary)
    End Sub

    Protected Sub grdOverallSummary_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdOverallSummary.RowDataBound
        If e.Row.RowType = DataControlRowType.Header Then
            e.Row.Cells(0).Visible = False
        End If

        If e.Row.RowType = DataControlRowType.DataRow Then
            e.Row.Cells(1).CssClass = "removeStyle"
            e.Row.Cells(0).Visible = False

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

                    If (dc.Text.IndexOf(" ") > 0) Then
                        text = dc.Text.Substring(0, dc.Text.IndexOf(" "))
                    Else
                        text = dc.Text
                    End If

                    dc.Text = text
                End If
            Next
        End If
    End Sub
End Class