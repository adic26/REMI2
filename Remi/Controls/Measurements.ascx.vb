﻿Imports Remi.BusinessEntities
Imports Remi.Bll

Public Class Measurements
    Inherits System.Web.UI.UserControl

    Private _emptyDataTextMeasure As String
    Private _emptyDataTextInfo As String
    Private _showFailsOnly As Boolean
    Private _includeArchived As Boolean
    Private _showExport As Boolean
    Private _controlMode As ControlMode
    Private _isProjectManager As Boolean

    Public Enum ControlMode
        RelabDisplay = 1
        ExecutiveSummaryDisplay = 2
    End Enum

#Region "Load"
    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.PreRender
        If (Not Page.ClientScript.IsClientScriptIncludeRegistered(Me.Page.GetType(), "1.10.2")) Then
            Page.ClientScript.RegisterClientScriptInclude(Me.Page.GetType(), "1.10.2", ResolveClientUrl("/Design/scripts/jQuery/jquery-1.10.2.js"))
        End If

        If (Not Page.ClientScript.IsClientScriptIncludeRegistered(Me.Page.GetType(), "1.11.3")) Then
            Page.ClientScript.RegisterClientScriptInclude(Me.Page.GetType(), "1.11.3", ResolveClientUrl("/Design/scripts/jQueryUI/jquery-ui-1.11.3.js"))
        End If

        If (Not Page.ClientScript.IsClientScriptIncludeRegistered(Me.Page.GetType(), "wz_tooltip")) Then
            Page.ClientScript.RegisterClientScriptInclude(Me.Page.GetType(), "wz_tooltip", ResolveClientUrl("/Design/scripts/wz_tooltip.js"))
            Page.ClientScript.RegisterClientScriptInclude(Me.Page.GetType(), "ToolBox", ResolveClientUrl("/Design/scripts/ToolBox.js"))
        End If

        If (Not Page.ClientScript.IsClientScriptIncludeRegistered(Me.Page.GetType(), "ImageClick_Measurements")) Then
            Page.ClientScript.RegisterClientScriptInclude(Me.Page.GetType(), "ImageClick_Measurements", ResolveClientUrl("/Design/scripts/ImageClick_Measurements.js"))
            Page.ClientScript.RegisterClientScriptInclude(Me.Page.GetType(), "magnific-popup", ResolveClientUrl("/Design/scripts/MagnificPopup/magnific-popup.js"))

        End If

    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
    End Sub

    Public Overrides Sub DataBind()
        If (ResultID > 0 And BatchID > 0) Then
            Dim failsOnly As Boolean = False
            Dim includeArch As Boolean = False

            If (ShowFailsOnly) Then
                failsOnly = True
                chkOnlyFails.Visible = False
            Else
                failsOnly = chkOnlyFails.Checked
            End If

            If (IncludeArchived) Then
                includeArch = True
                chkIncludeArchived.Visible = False
            Else
                includeArch = chkIncludeArchived.Checked
            End If

            Dim dtMeasure As New DataTable

            If (ResultID > 0) Then
                dtMeasure = RelabManager.ResultMeasurements(ResultID, failsOnly, includeArch)
            End If

            grdResultMeasurements.EmptyDataText = EmptyDataTextMeasurement

            Dim instance = New REMI.Dal.Entities().Instance()
            _isProjectManager = (From p In UserManager.GetCurrentUser.UserDetails Where p.Field(Of String)("Name") = "Products" And p.Field(Of String)("Values") = (From b In instance.Batches Where b.ID = BatchID Select b.Product.Values).FirstOrDefault() Select p.Field(Of Boolean)("IsProductManager")).FirstOrDefault()

            If (dtMeasure.Rows.Count > 0) Then
                grdResultMeasurements.DataSource = dtMeasure
                grdResultMeasurements.DataBind()
            Else
                chkIncludeArchived.Visible = False
                chkOnlyFails.Visible = False
            End If

            If (dtMeasure.Select("MaxVersion=1").Count > 0) Then
                chkIncludeArchived.Enabled = False
            End If

            If (dtMeasure.Select("[Pass/Fail]='Fail'").Count = 0) Then
                chkOnlyFails.Enabled = False
            End If

            SetVisible(dtMeasure)

            If (pnlInformation.Visible) Then
                grdResultInformation.EmptyDataText = EmptyDataTextInformation
                grdResultInformation.DataSource = RelabManager.ResultInformation(ResultID, includeArch)
                grdResultInformation.DataBind()
            End If
        End If
    End Sub
