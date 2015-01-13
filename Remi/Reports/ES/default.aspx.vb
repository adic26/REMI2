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

                Dim ds As DataSet = RelabManager.GetOverAllPassFail(b.ID)
                grdApproval.DataSource = ds.Tables(1)
                grdApproval.DataBind()

                SetStatus(ds.Tables(2).Rows(0)(0).ToString())

                For Each fa In (From tr In b.TestRecords Where tr.FailDocs.Count > 0 Select New With {tr.ID, tr.FailDocDS})
                    pnlFA.Visible = True
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

                If (pnlFA.Visible) Then
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

    Protected Sub gvwgrdApprovalGVWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdApproval.PreRender
        Helpers.MakeAccessable(grdApproval)
    End Sub

    Public ReadOnly Property PartName
        Get
            Return hdnPartName.Value
        End Get
    End Property

    Protected Sub ddlStatus_SelectedIndexChanged(sender As Object, e As EventArgs)
        If (RelabManager.SaveOverAllResult(hdnBatchID.Value, ddlStatus.SelectedValue)) Then
            Dim ds As DataSet = RelabManager.GetOverAllPassFail(hdnBatchID.Value)
            grdApproval.DataSource = ds.Tables(1)
            grdApproval.DataBind()

            SetStatus(ds.Tables(2).Rows(0)(0).ToString())
        End If
    End Sub

    Protected Sub ESMenu_MenuItemClick(sender As Object, e As MenuEventArgs)


    End Sub
End Class