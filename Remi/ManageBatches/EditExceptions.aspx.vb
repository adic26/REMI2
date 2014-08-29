Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports System.Data
Imports REMI.Contracts

Partial Class ManageBatches_EditExceptions
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            notMain.Clear()

            Dim qra As String = Request.QueryString.Get("QRA")
            If Not String.IsNullOrEmpty(qra) Then
                ProcessQRA(qra)
            End If
        End If
    End Sub

    Protected Sub UpdateTestExceptionsGridviewHeader() Handles gvwTestExceptions.PreRender
        gvwTestExceptions.PagerSettings.Mode = PagerButtons.NumericFirstLast
        Helpers.MakeAccessable(gvwTestExceptions)
    End Sub

    Protected Sub SaveException()
        Try
            Dim tex As New TestException()
            tex.QRAnumber = hdnQRANumber.Value
            tex.JobName = hdnJobName.Value

            If ddlTests.SelectedItem.Text <> "All" Then
                tex.TestName = ddlTests.SelectedItem.Text
                tex.TestID = ddlTests.SelectedValue
            End If

            If ddlTestStageSelection.SelectedItem.Text <> "All" Then
                tex.TestStageName = ddlTestStageSelection.SelectedItem.Text
                tex.TestStageID = CInt(ddlTestStageSelection.SelectedValue)
            End If

            If (lblProductType.Text.Trim().Length > 0) Then
                tex.ProductType = lblProductType.Text
            End If

            If (lblAccessoryGroup.Text.Trim().Length > 0) Then
                tex.AccessoryGroupName = lblAccessoryGroup.Text
            End If

            If (UserManager.GetCurrentUser.IsTestCenterAdmin And Not (UserManager.GetCurrentUser.IsAdmin)) Then
                tex.TestCenterID = UserManager.GetCurrentUser.TestCentreID
                tex.TestCenter = UserManager.GetCurrentUser.TestCentre
            End If

            For Each li As ListItem In cblUnit.Items
                If (cblUnit.Items.FindByText("All").Selected Or li.Selected) And li.Value <> "All" Then
                    tex.UnitNumber = CInt(li.Value)
                    notMain.Notifications.Add(ExceptionManager.AddException(tex))
                End If
            Next
        Catch ex As Exception
            notMain.Add(String.Format("Unable to save exceptions ({0}). Try hitting refresh and trying again. Do not use the browser back button to navigate to this page.", ex.Message), NotificationType.Errors)
        End Try
    End Sub

    Protected Sub ProcessQRA(ByVal QRANumber As String)
        Dim bc As DeviceBarcodeNumber = New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))
        Dim b As Batch

        If bc.Validate Then
            b = BatchManager.GetItem(bc.BatchNumber)

            If (Not UserManager.GetCurrentUser.HasEditItemAuthority(b.ProductGroup) And Not UserManager.GetCurrentUser.IsTestCenterAdmin And Not UserManager.GetCurrentUser.HasBatchSetupAuthority) Then
                Response.Redirect(b.BatchInfoLink, True)
            End If

            hdnQRANumber.Value = b.QRANumber
            lblQRANumber.Text = "Edit " + b.QRANumber + " Exceptions"
            hypBatchInfo.NavigateUrl = b.BatchInfoLink
            hypCancel.NavigateUrl = b.BatchInfoLink
            hypRefresh.NavigateUrl = b.ExceptionManagerLink

            ddlTestStageSelection.Items.Clear()
            ddlTestStageSelection.Items.Add("All")
            ddlTestStageSelection.DataSource = (From t In b.Tasks Where t.ProcessOrder > -1 And t.IsArchived <> True Select t.TestStageID, t.TestStageName Distinct).ToList()
            ddlTestStageSelection.DataBind()

            ddlTests.Items.Clear()
            ddlTests.Items.Add("All")
            ddlTests.DataSource = (From t In b.Tasks Where t.ProcessOrder > -1 And t.IsArchived <> True And t.TestIsArchived <> True Select t.TestName, t.TestID Distinct Order By TestName).ToList()
            ddlTests.DataBind()

            hdnJobName.Value = b.JobName
            cblUnit.Items.Add("All")
            cblUnit.DataSource = (From t As TestUnit In b.TestUnits Order By t.BatchUnitNumber Select t.BatchUnitNumber).ToList
            cblUnit.DataBind()

            lblProductType.Text = b.ProductType
            lblAccessoryGroup.Text = b.AccessoryGroup
        Else
            notMain.Notifications = bc.Notifications
            Exit Sub
        End If
    End Sub

    Protected Sub gvwTestExceptions_OnRowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs)
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim lnkDelete As LinkButton = DirectCast(e.Row.FindControl("lnkDelete"), LinkButton)
            Dim chk1 As CheckBox = DirectCast(e.Row.FindControl("chk1"), CheckBox)

            If (e.Row.Cells(7).Text = "0") Then
                lnkDelete.Visible = False
                chk1.Visible = False
            End If

            If (lnkDelete IsNot Nothing) Then
                lnkDelete.Visible = If(UserManager.GetCurrentUser.IsTestCenterAdmin And e.Row.Cells(0).Text <> UserManager.GetCurrentUser.TestCentre, False, True)
            End If

            If (chk1 IsNot Nothing) Then
                chk1.Visible = If(UserManager.GetCurrentUser.IsTestCenterAdmin And e.Row.Cells(0).Text <> UserManager.GetCurrentUser.TestCentre, False, True)
            End If
        End If
    End Sub

    Protected Sub lkbSaveExceptions_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lkbSaveExceptions.Click
        SaveException()
        gvwTestExceptions.DataBind()
    End Sub

    Protected Sub ddlTestStageSelection_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTestStageSelection.SelectedIndexChanged
        Dim testStageId As Integer
        Dim b As Batch = BatchManager.GetItem(hdnQRANumber.Value)

        If Integer.TryParse(ddlTestStageSelection.SelectedValue, testStageId) Then
            ddlTests.Items.Clear()
            ddlTests.Items.Add("All")
            ddlTests.DataSource = (From t In b.Tasks Where t.ProcessOrder > -1 And t.IsArchived <> True And t.TestStageID = testStageId And t.TestIsArchived <> True Select t.TestName, t.TestID Distinct Order By TestName).ToList()
            ddlTests.DataBind()
        Else
            ddlTests.Items.Clear()
            ddlTests.Items.Add("All")
            ddlTests.DataSource = (From t In b.Tasks Where t.ProcessOrder > -1 And t.IsArchived <> True And t.TestIsArchived <> True Select t.TestName, t.TestID Distinct Order By TestName).ToList()
            ddlTests.DataBind()
        End If
    End Sub

    Protected Sub btnDeleteAllChecked_Click(sender As Object, e As EventArgs)
        Dim exceptionDeleted As Boolean = False
        For Each rowItem As GridViewRow In gvwTestExceptions.Rows
            Dim ExceptionID As Integer = 0
            Dim processDelete As Boolean = True

            If (gvwTestExceptions.PageCount > 1) Then
                If (gvwTestExceptions.DataKeys().Count = rowItem.RowIndex) Then
                    processDelete = False
                End If
            End If

            If (processDelete) Then
                ExceptionID = IIf(CType(rowItem.Cells(0).FindControl("chk1"), CheckBox).Checked, CInt(gvwTestExceptions.DataKeys(rowItem.RowIndex).Value.ToString()), 0)
            End If

            If (ExceptionID > 0) Then
                exceptionDeleted = True
                ExceptionManager.DeleteException(ExceptionID)
            End If
        Next
        If exceptionDeleted Then
            gvwTestExceptions.DataBind()
        End If
    End Sub

    Protected Sub gvwTestExceptions_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs) Handles gvwTestExceptions.RowCommand
        Dim ID As Integer
        Integer.TryParse(e.CommandArgument, ID)
        Select Case e.CommandName.ToLower()
            Case "deleteitem"
                notMain.Notifications.Add(ExceptionManager.DeleteException(ID))
                gvwTestExceptions.DataBind()
        End Select
    End Sub
End Class