#End Region

#Region "Methods"
    Protected Sub SetVisible(ByVal dt As DataTable)
        Select Case DisplayMode
            Case ControlMode.ExecutiveSummaryDisplay
                pnlInformation.Visible = False
                grdResultMeasurements.Visible = True
                pnlLegend.Visible = False
                chkOnlyFails.Visible = False
                lblInfo.Visible = False
                chkIncludeArchived.Visible = False
                imgExport.Visible = False

                If (grdResultMeasurements.HeaderRow IsNot Nothing) Then
                    Dim index As Int32
                    index = dt.Columns.IndexOf("Lower Limit") + 2
                    grdResultMeasurements.HeaderRow.Cells(index).Visible = False
                    index = dt.Columns.IndexOf("Upper Limit") + 2
                    grdResultMeasurements.HeaderRow.Cells(index).Visible = False
                    index = dt.Columns.IndexOf("Unit") + 2
                    grdResultMeasurements.HeaderRow.Cells(index).Visible = False
                    index = dt.Columns.IndexOf("VerNum") + 2
                    grdResultMeasurements.HeaderRow.Cells(index).Visible = False
                    index = dt.Columns.IndexOf("Test Num") + 2
                    grdResultMeasurements.HeaderRow.Cells(index).Visible = False
                    index = dt.Columns.IndexOf("Degradation") + 2
                    grdResultMeasurements.HeaderRow.Cells(index).Visible = False

                    For i As Int32 = 0 To grdResultMeasurements.Rows.Count - 1
                        index = dt.Columns.IndexOf("Lower Limit") + 2
                        grdResultMeasurements.Rows(i).Cells(index).Visible = False
                        index = dt.Columns.IndexOf("Upper Limit") + 2
                        grdResultMeasurements.Rows(i).Cells(index).Visible = False
                        index = dt.Columns.IndexOf("Unit") + 2
                        grdResultMeasurements.Rows(i).Cells(index).Visible = False
                        index = dt.Columns.IndexOf("VerNum") + 2
                        grdResultMeasurements.Rows(i).Cells(index).Visible = False
                        index = dt.Columns.IndexOf("Test Num") + 2
                        grdResultMeasurements.Rows(i).Cells(index).Visible = False
                        index = dt.Columns.IndexOf("Degradation") + 2
                        grdResultMeasurements.Rows(i).Cells(index).Visible = False
                    Next
                End If
            Case ControlMode.RelabDisplay
                pnlInformation.Visible = True
                grdResultMeasurements.Visible = True
                chkOnlyFails.Visible = True
                lblInfo.Visible = True
                chkIncludeArchived.Visible = True
                pnlLegend.Visible = True
                imgExport.Visible = ShowExport
        End Select
    End Sub
#End Region

#Region "Properties"
    Public Property DisplayMode() As ControlMode
        Get
            Return _controlMode
        End Get
        Set(ByVal value As ControlMode)
            _controlMode = value
        End Set
    End Property

    Public Property TestID() As Int32
        Get
            Return hdnTestID.Value
        End Get
        Set(value As Int32)
            hdnTestID.Value = value
        End Set
    End Property

    Public Property ResultID() As Int32
        Get
            Return hdnResultID.Value
        End Get
        Set(value As Int32)
            hdnResultID.Value = value
        End Set
    End Property

    Public Property BatchID() As Int32
        Get
            Return hdnBatchID.Value
        End Get
        Set(value As Int32)
            hdnBatchID.Value = value
        End Set
    End Property

    Public Property ShowExport() As Boolean
        Get
            Return _showExport
        End Get
        Set(value As Boolean)
            _showExport = value
        End Set
    End Property

    Public Property IncludeArchived() As Boolean
        Get
            Return _includeArchived
        End Get
        Set(ByVal value As Boolean)
            _includeArchived = value
        End Set
    End Property

    Public Property ShowFailsOnly() As Boolean
        Get
            Return _showFailsOnly
        End Get
        Set(ByVal value As Boolean)
            _showFailsOnly = value
        End Set
    End Property

    Public Property EmptyDataTextMeasurement() As String
        Get
            Return _emptyDataTextMeasure
        End Get
        Set(ByVal value As String)
            _emptyDataTextMeasure = value
        End Set
    End Property

    Public Property EmptyDataTextInformation() As String
        Get
            Return _emptyDataTextInfo
        End Get
        Set(ByVal value As String)
            _emptyDataTextInfo = value
        End Set
    End Property
