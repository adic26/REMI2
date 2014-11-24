Imports REMI.Bll
Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Contracts

Public Class Admin_Results
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack AndAlso (Not UserManager.GetCurrentUser.IsAdmin And Not UserManager.GetCurrentUser.IsTestCenterAdmin) Then
            Response.Redirect("~/")
        End If

        If (UserManager.GetCurrentUser.IsTestCenterAdmin And Not (UserManager.GetCurrentUser.IsAdmin)) Then
            Hyperlink1.Enabled = False
            Hyperlink5.Enabled = False

            If (Not UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                Hyperlink2.Enabled = False
                Hyperlink6.Enabled = False
                hypTestStages.Enabled = False
                Hyperlink7.Enabled = False
                HyperLink9.Enabled = False
            End If
        End If

        ddlBatches.DataSource = BatchManager.GetYourActiveBatchesDataTable(UserManager.GetCurrentUser.ByPassProduct, DateTime.Now.Year.ToString().Substring(2, 2), True)
        ddlBatches.DataTextField = "Name"
        ddlBatches.DataValueField = "ID"
        ddlBatches.DataBind()

        Dim batchID As Int32
        Int32.TryParse(Request.Form(ddlBatches.UniqueID), batchID)

        ddlBatches.SelectedIndex = ddlBatches.Items.IndexOf(ddlBatches.Items.FindByValue(batchID))
    End Sub

    Protected Sub btnUpload_OnClick(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnUpload.Click
        Dim resultText As String = txtXMLResult.Text.Replace("version='1.0'", "version=""1.0""").Replace("encoding='UTF-8'", "encoding=""UTF-16""").Replace("encoding=""UTF-8""", "encoding=""UTF-16""").Replace("xmlns=""urn:xmlns:relab.rim.com/ResultFile.xsd""", "xmlns:urn=""relab.rim.com/ResultFile.xsd""")
        Dim success As Boolean = False

        Dim xml As XDocument
        Try
            xml = XDocument.Parse(resultText)
        Catch ex As Exception
            xml = Nothing
        End Try

        If (resultText.Trim().Length > 0 And xml IsNot Nothing) Then
            success = RelabManager.UploadResults(resultText, String.Empty)
        End If

        txtXMLResult.Text = String.Empty
        If (success) Then
            NotifList.Notifications.Add(New Notification("i2", NotificationType.Information, "The XML File Was Uploaded Successfully"))
        Else
            NotifList.Notifications.Add(New Notification("e1", NotificationType.Information, "The XML File Was Not Uploaded Successfully"))
        End If
    End Sub

    Protected Sub ddlBatches_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlBatches.SelectedIndexChanged
        ddlUnits.Visible = True
        lblUnits.Visible = True
        Dim batchID As Int32
        Int32.TryParse(ddlBatches.SelectedValue, batchID)

        ddlUnits.DataTextField = "BatchUnitNumber"
        ddlUnits.DataValueField = "ID"
        ddlUnits.DataSource = (From t In New REMI.Dal.Entities().Instance().Results Where t.TestUnit.Batch.ID = batchID Select t.TestUnit.ID, t.TestUnit.BatchUnitNumber).Distinct().ToList()
        ddlUnits.DataBind()
    End Sub

    Protected Sub ddlUnits_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlUnits.SelectedIndexChanged
        ddlTests.Visible = True
        lblTest.Visible = True
        Dim batchID As Int32
        Int32.TryParse(ddlBatches.SelectedValue, batchID)

        ddlTests.DataTextField = "TestName"
        ddlTests.DataValueField = "ID"
        ddlTests.DataSource = (From t In New REMI.Dal.Entities().Instance().Results Where t.TestUnit.Batch.ID = batchID Select t.Test.TestName, t.Test.ID).Distinct().ToList()
        ddlTests.DataBind()
    End Sub

    Protected Sub ddlTests_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTests.SelectedIndexChanged
        ddlTestStages.Visible = True
        lblTestStage.Visible = True
        Dim batchID As Int32
        Dim testID As Int32
        Int32.TryParse(ddlBatches.SelectedValue, batchID)
        Int32.TryParse(ddlTests.SelectedValue, testID)

        ddlTestStages.DataTextField = "TestStageName"
        ddlTestStages.DataValueField = "ID"
        ddlTestStages.DataSource = (From ts In New REMI.Dal.Entities().Instance().Results Where ts.TestUnit.Batch.ID = batchID And ts.Test.ID = testID Select ts.TestStage.TestStageName, ts.TestStage.ID).Distinct().ToList()
        ddlTestStages.DataBind()
    End Sub

    Protected Sub ddlTestStages_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTestStages.SelectedIndexChanged
        ddlNewTestStages.Visible = True
        lblNewTestStage.Visible = True
        btnReassign.Visible = True
        Dim batchID As Int32
        Int32.TryParse(ddlBatches.SelectedValue, batchID)

        ddlNewTestStages.DataTextField = "tsname"
        ddlNewTestStages.DataValueField = "TestStageID"
        ddlNewTestStages.DataSource = (From i In New REMI.Dal.Entities().Instance().vw_GetTaskInfo Where i.BatchID = batchID And i.processorder > 0 And i.TestIsArchived = False And i.IsArchived = False And i.testtype = 1 Select i.tsname, i.TestStageID).Distinct().ToList()
        ddlNewTestStages.DataBind()
    End Sub

    Protected Sub btnReassign_OnClick(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnReassign.Click
        Dim batchID As Int32
        Dim testID As Int32
        Dim testStageID As Int32
        Dim newTestStageID As Int32
        Dim unitID As Int32
        Dim success As Boolean = False
        Int32.TryParse(ddlBatches.SelectedValue, batchID)
        Int32.TryParse(ddlTests.SelectedValue, testID)
        Int32.TryParse(ddlTestStages.SelectedValue, testStageID)
        Int32.TryParse(ddlNewTestStages.SelectedValue, newTestStageID)
        Int32.TryParse(ddlUnits.SelectedValue, unitID)

        success = RelabManager.ReassignTestStage(batchID, testID, testStageID, unitID, newTestStageID)

        ddlTests.Visible = False
        ddlTestStages.Visible = False
        ddlNewTestStages.Visible = False
        ddlUnits.Visible = False
        btnReassign.Visible = False
        lblNewTestStage.Visible = False
        lblTestStage.Visible = False
        lblTest.Visible = False
        lblUnits.Visible = False

        If (success) Then
            NotifList.Notifications.Add(New Notification("i2", NotificationType.Information, "Test Stage Change Completed Successfully"))
        Else
            NotifList.Notifications.Add(New Notification("e1", NotificationType.Information, "Test Stage Change Did Not Complete Successfully"))
        End If
    End Sub
End Class