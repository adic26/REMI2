Imports Remi.BusinessEntities
Imports Remi.Validation
Imports Remi.Bll
Imports System.Data
Imports Remi.Contracts
Imports System.Drawing

Partial Class ES_Default
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If (Not Page.IsPostBack) Then
            Dim tmpStr As String = Request.QueryString.Get("QRA")
            Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(tmpStr))
            Dim b As BatchView

            If bc.Validate Then
                Dim bcol As New BatchCollection
                b = BatchManager.GetViewBatch(bc.BatchNumber)
                bcol.Add(b)

                hdnPartName.Value = (From rd In b.ReqData Where rd.Name.ToLower = "part name under test" Select rd.Value).FirstOrDefault()
                hdnBatchID.Value = b.ID
                hdnRequestNumber.Value = b.QRANumber
                lblRequestNumber.Text = b.QRANumber
                lblESText.Text = If(b.ExecutiveSummary Is Nothing, String.Empty, b.ExecutiveSummary.Replace(vbCr, "<br/>").Replace(vbCrLf, "<br/>").Replace(vbLf, "<br/>"))

                gvwRequestInfo.DataSource = b.ReqData
                gvwRequestInfo.DataBind()
                rptRequestSummary.DataSource = bcol
                rptRequestSummary.DataBind()

                gvwResultSummary.DataSource = ReportManager.ESResultSummary(b.QRANumber)
                gvwResultSummary.DataBind()

                gvwResultBreakDown.DataSource = RelabManager.ResultSummary(hdnBatchID.Value)
                gvwResultBreakDown.DataBind()

                Dim ds As DataSet = RelabManager.GetOverAllPassFail(b.ID)
                grdApproval.DataSource = ds.Tables(1)
                grdApproval.DataBind()

                SetStatus(ds.Tables(2).Rows(0)(0).ToString())

                For Each fa In (From tr In b.TestRecords Where tr.FailDocs.Count > 0 Select New With {tr.ID, tr.FailDocDS})
                    pnlFA.Style.Add("Display", "block")
                    Dim fac As FAControl
                    fac = CType(LoadControl("..\..\Controls\FAControl.ascx"), FAControl)
                    fac.EmptyDataText = "Error Loading FA!"

                    If (fa.FailDocDS.Columns.Count > 8) Then
                        fac.SetDataSource(fa.FailDocDS)
                    End If

                    fac.Visible = True
                    fac.ID = fa.ID

                    pnlFAInfo.Controls.Add(fac)
                Next

                Dim mi As New MenuItem

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
                lblResult.CssClass = "ESPass"
            Case "fail"
                lblResult.CssClass = "ESFail"
            Case "no result"
                lblResult.CssClass = "ESNoResult"
        End Select
    End Sub

    Protected Sub gvwRequestInfoGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwRequestInfo.PreRender
        Helpers.MakeAccessable(gvwRequestInfo)
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

    Protected Sub ESMenu_MenuItemClick(sender As Object, e As MenuEventArgs)
    End Sub

    'Protected Sub imgbtn_Click(ByVal sender As Object, ByVal e As System.EventArgs)
    '    Dim btndetails As ImageButton = DirectCast(sender, ImageButton)
    '    Dim gvrow As GridViewRow = DirectCast(btndetails.NamingContainer, GridViewRow)

    '    hdnTestID.Value = gvwResultBreakDown.DataKeys(gvrow.RowIndex).Values(1).ToString()
    '    hdnTestStageID.Value = gvwResultBreakDown.DataKeys(gvrow.RowIndex).Values(2).ToString()
    '    hdnUnit.Value = gvwResultBreakDown.DataKeys(gvrow.RowIndex).Values(0).ToString()
    '    Dim contextKey As String = String.Format("Test:{0},Stage:{1},Unit:{2}", hdnTestID.Value, hdnTestStageID.Value, hdnUnit.Value)

    '    sseImages.ContextKey = contextKey
    '    ModalPopupExtender1.Show()
    'End Sub

    '<System.Web.Services.WebMethod()> _
    'Public Shared Function GetSlides(ByVal contextKey As String) As AjaxControlToolkit.Slide()
    '    Dim strSplit As String() = contextKey.ToString().Split(","c)
    '    Dim context As New Dictionary(Of String, Int32)

    '    For Each d As String In strSplit
    '        Dim subSplit As String() = d.Split(":"c)
    '        context.Add(subSplit(0), subSplit(1))
    '    Next

    '    Dim dt As DataTable = RelabManager.MeasurementFiles(context.Item("Unit"), context.Item("Test"), context.Item("Stage"))
    '    Dim photos(dt.Rows.Count) As AjaxControlToolkit.Slide

    '    For i = 0 To dt.Rows.Count - 1
    '        Dim imageDataURL As String = String.Format("http://{0}:{1}/Handlers/ImageHandler.ashx?img={2}&width=1024&height=768", System.Web.HttpContext.Current.Request.ServerVariables("SERVER_Name"), System.Web.HttpContext.Current.Request.ServerVariables("SERVER_PORT"), dt.Rows(i)("ID"))
    '        Dim downloadURL As String = String.Format("http://{0}:{1}/Handlers/Download.ashx?img={2}", System.Web.HttpContext.Current.Request.ServerVariables("SERVER_Name"), System.Web.HttpContext.Current.Request.ServerVariables("SERVER_PORT"), dt.Rows(i)("ID"))
    '        Dim fileName As String = dt.Rows(i)("FileName").ToString().Substring(dt.Rows(i)("FileName").ToString().Replace("/", "\").LastIndexOf("\") + 1)

    '        If (Helpers.IsRecognisedImageFile(fileName)) Then
    '            photos(i) = New AjaxControlToolkit.Slide(imageDataURL, fileName, "<a href='" + downloadURL + "'>Download</a>")
    '        Else
    '            Select Case (IO.Path.GetExtension(fileName).ToUpper)
    '                Case "CSV"
    '                    photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/csv_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
    '                Case "XLS"
    '                Case "XLSX"
    '                    photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/xls_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
    '                Case "XML"
    '                    photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/xml_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
    '                Case "PPT"
    '                Case "PPTX"
    '                    photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/ppt_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
    '                Case "PDF"
    '                    photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/pdf_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
    '                Case "TXT"
    '                    photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/txt_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
    '                Case Else
    '                    photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/txt_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
    '            End Select
    '        End If
    '    Next

    '    Return photos
    'End Function

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

    Protected Sub gvwResultBreakDown_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwResultBreakDown.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            'If (gvwResultBreakDown.DataKeys(e.Row.RowIndex).Values(3).ToString() = "1") Then
            '    Dim img As ImageButton = DirectCast(e.Row.FindControl("img"), ImageButton)
            '    img.Visible = True
            'End If
           
            Dim resultID As Int32 = gvwResultBreakDown.DataKeys(e.Row.RowIndex).Values(0)
            Dim imgadd As HtmlImage = DirectCast(e.Row.FindControl("imgadd"), HtmlImage)
            Dim pnlmeasureBreakdown As Panel = DirectCast(e.Row.FindControl("pnlmeasureBreakdown"), Panel)
            Dim msm As REMI.Measuerments = DirectCast(e.Row.FindControl("msmMeasuerments"), REMI.Measuerments)

            If ((From m In New REMI.Dal.Entities().Instance().ResultsMeasurements Where m.ResultID = resultID And m.PassFail = False).FirstOrDefault() IsNot Nothing) Then
                msm.SetDataSource(resultID, hdnBatchID.Value)
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
End Class