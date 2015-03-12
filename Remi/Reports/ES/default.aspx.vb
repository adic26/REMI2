Imports Remi.BusinessEntities
Imports Remi.Validation
Imports Remi.Bll
Imports System.Data
Imports Remi.Contracts
Imports System.Drawing

Partial Class ES_Default
    Inherits System.Web.UI.Page

    'Protected Sub Page_LoadComplete(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.LoadComplete
    '    gvwObservationSummary.Columns(1).Visible = False
    'End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If (Not Page.IsPostBack) Then
            If (Not Page.ClientScript.IsClientScriptIncludeRegistered(Me.Page.GetType(), "1.10.2")) Then
                Page.ClientScript.RegisterClientScriptInclude(Me.Page.GetType(), "1.10.2", ResolveClientUrl("/Design/scripts/jQuery/jquery-1.10.2.js"))
            End If

            lblPrinted.Text = String.Format("<b>Printed:</b> {0}", DateTime.Now.ToLongDateString())

            Dim tmpStr As String = Request.QueryString.Get("RN")
            Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(tmpStr, True))

            If bc.Validate Then
                Dim mi As New MenuItem
                Dim b As BatchView
                Dim bcol As New BatchCollection
                b = BatchManager.GetViewBatch(bc.BatchNumber)
                bcol.Add(b)

                hdnPartName.Value = (From rd In b.ReqData Where rd.Name.ToLower = "part name under test" Select rd.Value).FirstOrDefault()
                hdnBatchID.Value = b.ID
                hdnRequestNumber.Value = b.QRANumber
                lblRequestNumber.Text = b.QRANumber
                lblESText.Text = If(b.ExecutiveSummary Is Nothing, "No Summary Available!", b.ExecutiveSummary.Replace(vbCr, "<br/>").Replace(vbCrLf, "<br/>").Replace(vbLf, "<br/>"))

                gvwRequestInfo.DataSource = b.ReqData
                gvwRequestInfo.DataBind()
                rptRequestSummary.DataSource = bcol
                rptRequestSummary.DataBind()
                Dim ds As DataSet = RelabManager.GetOverAllPassFail(b.ID)
                grdApproval.DataSource = ds.Tables(1)
                grdApproval.DataBind()

                grdJIRAS.DataSource = BatchManager.GetBatchJIRA(b.ID, False)
                grdJIRAS.DataBind()

                Dim bs As New REMI.BusinessEntities.BatchSearch
                bs.ProductID = b.ProductID
                bs.JobName = b.JobName
                bs.ProductTypeID = b.ProductTypeID

                Dim batchCol As BatchCollection = BatchManager.BatchSearch(bs, True, 0, False, False, False, 1)

                For Each batch As Batch In batchCol.Take(10)
                    Dim l As New ListItem

                    If (b.ID = batch.ID) Then
                        l.Text = "<b><img src='../../Design/Icons/png/SliderOn.png' alt='" + batch.QRANumber + "' title='" + batch.QRANumber + "'/>" + batch.QRANumber + "</b>"
                    Else
                        l.Text = "<img src='../../Design/Icons/png/SliderOff.png' alt='" + batch.QRANumber + "' title='" + batch.QRANumber + "'/>" + batch.QRANumber
                    End If

                    l.Value = batch.ID
                    rboQRASlider.Items.Add(l)
                Next

                rboQRASlider.SelectedValue = b.ID

                If (rboQRASlider.Items.Count = 0) Then
                    pnlQRASlider.Visible = False
                End If

                SetStatus(ds.Tables(2).Rows(0)(0).ToString())

                For Each fa In (From tr In b.TestRecords Where tr.FailDocs.Count > 0 Distinct Select New With {tr.FailDocDS})
                    pnlFA.Style.Add("Display", "block")

                    Try
                        Dim fac As FAControl
                        fac = CType(LoadControl("..\..\Controls\FAControl.ascx"), FAControl)
                        fac.EmptyDataText = "Error Loading FA!"

                        If (fa.FailDocDS.Columns.Count > 8) Then
                            fac.SetDataSource(fa.FailDocDS)
                        End If

                        fac.Visible = True

                        pnlFAInfo.Controls.Add(fac)
                    Catch ex As Exception
                        BatchManager.LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                    End Try
                Next

                If (pnlFA.Style.Item("Display") = "block") Then
                    mi = New MenuItem
                    mi.NavigateUrl = "#fa"
                    mi.Text = "FA Summary"

                    ESMenu.Items(0).ChildItems.Add(mi)
                End If

                mi = New MenuItem
                mi.Text = "Links"
                ESMenu.Items(0).ChildItems.Add(mi)

                For Each rec As DataRow In BatchManager.GetBatchDocuments(b.QRANumber).Rows
                    mi = New MenuItem
                    mi.NavigateUrl = rec.Field(Of String)("Location")
                    mi.Text = rec.Field(Of String)("WIType")
                    mi.Target = "_blank"

                    ESMenu.Items(0).ChildItems(ESMenu.Items(0).ChildItems.Count - 1).ChildItems.Add(mi)
                Next
            End If
        End If
    End Sub

    Protected Sub SetStatus(ByVal result As String)
        lblResult.Text = result
        ddlStatus.SelectedValue = ddlStatus.Items.FindByText(lblResult.Text).Value

        Select Case lblResult.Text.ToLower
            Case "pass"
            Case "preliminary pass"
                lblResult.CssClass = "ESPass"
            Case "fail"
            Case "preliminary fail"
                lblResult.CssClass = "ESFail"
            Case "no result"
                lblResult.CssClass = "ESNoResult"
        End Select
    End Sub

    Protected Sub gvwRequestInfoGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwRequestInfo.PreRender
        Helpers.MakeAccessable(gvwRequestInfo)
    End Sub

    Protected Sub grdJIRASGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdJIRAS.PreRender
        Helpers.MakeAccessable(grdJIRAS)
    End Sub

    Protected Sub gvwResultSummaryGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwResultSummary.PreRender
        Helpers.MakeAccessable(gvwResultSummary)
    End Sub

    Protected Sub gvwResultBreakDownGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwResultBreakDown.PreRender
        Helpers.MakeAccessable(gvwResultBreakDown)
    End Sub

    Protected Sub gvwgrdApprovalGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdApproval.PreRender
        Helpers.MakeAccessable(grdApproval)
    End Sub

    Protected Sub gvwObservationsGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwObservations.PreRender
        Helpers.MakeAccessable(gvwObservations)
    End Sub

    Protected Sub gvwObservationSummaryGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwObservationSummary.PreRender
        Helpers.MakeAccessable(gvwObservationSummary)
    End Sub

    Public ReadOnly Property PartName
        Get
            Return hdnPartName.Value
        End Get
    End Property

    Protected Sub ddlStatus_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlStatus.SelectedIndexChanged
        If (RelabManager.SaveOverAllResult(hdnBatchID.Value, ddlStatus.SelectedValue)) Then
            Dim ds As DataSet = RelabManager.GetOverAllPassFail(hdnBatchID.Value)
            grdApproval.DataSource = ds.Tables(1)
            grdApproval.DataBind()

            SetStatus(ds.Tables(2).Rows(0)(0).ToString())
        End If
    End Sub

    Protected Sub gvwResultSummary_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwResultSummary.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            For Each dc As DataControlFieldCell In e.Row.Cells
                If (dc.Text.ToLower().Contains("pass")) Then
                    dc.ForeColor = Drawing.Color.Green
                    dc.Font.Bold = True
                    dc.Text = "Pass"
                ElseIf (dc.Text.ToLower().Contains("fail")) Then
                    dc.ForeColor = Drawing.Color.Red
                    dc.Font.Bold = True
                    dc.Text = "Fail"
                End If
            Next
        End If
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

    Protected Sub gvwResultBreakDown_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwResultBreakDown.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim resultID As Int32 = gvwResultBreakDown.DataKeys(e.Row.RowIndex).Values(0)
            Dim imgadd As HtmlImage = DirectCast(e.Row.FindControl("imgadd"), HtmlImage)
            Dim pnlmeasureBreakdown As Panel = DirectCast(e.Row.FindControl("pnlmeasureBreakdown"), Panel)
            Dim instance = New REMI.Dal.Entities().Instance()
            'And m.PassFail = False
            If ((From m In instance.ResultsMeasurements Where m.ResultID = resultID).FirstOrDefault() IsNot Nothing) Then
                Dim msm As Remi.Measurements = DirectCast(e.Row.FindControl("msmMeasuerments"), Remi.Measurements)

                msm.Visible = True
                msm.BatchID = hdnBatchID.Value
                msm.ResultID = resultID
                msm.TestID = 0
                msm.DataBind()
            Else
                imgadd.Visible = False
            End If

            For Each dc As DataControlFieldCell In e.Row.Cells
                If (dc.Text.ToLower().Contains("pass")) Then
                    dc.ForeColor = Drawing.Color.Green
                    dc.Font.Bold = True
                    dc.Text = "Pass"
                ElseIf (dc.Text.ToLower().Contains("fail")) Then
                    dc.ForeColor = Drawing.Color.Red
                    dc.Font.Bold = True
                    dc.Text = "Fail"
                End If
            Next
        End If
    End Sub

    Protected Sub gvwObservations_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwObservations.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim hdnHasFiles As HiddenField = DirectCast(e.Row.FindControl("hdnHasFiles"), HiddenField)

            If (hdnHasFiles.Value = "1") Then
                Dim img As HtmlInputImage = DirectCast(e.Row.FindControl("viewImages"), HtmlInputImage)
                img.Visible = True
            End If
        End If
    End Sub

    Protected Sub gvwObservationSummary_DataBound(sender As Object, e As EventArgs)
        Dim count As Int32 = gvwObservationSummary.Rows.Count

        If (count > 0) Then
            pnlObservationSummary.Enabled = True
            gvwObservationSummary.HeaderRow.Cells(1).Visible = False

            For r As Int32 = 0 To gvwObservationSummary.Rows.Count - 1
                gvwObservationSummary.Rows(r).Cells(1).Visible = False
            Next

            If (ESMenu.FindItem("Observation Summary") Is Nothing) Then
                Dim mi As MenuItem = New MenuItem
                mi.NavigateUrl = "#observationSummary"
                mi.Text = "Observation Summary"

                ESMenu.Items(0).ChildItems.Add(mi)
            End If
        Else
            pnlObservationSummary.Enabled = False
        End If
    End Sub

    Protected Sub gvwObservations_DataBound(sender As Object, e As EventArgs)
        Dim count As Int32 = gvwObservations.Rows.Count

        If (count > 0) Then
            pnlObservations.Enabled = True

            If (ESMenu.FindItem("Observations") Is Nothing) Then
                Dim mi As MenuItem = New MenuItem
                mi.NavigateUrl = "#observations"
                mi.Text = "Observations"

                ESMenu.Items(0).ChildItems.Add(mi)
            End If
        Else
            pnlObservations.Enabled = False
        End If
    End Sub
End Class