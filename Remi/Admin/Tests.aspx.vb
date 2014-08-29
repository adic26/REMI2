Imports REMI.Bll
Imports REMI.Validation
Imports REMI.BusinessEntities

Partial Class Admin_Tests
    Inherits System.Web.UI.Page

    Protected Sub Page_Load() Handles Me.Load
        If Not (Page.IsPostBack) Then
            If Not UserManager.GetCurrentUser.IsAdmin And Not UserManager.GetCurrentUser.HasAdminReadOnlyAuthority Then
                Response.Redirect("~/")
            End If

            If (UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                lnkAddTest.Enabled = False
                lnkAddTestAction.Enabled = False
            End If

            If (UserManager.GetCurrentUser.IsTestCenterAdmin And Not (UserManager.GetCurrentUser.IsAdmin)) Then
                Hyperlink5.Enabled = False
                Hyperlink1.Enabled = False

                If (Not UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                    Hyperlink7.Enabled = False
                    Hyperlink8.Enabled = False
                End If
            End If

            ddlTestType.DataSource = Helpers.GetTestTypes()
            ddlTestType.DataBind()
        End If
    End Sub

    Protected Sub gvMain_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs)
        Select Case e.CommandName.ToLower()
            Case "edit"
                Response.Redirect("~/admin/tests/editdetail.aspx?testid=" + e.CommandArgument)

            Case "deleteitem"
                notMain.Notifications.Add(TestManager.DeleteTest(Convert.ToInt32(e.CommandArgument)))

        End Select
    End Sub

    Protected Sub lnkViewTests_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkViewTests.Click
        notMain.Clear()
    End Sub
    Protected Sub UpdateGvwHeaders() Handles gvMain.PreRender
        Helpers.MakeAccessable(gvMain)
    End Sub

    Protected Sub lnkAddTest_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddTest.Click
        Response.Redirect("~/admin/tests/editdetail.aspx")
    End Sub

    Protected Sub gvMain_RowCreated(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.GridViewRowEventArgs) Handles gvMain.RowCreated
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim archived As Boolean = False

            If (DataBinder.Eval(e.Row.DataItem, "IsArchived") IsNot Nothing) Then
                Boolean.TryParse(DataBinder.Eval(e.Row.DataItem, "IsArchived").ToString(), archived)
            End If

            If (archived) Then
                e.Row.BackColor = Drawing.Color.Yellow
            End If
        End If
    End Sub

    Protected Sub gvMain_DataBound(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvMain.DataBound
        If (ddlTestType.SelectedItem.Value <> "EnvironmentalStress") Then
            If (gvMain.Rows.Count > 0) Then
                gvMain.HeaderRow.Cells(7).Visible = False
                gvMain.HeaderRow.Cells(8).Visible = False

                For i As Int32 = 0 To gvMain.Rows.Count - 1
                    gvMain.Rows(i).Cells(7).Visible = False
                    gvMain.Rows(i).Cells(8).Visible = False
                Next
            End If
        End If
    End Sub
End Class