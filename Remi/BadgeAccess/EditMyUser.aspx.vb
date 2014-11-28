Imports REMI.Bll
Imports REMI.BusinessEntities

Partial Class BadgeAccess_EditMyUser
    Inherits System.Web.UI.Page

    Protected Sub ddlDefaultPage_Databound(ByVal sender As Object, ByVal e As EventArgs) Handles ddlDefaultPage.DataBound
        ddlDefaultPage.SelectedValue = UserManager.GetCurrentUser.DefaultPage
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If (Not Page.IsPostBack) Then
            ddlDefaultPage.DataSource = SecurityManager.GetMenuAccessByDepartment(String.Empty, UserManager.GetCurrentUser.DepartmentID)
            ddlDefaultPage.DataBind()

            ddlTraining.Items.Clear()
            ddlTraining.Items.Add("Select")
            ddlTraining.DataSource = (From t In UserManager.GetCurrentUser.Training Where t.Field(Of String)("Level") = "Trainer" Select New With {.TrainingOption = t.Field(Of String)("TrainingOption"), .LookupID = t.Field(Of Int32)("LookupID")})
            ddlTraining.DataBind()
        End If

        Dim username As String = UserManager.GetCurrentUser.LDAPName
        Dim sl As ListItem = New ListItem

        sl = ddlDefaultPage.Items.FindByValue(UserManager.GetCurrentUser.DefaultPage.ToString())

        If ddlDefaultPage.Items.Contains(sl) Then
            ddlDefaultPage.SelectedValue = sl.Value
        End If

        hdnUserID.Value = UserManager.GetCurrentValidUserID

        For Each dr As DataRow In UserManager.GetCurrentUser.UserDetails.Rows
            For Each dli As DataListItem In dlstTestCenter.Items
                Dim chkTestCenter As CheckBox = dli.FindControl("chkTestCenter")
                Dim hdnTCIsDefault As HiddenField = dli.FindControl("hdnTCIsDefault")

                hdnTCIsDefault.Value = dr.Item("IsDefault").ToString()

                If chkTestCenter.Text = dr.Item("Values").ToString() Then
                    chkTestCenter.Checked = True
                    chkTestCenter.Enabled = False

                    If (hdnTCIsDefault.Value = "True") Then
                        chkTestCenter.Style.Add("font-weight", "bold")
                    End If
                End If
            Next

            For Each dli As DataListItem In dlstDepartments.Items
                Dim chkDepartment As CheckBox = dli.FindControl("chkDepartment")
                Dim hdnDIsDefault As HiddenField = dli.FindControl("hdnDIsDefault")

                hdnDIsDefault.Value = dr.Item("IsDefault").ToString()

                If chkDepartment.Text = dr.Item("Values").ToString() Then
                    chkDepartment.Checked = True
                    chkDepartment.Enabled = False

                    If (hdnDIsDefault.Value = "True") Then
                        chkDepartment.Style.Add("font-weight", "bold")
                    End If
                End If
            Next
        Next
    End Sub

    Protected Sub ddlTraining_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTraining.SelectedIndexChanged
        If (ddlTraining.SelectedItem.Value = "Select") Then
            gvwTrainingLevels.DataSource = Nothing
            gvwTrainingLevels.DataBind()
        Else
            gvwTrainingLevels.DataSource = UserManager.GetSimiliarTraining(ddlTraining.SelectedItem.Value)
            gvwTrainingLevels.DataBind()
        End If
    End Sub

    Protected Sub gvwTrainingLevels_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwTrainingLevels.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim ddlLevel As DropDownList = DirectCast(e.Row.FindControl("ddlLevel"), DropDownList)
            Dim hdnLevel As HiddenField = DirectCast(e.Row.FindControl("hdnLevel"), HiddenField)
            Dim chkModify As CheckBox = DirectCast(e.Row.FindControl("chkModify"), CheckBox)

            ddlLevel.DataSource = LookupsManager.GetLookups("Level", 0, 0, 0)
            ddlLevel.DataBind()

            ddlLevel.SelectedValue = hdnLevel.Value

            chkModify.InputAttributes.Add("onclick", "EnableDisableCheckbox_Click('" & ddlLevel.ClientID & "', '" & chkModify.ClientID & "');")

        End If
    End Sub

    Protected Sub gvwTraining_DataBound(ByVal sender As Object, ByVal e As System.EventArgs) Handles gvwTraining.DataBound
        If (gvwTraining.HeaderRow IsNot Nothing) Then
            Dim notTrained = (From row In gvwTraining.Rows.OfType(Of GridViewRow)() Where row.Cells(1).Text = "0" Select row).FirstOrDefault()

            If (notTrained Is Nothing) Then
                For Each headerCell As TableCell In gvwTraining.HeaderRow.Cells
                    DirectCast(headerCell.FindControl("btnConfirmAll"), Button).CssClass = "hidden"
                    DirectCast(headerCell.FindControl("lblConfirm"), Label).CssClass = ""
                Next
            End If
        End If
    End Sub

    Protected Sub gvwTraining_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwTraining.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim chkTrainingConfirm As CheckBox = DirectCast(e.Row.FindControl("chkTrainingConfirm"), CheckBox)

            If (chkTrainingConfirm.Checked) Then
                chkTrainingConfirm.CssClass = "hidden"
            End If
        End If
    End Sub

    Protected Sub btnSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSave.Click
        UserManager.SetUserToSession(UserManager.GetUser(UserManager.GetCurrentUser.LDAPName, UserManager.GetCurrentUser.ID))
        UserManager.GetCurrentUser.DefaultPage = Request.Form(ddlDefaultPage.UniqueID)

        Dim testCenters As DataList = DirectCast(Me.FindControl(dlstTestCenter.UniqueID), DataList)
        Dim departments As DataList = DirectCast(Me.FindControl(dlstDepartments.UniqueID), DataList)

        Dim userDetails As New DataTable
        userDetails.Columns.Add("Name", Type.GetType("System.String"))
        userDetails.Columns.Add("Values", Type.GetType("System.String"))
        userDetails.Columns.Add("LookupID", Type.GetType("System.Int32"))
        userDetails.Columns.Add("IsDefault", Type.GetType("System.Boolean"))

        For Each dli As DataListItem In testCenters.Items
            If (dli.ItemType = ListItemType.Item Or dli.ItemType = ListItemType.AlternatingItem) Then
                Dim chkTestCenter As CheckBox = dli.FindControl("chkTestCenter")
                Dim hdnTestCenterID As HiddenField = dli.FindControl("hdnTestCenterID")
                Dim hdnTCIsDefault As HiddenField = dli.FindControl("hdnTCIsDefault")

                If Request.Form(chkTestCenter.UniqueID) = "on" Then
                    Dim newRow As DataRow = userDetails.NewRow
                    newRow("LookupID") = hdnTestCenterID.Value
                    newRow("Values") = chkTestCenter.Text
                    newRow("Name") = "TestCenter"
                    newRow("IsDefault") = hdnTCIsDefault.Value
                    userDetails.Rows.Add(newRow)
                End If
            End If
        Next

        For Each dli As DataListItem In departments.Items
            If (dli.ItemType = ListItemType.Item Or dli.ItemType = ListItemType.AlternatingItem) Then
                Dim chkDepartment As CheckBox = dli.FindControl("chkDepartment")
                Dim hdnDepartmentID As HiddenField = dli.FindControl("hdnDepartmentID")
                Dim hdnDIsDefault As HiddenField = dli.FindControl("hdnDIsDefault")

                If Request.Form(chkDepartment.UniqueID) = "on" Then
                    Dim newRow As DataRow = userDetails.NewRow
                    newRow("LookupID") = hdnDepartmentID.Value
                    newRow("Values") = chkDepartment.Text
                    newRow("Name") = "Department"
                    newRow("IsDefault") = hdnDIsDefault.Value
                    userDetails.Rows.Add(newRow)
                End If
            End If
        Next

        UserManager.GetCurrentUser.UserDetails = userDetails

        Dim training As GridView = DirectCast(Me.FindControl(gvwTraining.UniqueID), GridView)
        For Each gvr As GridViewRow In training.Rows
            Dim chkTrainingConfirm As CheckBox = gvr.FindControl("chkTrainingConfirm")
            Dim lblTrainingConfirm As Label = gvr.FindControl("lblTrainingConfirm")
            Dim hdnLevel As HiddenField = gvr.FindControl("hdnLevel")
            Dim id As Int32 = If(DirectCast(gvr.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(gvr.RowIndex).Values(0).ToString() = String.Empty, 0, CType(DirectCast(gvr.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(gvr.RowIndex).Values(0).ToString(), Int32))

            If ((String.IsNullOrEmpty(chkTrainingConfirm.Text) And chkTrainingConfirm.Checked) Or Not (String.IsNullOrEmpty(lblTrainingConfirm.Text))) Then
                UserManager.SaveTrainingConfirmation(hdnUserID.Value, id, hdnLevel.Value, True)
            End If
        Next

        Dim trainingLevel As GridView = DirectCast(Me.FindControl(gvwTrainingLevels.UniqueID), GridView)

        For Each gvr As GridViewRow In trainingLevel.Rows
            Dim chkModify As CheckBox = gvr.FindControl("chkModify")
            Dim ddlLevel As DropDownList = gvr.FindControl("ddlLevel")
            Dim UserID As Int32 = DirectCast(gvr.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(gvr.RowIndex).Values(1).ToString()
            Dim recordID As Int32 = DirectCast(gvr.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(gvr.RowIndex).Values(0).ToString()

            If (chkModify.Checked) Then
                UserManager.SaveTrainingConfirmation(UserID, recordID, ddlLevel.SelectedValue, False)
            End If
        Next

        If UserManager.Save(UserManager.GetCurrentUser, False) > 0 Then
            notMain.Add("Location saved!", Remi.Validation.NotificationType.Information)
            RedirectIfRequested()
        Else
            notMain.Add("Unable to save. Please contact support.", Remi.Validation.NotificationType.Errors)
        End If
    End Sub

    Protected Sub btnConfirmAllChecked_Click(sender As Object, e As EventArgs)
        For Each rowItem As GridViewRow In gvwTraining.Rows
            Dim id As Int32 = 0
            Dim levelID As Int32
            id = CInt(gvwTraining.DataKeys(rowItem.RowIndex).Value.ToString())
            levelID = DirectCast(rowItem.FindControl("hdnLevel"), HiddenField).Value

            If (id > 0) Then
                UserManager.SaveTrainingConfirmation(hdnUserID.Value, id, levelID, True)
            End If
        Next

        gvwTraining.DataBind()
    End Sub

    Protected Sub UpdateGvwHeader() Handles gvwTraining.PreRender
        Helpers.MakeAccessable(gvwTraining)
    End Sub

    Protected Sub UpdategvwTrainingLevelsHeader() Handles gvwTrainingLevels.PreRender
        Helpers.MakeAccessable(gvwTrainingLevels)
    End Sub

    Private Sub RedirectIfRequested()
        If Request.QueryString.Item("RedirectPage") IsNot Nothing Then
            Response.Redirect(Request.QueryString.Get("RedirectPage"), True)
        Else
            Response.Redirect(String.Format("~{0}", UserManager.GetCurrentUser.DefaultPage))
        End If
    End Sub
End Class