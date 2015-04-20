Imports Remi.Bll
Imports Remi.BusinessEntities

Public Class Relab_Measurements
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Dim resultID As Int32
        Dim batchID As Int32

        If (Not Page.IsPostBack) Then
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

                ddlTestStage.DataSource = (From r In New Remi.Dal.Entities().Instance().Results.Include("Results.TestStages").Include("Results.TestUnits").Include("TestUnits.Batches") _
                           Where r.TestUnit.Batch.ID = batchID _
                           Select New With {r.TestStage.ID, r.TestStage.TestStageName, r.TestStage.ProcessOrder}).Distinct().OrderBy(Function(o) o.ProcessOrder)
                ddlTestStage.DataBind()

                ddlTests.DataSource = (From r In New Remi.Dal.Entities().Instance().Results.Include("Results.Tests").Include("Results.TestUnits").Include("TestUnits.Batches") _
                           Where r.TestUnit.Batch.ID = batchID _
                           Select New With {r.Test.ID, r.Test.TestName}).Distinct().OrderBy(Function(o) o.TestName)
                ddlTests.DataBind()

                ddlUnits.DataSource = (From r In New Remi.Dal.Entities().Instance().Results Where r.TestUnit.Batch.ID = batchID Select New With {.BatchUnitNumber = r.TestUnit.BatchUnitNumber, .ID = r.TestUnit.ID}).Distinct().OrderBy(Function(o) o.BatchUnitNumber).ToList()
                ddlUnits.DataBind()

                Dim resultInfo = (From r In New REMI.Dal.Entities().Instance().Results.Include("Results.TestUnits").Include("TestUnits.Batches") _
                            Where r.ID = resultID _
                            Select New With {r.TestUnit.Batch.QRANumber, r.TestUnit.BatchUnitNumber, r.TestID, r.TestStageID}).FirstOrDefault()

                If (resultInfo Is Nothing) Then
                    Response.Redirect("/Relab/Results.aspx")
                End If

                lblHeader.Text = String.Format("Result Measurements {0} ", String.Format("{0}-{1:d3}", resultInfo.QRANumber, resultInfo.BatchUnitNumber))
                hdnUnit.Value = resultInfo.BatchUnitNumber

                hypCancel.NavigateUrl = String.Format("/Relab/Results.aspx?Batch={0}", Request.QueryString("Batch"))
                hypVersions.NavigateUrl = String.Format("/Relab/Versions.aspx?TestID={0}&Batch={1}&unitNumber={2}&TestStageID={3}", resultInfo.TestID, Request.QueryString("Batch"), resultInfo.BatchUnitNumber, resultInfo.TestStageID)

                Dim dt = (From r In New REMI.Dal.Entities().Instance().Results Where r.ID = resultID Select TestID = r.Test.ID, TestStageID = r.TestStage.ID, TestUnitID = r.TestUnit.ID)
                ddlTests.SelectedValue = dt.FirstOrDefault().TestID
                ddlTestStage.SelectedValue = dt.FirstOrDefault().TestStageID
                ddlUnits.SelectedValue = dt.FirstOrDefault().TestUnitID

                msmMeasuerments.Visible = True
                msmMeasuerments.BatchID = batchID
                msmMeasuerments.ResultID = resultID
                msmMeasuerments.TestID = ddlTests.SelectedValue
                msmMeasuerments.DataBind()
            End If
        Else
            Dim ctrl As Control = Helpers.GetPostBackControl(Page)

            If ctrl.ID = "ddlTestStage" Then
                If (ddlTests.Items.FindByText(ddlTestStage.SelectedItem.Text) IsNot Nothing) Then
                    ddlTests.SelectedValue = ddlTests.Items.FindByText(ddlTestStage.SelectedItem.Text).Value
                Else
                    ddlTests.ClearSelection()
                End If
            End If
        End If
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
End Class