#End Region

#Region "Events"
    Protected Sub chkOnlyFails_CheckedChanged(sender As Object, e As EventArgs)
        DataBind()
    End Sub

    Protected Sub chkIncludeArchived_CheckedChanged(sender As Object, e As EventArgs)
        DataBind()
    End Sub

    Protected Sub gvwWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdResultMeasurements.PreRender
        Helpers.MakeAccessable(grdResultMeasurements)
    End Sub

    Protected Sub grdResultInformationHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdResultInformation.PreRender
        Helpers.MakeAccessable(grdResultInformation)
    End Sub

    Protected Sub grdResultInformation_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdResultInformation.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            If (e.Row.Cells(3).Text.ToLower().Contains("true")) Then
                e.Row.BackColor = Drawing.Color.LightBlue
            End If
        End If
    End Sub

    Protected Sub grdResultMeasurements_DataBound(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdResultMeasurements.DataBound
        If (grdResultMeasurements.HeaderRow IsNot Nothing) Then
            grdResultMeasurements.HeaderRow.Cells(2).Visible = False 'ID
            grdResultMeasurements.HeaderRow.Cells(3).Visible = False 'Measurement (non template field)
            grdResultMeasurements.HeaderRow.Cells(9).Visible = False 'MeasurementTypeID
            grdResultMeasurements.HeaderRow.Cells(11).Visible = False 'Archived
            grdResultMeasurements.HeaderRow.Cells(12).Visible = False 'XMLID
            grdResultMeasurements.HeaderRow.Cells(13).Visible = False 'MaxVersion
            grdResultMeasurements.HeaderRow.Cells(14).Visible = False 'Comment
            grdResultMeasurements.HeaderRow.Cells(15).Visible = False 'Description
            grdResultMeasurements.HeaderRow.Cells(16).Visible = False 'WasChanged
            grdResultMeasurements.HeaderRow.Cells(18).Visible = UserManager.GetCurrentUser.IsDeveloper() ' VerNum
            grdResultMeasurements.HeaderRow.Cells(19).Visible = False 'HasFiles
            grdResultMeasurements.HeaderRow.Cells(20).Visible = False 'ResultMeasurementID

            If (grdResultMeasurements.Rows.Count > 0) Then
                For i As Int32 = 0 To grdResultMeasurements.Rows.Count - 1
                    grdResultMeasurements.Rows(i).Cells(2).Visible = False 'ID
                    grdResultMeasurements.Rows(i).Cells(3).Visible = False 'Measurement (non template field)
                    grdResultMeasurements.Rows(i).Cells(9).Visible = False 'MeasurementTypeID
                    grdResultMeasurements.Rows(i).Cells(11).Visible = False 'Archived
                    grdResultMeasurements.Rows(i).Cells(12).Visible = False 'XMLID
                    grdResultMeasurements.Rows(i).Cells(13).Visible = False 'MaxVersion
                    grdResultMeasurements.Rows(i).Cells(14).Visible = False 'Comment
                    grdResultMeasurements.Rows(i).Cells(15).Visible = False 'Description
                    grdResultMeasurements.Rows(i).Cells(16).Visible = False 'WasChanged
                    grdResultMeasurements.Rows(i).Cells(18).Visible = UserManager.GetCurrentUser.IsDeveloper() ' VerNum
                    grdResultMeasurements.Rows(i).Cells(19).Visible = False 'HasFiles
                    grdResultMeasurements.Rows(i).Cells(20).Visible = False 'ResultMeasurementID
                Next
            End If
        End If
    End Sub

    Protected Sub grdResultMeasurements_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdResultMeasurements.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            If (DataBinder.Eval(e.Row.DataItem, "Pass/Fail").ToString() = "Pass") Then
                e.Row.Cells(6).ForeColor = Drawing.Color.Green
                e.Row.Cells(8).ForeColor = Drawing.Color.Green

                e.Row.Cells(6).Font.Bold = True
                e.Row.Cells(8).Font.Bold = True
            Else
                e.Row.Cells(8).ForeColor = Drawing.Color.Red
                e.Row.Cells(8).Font.Bold = True
            End If

            If (e.Row.Cells(6).Text.Length > 20) Then
                e.Row.Cells(6).ToolTip = e.Row.Cells(6).Text
                e.Row.Cells(6).Text = e.Row.Cells(6).Text.Substring(0, 20) + "..."
                e.Row.Cells(6).HorizontalAlign = HorizontalAlign.Center
            End If

            If (DirectCast(e.Row.Cells(11).Controls(0), System.Web.UI.WebControls.CheckBox).Checked) Then
                e.Row.BackColor = Drawing.Color.LightBlue
            End If

            If DisplayMode <> ControlMode.ExecutiveSummaryDisplay Then
                Dim popupString As String = String.Format("<textarea id=&quot;txtComment" + grdResultMeasurements.DataKeys(e.Row.RowIndex).Values(1).ToString() + "&quot;>" + Server.HtmlDecode(e.Row.Cells(14).Text).Trim().Replace(vbCr, "\n").Replace(vbLf, "") + "</textarea><input type=&quot;checkbox&quot; id=&quot;chkPassFail{1}&quot; {3}>{0}<br/><input type=&quot;button&quot; id=&quot;btnSave&quot; value=&quot;Save Comment&quot; onclick=&quot;SaveComment(txtComment" + grdResultMeasurements.DataKeys(e.Row.RowIndex).Values(1).ToString() + "," + grdResultMeasurements.DataKeys(e.Row.RowIndex).Values(1).ToString() + ", chkPassFail" + grdResultMeasurements.DataKeys(e.Row.RowIndex).Values(1).ToString() + ", {2}, \'{0}\')&quot; />", If(e.Row.Cells(8).Text = "Pass", "Fail", "Pass"), grdResultMeasurements.DataKeys(e.Row.RowIndex).Values(1).ToString(), If(e.Row.Cells(8).Text = "Pass", "true", "false"), If(_isProjectManager Or UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin, "", "disabled"))
                e.Row.Cells(8).Text = String.Format("<label onmouseover=""Tip('{1}',STICKY,'true',null,'true',CLOSEBTN,'true',WIDTH,'',TITLEBGCOLOR,'#6494C8')"" onmouseout=""UnTip()"">{0}</label>", e.Row.Cells(8).Text, popupString)
            End If

            If (DataBinder.Eval(e.Row.DataItem, "WasChanged").ToString() = 1) Then
                e.Row.Cells(8).BackColor = Drawing.Color.Yellow
            End If

            If (e.Row.Cells(19).Text = "1") Then
                Dim img As HtmlInputImage = DirectCast(e.Row.FindControl("viewImages"), HtmlInputImage)
                img.Visible = True
            End If

            Dim hplMeasurementType As HyperLink = DirectCast(e.Row.FindControl("hplMeasurementType"), HyperLink)
            Dim lblMeasurementType As Label = DirectCast(e.Row.FindControl("lblMeasurementType"), Label)

            If DisplayMode <> ControlMode.ExecutiveSummaryDisplay And (Regex.IsMatch(e.Row.Cells(6).Text, "^-{0,1}[0-9 ]+$") Or Regex.IsMatch(e.Row.Cells(6).Text, "^-{0,1}[0-9]\d*(\.\d+)?$") Or e.Row.Cells(6).Text.Contains("True") Or e.Row.Cells(6).Text.Contains("Pass") Or e.Row.Cells(6).Text.Contains("Fail") Or e.Row.Cells(6).Text.Contains("False")) Then
                hplMeasurementType.Visible = True
                lblMeasurementType.Visible = False
                hplMeasurementType.NavigateUrl = String.Format("/Relab/ResultGraph.aspx?BatchID={0}&MeasurementID={1}&TestID={2}", Request.QueryString("Batch"), grdResultMeasurements.DataKeys(e.Row.RowIndex).Values(1).ToString(), TestID)
            Else
                hplMeasurementType.Visible = False
                lblMeasurementType.Visible = True
            End If

            If (Not String.IsNullOrEmpty(e.Row.Cells(15).Text) And e.Row.Cells(15).Text <> "&nbsp;" And DisplayMode <> ControlMode.ExecutiveSummaryDisplay) Then
                e.Row.Cells(6).Text += String.Format(" <img src='\Design\Icons\png\16x16\cloud_comment.png' onmouseover=""Tip('{0}','true',null,'true','true',WIDTH,'',TITLEBGCOLOR,'#6494C8')"" onmouseout=""UnTip()""/>", e.Row.Cells(15).Text)
            End If
        End If
    End Sub

    Protected Sub imgExport_Click(sender As Object, e As ImageClickEventArgs)
        Helpers.ExportToExcel(Helpers.GetDateTimeFileName("ResultSummary", "xls"), RelabManager.ResultSummaryExport(BatchID, ResultID))
    End Sub
#End Region

End Class