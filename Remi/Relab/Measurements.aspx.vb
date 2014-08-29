Imports Remi.Bll

Public Class Measurements
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If (Not UserManager.GetCurrentUser.HasRelabAccess And Not UserManager.GetCurrentUser.HasRelabAuthority) Then
            Response.Redirect("~/")
        End If

        Dim resultID As Int32
        Dim batchID As Int32
        Int32.TryParse(Request.QueryString("ID"), resultID)
        Int32.TryParse(Request.QueryString("Batch"), batchID)

        If (resultID < 1 And batchID < 1) Then
            Response.Redirect("/Relab/Results.aspx")
        ElseIf (resultID < 1 And batchID > 0) Then
            pnlMeasurements.Visible = False
            lblNoResults.Visible = True
        ElseIf (resultID > 0 And batchID > 0) Then
            lblNoResults.Visible = False
            pnlMeasurements.Visible = True

            ddlTestStage.DataSource = (From r In New REMI.Dal.Entities().Instance().Results.Include("Results.TestStages").Include("Results.TestUnits").Include("TestUnits.Batches") _
                       Where r.TestUnit.Batch.ID = batchID _
                       Select New With {r.TestStage.ID, r.TestStage.TestStageName}).Distinct()
            ddlTestStage.DataBind()

            ddlTests.DataSource = (From r In New REMI.Dal.Entities().Instance().Results.Include("Results.Tests").Include("Results.TestUnits").Include("TestUnits.Batches") _
                       Where r.TestUnit.Batch.ID = batchID _
                       Select New With {r.Test.ID, r.Test.TestName}).Distinct()
            ddlTests.DataBind()

            ddlUnits.DataSource = (From r In New REMI.Dal.Entities().Instance().Results Where r.TestUnit.Batch.ID = batchID Select New With {.BatchUnitNumber = r.TestUnit.BatchUnitNumber, .ID = r.TestUnit.ID}).Distinct().ToList()
            ddlUnits.DataBind()

            Dim resultInfo = (From r In New REMI.Dal.Entities().Instance().Results.Include("Results.TestUnits").Include("TestUnits.Batches") _
                        Where r.ID = resultID _
                        Select New With {r.TestUnit.Batch.QRANumber, r.TestUnit.BatchUnitNumber}).FirstOrDefault()

            If (resultInfo Is Nothing) Then
                Response.Redirect("/Relab/Results.aspx")
            End If

            lblHeader.Text = String.Format("Result Measurements {0} ", String.Format("{0}-{1:d3}", resultInfo.QRANumber, resultInfo.BatchUnitNumber))
            hdnUnit.Value = resultInfo.BatchUnitNumber

            hypCancel.NavigateUrl = "/Relab/Results.aspx?Batch=" + Request.QueryString("Batch")

            Dim dt = (From r In New REMI.Dal.Entities().Instance().Results Where r.ID = resultID Select TestID = r.Test.ID, TestStageID = r.TestStage.ID, TestUnitID = r.TestUnit.ID)
            ddlTests.SelectedValue = dt.FirstOrDefault().TestID
            ddlTestStage.SelectedValue = dt.FirstOrDefault().TestStageID
            ddlUnits.SelectedValue = dt.FirstOrDefault().TestUnitID

            Dim dtmeasurements As DataTable = RelabManager.ResultMeasurements(resultID, chkOnlyFails.Checked, chkIncludeArchived.Checked)
            If (dtmeasurements.Rows.Count > 0) Then
                grdResultMeasurements.DataSource = dtmeasurements
                grdResultMeasurements.DataBind()
            Else
                chkIncludeArchived.Visible = False
                chkOnlyFails.Visible = False
                lblNoResults.Visible = True
            End If

            If (dtmeasurements.Select("MaxVersion=1").Count > 0) Then
                chkIncludeArchived.Enabled = False
            End If

            If (dtmeasurements.Select("[Pass/Fail]='Fail'").Count = 0) Then
                chkOnlyFails.Enabled = False
            End If
        End If
    End Sub

    Protected Sub SetGvwmeasurementHeader() Handles grdResultMeasurements.PreRender
        Helpers.MakeAccessable(grdResultMeasurements)
    End Sub

    Protected Sub btnSubmit_OnClick(ByVal sender As Object, ByVal e As EventArgs) Handles btnSubmit.Click
        Dim testID As Int32
        Dim TestStageID As Int32
        Dim currentResultID As Int32
        Dim unitID As Int32

        Int32.TryParse(Request.Form(ddlUnits.UniqueID), unitID)
        Int32.TryParse(Request.QueryString("ID"), currentResultID)
        Int32.TryParse(Request.Form(ddlTests.UniqueID), testID)
        Int32.TryParse(Request.Form(ddlTestStage.UniqueID), TestStageID)

        Dim resultID As Int32 = (From r In New REMI.Dal.Entities().Instance().Results Where r.Test.ID = testID And r.TestUnit.ID = unitID And r.TestStage.ID = TestStageID Select r.ID).FirstOrDefault()

        If (resultID > 0) Then
            Response.Redirect(String.Format("/Relab/Measurements.aspx?ID={0}&Batch={1}", resultID, Request.QueryString("Batch")))
        Else
            pnlMeasurements.Visible = False
            lblNoResults.Visible = True
        End If
    End Sub

    Protected Sub grdResultMeasurements_DataBound(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdResultMeasurements.DataBound
        grdResultMeasurements.HeaderRow.Cells(2).Visible = False
        grdResultMeasurements.HeaderRow.Cells(3).Visible = False
        grdResultMeasurements.HeaderRow.Cells(9).Visible = False
        grdResultMeasurements.HeaderRow.Cells(11).Visible = False
        grdResultMeasurements.HeaderRow.Cells(12).Visible = False
        grdResultMeasurements.HeaderRow.Cells(13).Visible = False
        grdResultMeasurements.HeaderRow.Cells(14).Visible = False
        grdResultMeasurements.HeaderRow.Cells(15).Visible = False
        grdResultMeasurements.HeaderRow.Cells(16).Visible = False
        grdResultMeasurements.HeaderRow.Cells(17).Visible = False
        grdResultMeasurements.HeaderRow.Cells(19).Visible = False
        grdResultMeasurements.HeaderRow.Cells(4).Width = 10
        grdResultMeasurements.HeaderRow.Cells(5).Width = 10
        grdResultMeasurements.HeaderRow.Cells(6).Width = 10
        grdResultMeasurements.HeaderRow.Cells(6).CssClass = "removeStyleWithCenter"
        grdResultMeasurements.HeaderRow.Cells(6).Wrap = True
        grdResultMeasurements.HeaderRow.Cells(6).HorizontalAlign = HorizontalAlign.Center

        For i As Int32 = 15 To grdResultMeasurements.HeaderRow.Cells.Count - 1
            grdResultMeasurements.HeaderRow.Cells(i).Wrap = True
            grdResultMeasurements.HeaderRow.Cells(i).ControlStyle.Width = 10
            grdResultMeasurements.HeaderRow.Cells(i).ControlStyle.CssClass = "removeStyleWithCenter"
        Next i

        If (grdResultMeasurements.Rows.Count > 0) Then
            For i As Int32 = 0 To grdResultMeasurements.Rows.Count - 1
                grdResultMeasurements.Rows(i).Cells(2).Visible = False
                grdResultMeasurements.Rows(i).Cells(3).Visible = False
                grdResultMeasurements.Rows(i).Cells(9).Visible = False
                grdResultMeasurements.Rows(i).Cells(11).Visible = False 'Archived
                grdResultMeasurements.Rows(i).Cells(12).Visible = False 'XMLID
                grdResultMeasurements.Rows(i).Cells(13).Visible = False 'MaxVersion
                grdResultMeasurements.Rows(i).Cells(14).Visible = False 'Comment
                grdResultMeasurements.Rows(i).Cells(15).Visible = False 'Image
                grdResultMeasurements.Rows(i).Cells(16).Visible = False 'ContentType
                grdResultMeasurements.Rows(i).Cells(17).Visible = False 'Description
                grdResultMeasurements.Rows(i).Cells(19).Visible = False 'WasChanged
                grdResultMeasurements.Rows(i).Cells(6).ControlStyle.CssClass = "removeStyleWithCenter" 'Result
                grdResultMeasurements.Rows(i).Cells(6).Wrap = True 'Result
                grdResultMeasurements.Rows(i).Cells(6).HorizontalAlign = HorizontalAlign.Center 'Result
                grdResultMeasurements.Rows(i).Cells(4).ControlStyle.Width = 60 'LL
                grdResultMeasurements.Rows(i).Cells(5).ControlStyle.Width = 60 'UL
                grdResultMeasurements.Rows(i).Cells(6).ControlStyle.Width = 220 'Result
                grdResultMeasurements.Rows(i).Cells(7).ControlStyle.Width = 50 'Unit
                grdResultMeasurements.Rows(i).Cells(8).ControlStyle.Width = 50 'Pass/Fail
                grdResultMeasurements.Rows(i).Cells(10).ControlStyle.Width = 50 'Test Num

                For j As Int32 = 19 To grdResultMeasurements.Rows(i).Cells.Count - 1 'The Parameter columns
                    grdResultMeasurements.Rows(i).Cells(j).Wrap = True
                    grdResultMeasurements.Rows(i).Cells(j).ControlStyle.CssClass = "removeStyleWithCenter"
                    grdResultMeasurements.Rows(i).Cells(j).ControlStyle.Width = 70
                Next
            Next
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

            Dim popupString As String = String.Format("<textarea id=&quot;txtComment" + grdResultMeasurements.DataKeys(e.Row.RowIndex).Values(1).ToString() + "&quot;>" + Server.HtmlDecode(e.Row.Cells(14).Text).Trim().Replace(vbCr, "\n").Replace(vbLf, "") + "</textarea><input type=&quot;checkbox&quot; id=&quot;chkPassFail{1}&quot; {3}>{0}<br/><input type=&quot;button&quot; id=&quot;btnSave&quot; value=&quot;Save Comment&quot; onclick=&quot;SaveComment(txtComment" + grdResultMeasurements.DataKeys(e.Row.RowIndex).Values(1).ToString() + "," + grdResultMeasurements.DataKeys(e.Row.RowIndex).Values(1).ToString() + ", chkPassFail" + grdResultMeasurements.DataKeys(e.Row.RowIndex).Values(1).ToString() + ", {2}, \'{0}\')&quot; />", If(e.Row.Cells(8).Text = "Pass", "Fail", "Pass"), grdResultMeasurements.DataKeys(e.Row.RowIndex).Values(1).ToString(), If(e.Row.Cells(8).Text = "Pass", "true", "false"), If(UserManager.GetCurrentUser.IsProjectManager Or UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin, "", "disabled"))

            e.Row.Cells(8).Text = String.Format("<label onmouseover=""Tip('{1}',STICKY,'true',null,'true',CLOSEBTN,'true',WIDTH,'',TITLEBGCOLOR,'#6494C8')"" onmouseout=""UnTip()"">{0}</label>", e.Row.Cells(8).Text, popupString)

            If (DataBinder.Eval(e.Row.DataItem, "WasChanged").ToString() = 1) Then
                e.Row.Cells(8).BackColor = Drawing.Color.Yellow
            End If

            Dim hdnImgStr As HiddenField = DirectCast(e.Row.FindControl("hdnImgStr"), HiddenField)
            If (Not (String.IsNullOrEmpty(hdnImgStr.Value))) Then
                If (Not (hdnImgStr.Value.Contains(";base64,AAAAAA=="))) Then
                    Dim img As Image = DirectCast(e.Row.FindControl("img"), Image)
                    img.Visible = True
                    img.ImageUrl = hdnImgStr.Value
                    img.Width = 30
                    img.Height = 30
                    img.Attributes.Add("onmouseover", String.Format("Tip('<img src=""{0}""/>',STICKY,'true',CLICKCLOSE,'true',CLOSEBTN,'true',WIDTH,'',TITLEBGCOLOR,'#6494C8')", hdnImgStr.Value))
                    img.Attributes.Add("onmouseout", "UnTip()")
                End If
            End If

            Dim hplMeasurementType As HyperLink = DirectCast(e.Row.FindControl("hplMeasurementType"), HyperLink)
            Dim lblMeasurementType As Label = DirectCast(e.Row.FindControl("lblMeasurementType"), Label)

            If Regex.IsMatch(e.Row.Cells(6).Text, "^-{0,1}[0-9 ]+$") Or Regex.IsMatch(e.Row.Cells(6).Text, "^-{0,1}[0-9]\d*(\.\d+)?$") Or e.Row.Cells(6).Text.Contains("True") Or e.Row.Cells(6).Text.Contains("Pass") Or e.Row.Cells(6).Text.Contains("Fail") Or e.Row.Cells(6).Text.Contains("False") Then
                hplMeasurementType.Visible = True
                lblMeasurementType.Visible = False
                hplMeasurementType.NavigateUrl = String.Format("/Relab/ResultGraph.aspx?BatchID={0}&MeasurementID={1}&TestID={2}", Request.QueryString("Batch"), grdResultMeasurements.DataKeys(e.Row.RowIndex).Values(1).ToString(), ddlTests.SelectedValue)
            Else
                hplMeasurementType.Visible = False
                lblMeasurementType.Visible = True
            End If

            If (Not String.IsNullOrEmpty(e.Row.Cells(16).Text) And e.Row.Cells(16).Text <> "&nbsp;") Then
                e.Row.Cells(6).Text += String.Format(" <img src='\Design\Icons\png\16x16\cloud_comment.png' onmouseover=""Tip('{0}','true',null,'true','true',WIDTH,'',TITLEBGCOLOR,'#6494C8')"" onmouseout=""UnTip()""/>", e.Row.Cells(16).Text)
            End If
        End If
    End Sub

    Protected Sub lnkExportAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkExportAction.Click
        Dim resultID As Int32
        Int32.TryParse(Request.QueryString("ID"), resultID)
        Helpers.ExportToExcel(Helpers.GetDateTimeFileName("ResultSummary", "xls"), RelabManager.ResultSummaryExport(Request.QueryString("Batch"), resultID))
    End Sub

    <System.Web.Services.WebMethod()> _
    Public Shared Function UpdateComment(ByVal value As String, ByVal ID As Int32, ByVal passFailOverride As Boolean, ByVal currentPassFail As Boolean, ByVal passFailText As String) As Boolean
        Dim instance = New REMI.Dal.Entities().Instance()

        Dim passFail As Boolean = currentPassFail
        Dim resultID As Int32
        Dim result As Entities.Result

        If (passFailOverride = True) Then
            If (passFailText.ToLower() = "pass") Then
                passFail = True
            Else
                passFail = False
            End If
        End If

        Dim measurement = (From m In instance.ResultsMeasurements.Include("Result") Where m.ID = ID Select m).FirstOrDefault()

        If (measurement IsNot Nothing) Then
            measurement.Comment = value.Replace(Chr(34), "&#34;")
            measurement.PassFail = passFail
            measurement.LastUser = UserManager.GetCurrentUser.UserName

            resultID = measurement.Result.ID
            result = measurement.Result

            instance.SaveChanges()

            If (passFailOverride = True) Then
                Dim failureCount As Int32 = (From m In instance.ResultsMeasurements Where m.Result.ID = resultID And m.Archived = False And m.PassFail = False Select m).Count()

                If (result IsNot Nothing) Then
                    result.PassFail = If(failureCount > 0, False, True)

                    instance.SaveChanges()
                End If
            End If
        End If

        Return True
    End Function
End Class