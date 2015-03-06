﻿Imports Remi.BusinessEntities
Imports Remi.Bll
Imports Remi.Contracts

Partial Class Admin_Users
    Inherits System.Web.UI.Page
    Dim level As DataTable = LookupsManager.GetLookups("Level", 0, 0, String.Empty, String.Empty, 0, False, 0, False)

    Protected Sub Page_Load() Handles Me.Load
        If Not Page.IsPostBack AndAlso Not UserManager.GetCurrentUser.IsAdmin And Not UserManager.GetCurrentUser.IsTestCenterAdmin Then
            Response.Redirect("~/")
        End If

        If Not Page.IsPostBack Then
            If (Request.QueryString IsNot Nothing AndAlso Not String.IsNullOrEmpty(Request.QueryString.Get("userid"))) Then
                SetupPageAddEditUser(UserManager.GetUser(String.Empty, Request.QueryString.Get("userid")))
            End If
        End If

        If (UserManager.GetCurrentUser.IsTestCenterAdmin And Not (UserManager.GetCurrentUser.IsAdmin)) Then
            Hyperlink1.Enabled = False
            Hyperlink4.Enabled = False
            ddlTestCenters.Enabled = False

            If (Not UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                Hyperlink2.Enabled = False
                HyperLink5.Enabled = False
                Hyperlink7.Enabled = False
                Hyperlink8.Enabled = False
                HyperLink9.Enabled = False
            End If
        End If
    End Sub

    Protected Sub UpdateGvwHeader() Handles gvwUsers.PreRender
        Helpers.MakeAccessable(gvwUsers)
    End Sub

    Protected Sub TestCenterHeader() Handles grdTestCenter.PreRender
        Helpers.MakeAccessable(grdTestCenter)
    End Sub

    Protected Sub DeaprtmentHeader() Handles grdDepartments.PreRender
        Helpers.MakeAccessable(grdDepartments)
    End Sub

    Protected Sub UpdatePermissionsGvw() Handles gvwPermissions.PreRender
        Helpers.MakeAccessable(gvwPermissions)
    End Sub

    Protected Sub gvRequestTypes_PreRender() Handles gvRequestTypes.PreRender
        Helpers.MakeAccessable(gvRequestTypes)
    End Sub

    Protected Sub UpdateTrainingGvw() Handles gvwTraining.PreRender
        Helpers.MakeAccessable(gvwTraining)
    End Sub

    Protected Sub Page_PreRender() Handles Me.PreRender
        If Not Page.IsPostBack Then
            ddlTestCenters.DataBind()

            Dim l As ListItem = New ListItem(UserManager.GetCurrentUser.TestCentre, UserManager.GetCurrentUser.TestCentreID)
            If (ddlTestCenters.Items.Contains(l)) Then
                ddlTestCenters.SelectedValue = UserManager.GetCurrentUser.TestCentreID
            End If
        End If

        Dim testCenterID As Int32 = 0
        Int32.TryParse(ddlTestCenters.SelectedValue, testCenterID)

        Dim us As New UserSearch
        us.TestCenterID = testCenterID
        gvwUsers.DataSource = UserManager.UserSearchList(us, False, True, True, True, True, chkArchived.Checked)
        gvwUsers.DataBind()
    End Sub

    Protected Sub SetupPageViewAll()
        pnlAddNewUser.Visible = False
        pnlViewAllUsers.Visible = True
        pnlLeftMenuActions.Visible = False
        lblHeaderText.Text = "View All Users"

        Dim testCenterID As Int32 = 0
        Int32.TryParse(ddlTestCenters.SelectedValue, testCenterID)

        Dim us As New UserSearch
        us.TestCenterID = testCenterID
        gvwUsers.DataSource = UserManager.UserSearchList(us, False, True, True, True, True, chkArchived.Checked)
        gvwUsers.DataBind()

    End Sub

    Protected Sub SetupPageAddEditUser(ByVal CurrentUser As User)
        pnlAddNewUser.Visible = True
        pnlViewAllUsers.Visible = False
        pnlLeftMenuActions.Visible = True

        ddlDefaultPage.DataSource = SecurityManager.GetMenuAccessByDepartment(String.Empty, UserManager.GetCurrentUser.DepartmentID, True)
        ddlDefaultPage.DataBind()

        If CurrentUser Is Nothing Then
            lblHeaderText.Text = "Add New User"
            txtName.Visible = True
            lblUserName.Visible = False
            txtName.Text = String.Empty
            txtBadgeNumber.Text = String.Empty
            hdnUserName.Value = String.Empty
            hdnUserID.Value = -1
            chkIsActive.Checked = True
            chkByPassProduct.Checked = False
            chkWA.Checked = True
            grdTestCenter.DataSource = LookupsManager.GetLookups("TestCenter", 0, 0, String.Empty, String.Empty, 0, False, 1, False)
            grdTestCenter.DataBind()

            grdDepartments.DataSource = LookupsManager.GetLookups("Department", 0, 0, String.Empty, String.Empty, 0, False, 1, False)
            grdDepartments.DataBind()
        Else
            lblHeaderText.Text = String.Format("Editing {0}", CurrentUser.LDAPName)
            txtName.Visible = False
            lblUserName.Visible = True
            lblUserName.Text = CurrentUser.LDAPName
            chkWA.Checked = True
            txtBadgeNumber.Text = CurrentUser.BadgeNumber
            If (CurrentUser.IsActive = 1) Then
                chkIsActive.Checked = True
            Else
                chkIsActive.Checked = False
            End If

            If (CurrentUser.ByPassProduct = 1) Then
                chkByPassProduct.Checked = True
            Else
                chkByPassProduct.Checked = False
            End If

            Dim sl As ListItem = New ListItem
            sl = ddlDefaultPage.Items.FindByValue(CurrentUser.DefaultPage.ToString())

            If ddlDefaultPage.Items.Contains(sl) Then
                ddlDefaultPage.SelectedValue = sl.Value
            End If

            hdnUserName.Value = CurrentUser.LDAPName
            hdnUserID.Value = CurrentUser.ID

            gvRequestTypes.DataSource = CurrentUser.RequestTypes()
            gvRequestTypes.DataBind()

            grdTestCenter.DataSource = LookupsManager.GetLookups("TestCenter", 0, 0, String.Empty, String.Empty, 0, False, 1, False)
            grdTestCenter.DataBind()

            grdDepartments.DataSource = LookupsManager.GetLookups("Department", 0, 0, String.Empty, String.Empty, 0, False, 1, False)
            grdDepartments.DataBind()

            For Each drtc As GridViewRow In grdTestCenter.Rows
                Dim chkAccess As CheckBox = drtc.FindControl("chkAccess")
                Dim chkDefault As CheckBox = drtc.FindControl("chkDefault")
                Dim hdnLookupID As HiddenField = drtc.FindControl("hdnLookupID")

                Dim dr As DataRow = (From ud As DataRow In CurrentUser.UserDetails.Rows Where ud.Field(Of Int32)("LookupID") = hdnLookupID.Value Select ud).FirstOrDefault()

                If (dr IsNot Nothing) Then
                    chkDefault.Checked = dr.Field(Of Boolean)("IsDefault")
                    chkAccess.Checked = True
                End If
            Next

            For Each drtc As GridViewRow In grdDepartments.Rows
                Dim chkAccess As CheckBox = drtc.FindControl("chkAccess")
                Dim chkDefault As CheckBox = drtc.FindControl("chkDefault")
                Dim hdnLookupID As HiddenField = drtc.FindControl("hdnLookupID")

                Dim dr As DataRow = (From ud As DataRow In CurrentUser.UserDetails.Rows Where ud.Field(Of Int32)("LookupID") = hdnLookupID.Value Select ud).FirstOrDefault()

                If (dr IsNot Nothing) Then
                    chkDefault.Checked = dr.Field(Of Boolean)("IsDefault")
                    chkAccess.Checked = True
                End If
            Next

            dlstProductGroups.DataBind()
            gvwTraining.DataBind()

            For Each dr As DataRow In CurrentUser.ProductGroups.Rows
                For Each dli As DataListItem In dlstProductGroups.Items
                    Dim chkProductGroup As CheckBox = dli.FindControl("chkProductGroup")
                    If chkProductGroup.Text = dr.Item("ProductGroupName").ToString() Then
                        chkProductGroup.Checked = True
                    End If
                Next
            Next
            Dim testCenterAdmin As Boolean = UserManager.GetCurrentUser.IsTestCenterAdmin

            'recheck appropriate roles.
            For Each r As String In CurrentUser.RolesList
                For Each dli As DataListItem In dlstRoles.Items
                    Dim chkRole As CheckBox = dli.FindControl("chkRole")

                    If (chkRole.Text = "Administrator" And testCenterAdmin) Then
                        chkRole.Style.Add("Display", "None")
                    End If

                    If chkRole.Text = r Then
                        chkRole.Checked = True
                    End If
                Next
            Next
        End If
    End Sub

    Protected Sub gvwUsers_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwUsers.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim btnTraining As Image = DirectCast(e.Row.FindControl("btnTraining"), Image)
            Dim pnlTraining As Panel = DirectCast(e.Row.FindControl("pnlTraining"), Panel)
            Dim blTraining As BulletedList = DirectCast(e.Row.FindControl("blTraining"), BulletedList)

            If (blTraining.Items.Count = 0) Then
                btnTraining.CssClass = "hidden"
            End If

            btnTraining.Attributes.Add("onclick", "javascript: gvrowtoggle(" & e.Row.RowIndex & ", '" & pnlTraining.ClientID & "')")
        End If
    End Sub

    Protected Sub gvwUsers_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs)
        Select Case e.CommandName.ToLower()
            Case "editrow"
                SetupPageAddEditUser(UserManager.GetUser(String.Empty, e.CommandArgument.ToString))
                Exit Select
            Case "deleteitem"
                Dim currentUser As String = UserManager.GetCurrentValidUserLDAPName
                Dim userID As Int32 = (From u In New REMI.Dal.Entities().Instance().Users Where u.LDAPLogin = currentUser Select u.ID).FirstOrDefault()
                notMain.Notifications.Add(UserManager.Delete(e.CommandArgument, userID))
                SetupPageViewAll()
        End Select
    End Sub

    Protected Sub lnkAddUserAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddUserAction.Click
        Dim tmpUser As User
        If Not String.IsNullOrEmpty(hdnUserName.Value) Then
            tmpUser = UserManager.GetUser(hdnUserName.Value, 0)
        Else
            tmpUser = New User
            tmpUser.LDAPName = txtName.Text
        End If

        Int32.TryParse(Request.Form(txtBadgeNumber.UniqueID).Trim, tmpUser.BadgeNumber)

        If (Request.Form(chkIsActive.UniqueID) = "on") Then
            tmpUser.IsActive = 1
        Else
            tmpUser.IsActive = 0
        End If

        If (Request.Form(chkByPassProduct.UniqueID) = "on") Then
            tmpUser.ByPassProduct = 1
        Else
            tmpUser.ByPassProduct = 0
        End If

        'Projects
        Dim userProjects As New DataTable("ProductGroups")
        userProjects.Columns.Add("ID", Type.GetType("System.Int32"))
        userProjects.Columns.Add("ProductGroupName", Type.GetType("System.String"))

        Dim products As DataList = DirectCast(Me.FindControl(dlstProductGroups.UniqueID), DataList)

        For Each dli As DataListItem In products.Items
            If (dli.ItemType = ListItemType.Item Or dli.ItemType = ListItemType.AlternatingItem) Then

                Dim chkProductGroup As CheckBox = dli.FindControl("chkProductGroup")
                Dim hdnProductID As HiddenField = dli.FindControl("hdnProductID")

                If Request.Form(chkProductGroup.UniqueID) = "on" Then
                    Dim newRow As DataRow = userProjects.NewRow
                    newRow("ID") = hdnProductID.Value
                    newRow("ProductGroupName") = chkProductGroup.Text
                    userProjects.Rows.Add(newRow)
                End If
            End If

        Next

        Dim roles As DataList = DirectCast(Me.FindControl(dlstRoles.UniqueID), DataList)
        Dim userRoles As New List(Of String)

        For Each dli As DataListItem In roles.Items
            If (dli.ItemType = ListItemType.Item Or dli.ItemType = ListItemType.AlternatingItem) Then
                Dim chkRole As CheckBox = dli.FindControl("chkRole")

                If Request.Form(chkRole.UniqueID) = "on" Then
                    userRoles.Add(chkRole.Text)
                End If
            End If
        Next

        Dim training As GridView = DirectCast(Me.FindControl(gvwTraining.UniqueID), GridView)
        Dim userTraining As New DataTable("Training")
        userTraining.Columns.Add("UserID", Type.GetType("System.Int32"))
        userTraining.Columns.Add("DateAdded", Type.GetType("System.DateTime"))
        userTraining.Columns.Add("LookupID", Type.GetType("System.Int32"))
        userTraining.Columns.Add("TrainingOption", Type.GetType("System.String"))
        userTraining.Columns.Add("IsTrained", Type.GetType("System.Boolean"))
        userTraining.Columns.Add("LevelLookupID", Type.GetType("System.Int32"))
        userTraining.Columns.Add("Level", Type.GetType("System.String"))
        userTraining.Columns.Add("ID", Type.GetType("System.Int32"))
        userTraining.Columns.Add("UserAssigned", Type.GetType("System.String"))

        For Each gvr As GridViewRow In training.Rows
            Dim chkTraining As CheckBox = gvr.FindControl("chkTraining")
            Dim ddlTrainingLevel As DropDownList = gvr.FindControl("ddlTrainingLevel")
            Dim hdnLookupID As HiddenField = gvr.FindControl("hdnLookupID")
            Dim hdnDateAdded As HiddenField = gvr.FindControl("hdnDateAdded")
            Dim pnlTraining As Panel = gvr.FindControl("pnlTraining")
            Dim lblAddedBy As Label = gvr.FindControl("lblAddedBy")

            If chkTraining.Checked Then
                Dim newRow As DataRow = userTraining.NewRow
                newRow("UserID") = hdnUserID.Value
                If (pnlTraining.Enabled = True) Then
                    newRow("DateAdded") = DateTime.UtcNow
                Else
                    newRow("DateAdded") = hdnDateAdded.Value
                End If
                newRow("IsTrained") = True
                newRow("LookupID") = hdnLookupID.Value
                newRow("TrainingOption") = chkTraining.Text
                newRow("LevelLookupID") = ddlTrainingLevel.SelectedValue
                newRow("Level") = ddlTrainingLevel.SelectedItem.Text
                newRow("ID") = If(DirectCast(gvr.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(gvr.RowIndex).Values(1).ToString() = String.Empty, 0, CType(DirectCast(gvr.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(gvr.RowIndex).Values(1).ToString(), Int32))

                If (pnlTraining.Enabled) Then
                    newRow("UserAssigned") = UserManager.GetCurrentUser.UserName
                Else
                    newRow("UserAssigned") = lblAddedBy.Text
                End If

                userTraining.Rows.Add(newRow)
            End If
        Next

        'create an updated list from the gui
        Dim permissionList As New TrackingLocationTypePermissionCollection(hdnUserName.Value)
        Dim singlePermission As TrackingLocationTypePermission
        Dim permissions As GridView = DirectCast(Me.FindControl(gvwPermissions.UniqueID), GridView)

        For Each permissionTableRow As GridViewRow In permissions.Rows
            If permissionTableRow.RowType = DataControlRowType.DataRow Then
                singlePermission = New TrackingLocationTypePermission
                'for each of the security options, if the checkbox is checked then set the mask 
                'for the appropriate security mask.
                singlePermission.HasBasicAccess = DirectCast(permissionTableRow.FindControl("chkHasBasicAccess"), CheckBox).Checked
                singlePermission.HasModifiedAccess = DirectCast(permissionTableRow.FindControl("chkHasModifiedAccess"), CheckBox).Checked
                singlePermission.HasCalibrationAccess = DirectCast(permissionTableRow.FindControl("chkHasCalibrationAccess"), CheckBox).Checked


                singlePermission.TrackingLocationTypeID = gvwPermissions.DataKeys(permissionTableRow.RowIndex).Value

                'finally add the single permission to the collection
                permissionList.Add(singlePermission)
            End If
        Next
        'save the list.
        TrackingLocationManager.SaveUserPermissions(permissionList)

        'set up the user data
        tmpUser.RolesList = userRoles
        tmpUser.ProductGroups = userProjects
        tmpUser.Training = userTraining
        tmpUser.DefaultPage = Request.Form(ddlDefaultPage.UniqueID)

        Dim defaultIsSet As Boolean = False
        Dim userDetails As New DataTable("UserDetails")
        userDetails.Columns.Add("Name", Type.GetType("System.String"))
        userDetails.Columns.Add("Values", Type.GetType("System.String"))
        userDetails.Columns.Add("LookupID", Type.GetType("System.Int32"))
        userDetails.Columns.Add("IsDefault", Type.GetType("System.Boolean"))

        For Each drtc As GridViewRow In grdDepartments.Rows
            Dim chkAccess As CheckBox = drtc.FindControl("chkAccess")
            Dim chkDefault As CheckBox = drtc.FindControl("chkDefault")
            Dim hdnLookupID As HiddenField = drtc.FindControl("hdnLookupID")
            Dim lblName As Label = drtc.FindControl("lblName")

            If (chkAccess.Checked) Then
                Dim newRow As DataRow = userDetails.NewRow
                newRow("LookupID") = hdnLookupID.Value
                newRow("Values") = lblName.Text
                newRow("Name") = "Department"

                If (chkDefault.Checked And Not defaultIsSet) Then
                    defaultIsSet = True
                    newRow("IsDefault") = chkDefault.Checked
                Else
                    newRow("IsDefault") = False
                End If

                userDetails.Rows.Add(newRow)
            End If
        Next

        defaultIsSet = False

        For Each drtc As GridViewRow In grdTestCenter.Rows
            Dim chkAccess As CheckBox = drtc.FindControl("chkAccess")
            Dim chkDefault As CheckBox = drtc.FindControl("chkDefault")
            Dim hdnLookupID As HiddenField = drtc.FindControl("hdnLookupID")
            Dim lblName As Label = drtc.FindControl("lblName")

            If (chkAccess.Checked) Then
                Dim newRow As DataRow = userDetails.NewRow
                newRow("LookupID") = hdnLookupID.Value
                newRow("Values") = lblName.Text
                newRow("Name") = "TestCenter"

                If (chkDefault.Checked And Not defaultIsSet) Then
                    defaultIsSet = True
                    newRow("IsDefault") = chkDefault.Checked
                Else
                    newRow("IsDefault") = False
                End If

                userDetails.Rows.Add(newRow)
            End If
        Next

        tmpUser.UserDetails = userDetails

        Dim requestAccess As GridView = DirectCast(Me.FindControl(gvRequestTypes.UniqueID), GridView)
        Dim dtRequestAccess As New DataTable("RequestTypes")
        dtRequestAccess.Columns.Add("RequestType", Type.GetType("System.String"))
        dtRequestAccess.Columns.Add("Department", Type.GetType("System.String"))
        dtRequestAccess.Columns.Add("IsActive", Type.GetType("System.Boolean"))
        dtRequestAccess.Columns.Add("HasIntegration", Type.GetType("System.Boolean"))
        dtRequestAccess.Columns.Add("RequestTypeID", Type.GetType("System.Int32"))
        dtRequestAccess.Columns.Add("IsAdmin", Type.GetType("System.Boolean"))
        dtRequestAccess.Columns.Add("UserDetailsID", Type.GetType("System.Int32"))
        dtRequestAccess.Columns.Add("IsExternal", Type.GetType("System.Boolean"))
        dtRequestAccess.Columns.Add("TypeID", Type.GetType("System.Int32"))

        For Each row As GridViewRow In requestAccess.Rows
            If (row.RowType = DataControlRowType.DataRow) Then
                Dim userDetailsID As Int32 = requestAccess.DataKeys(row.RowIndex).Values(0)
                Dim RequestTypeAccessID As Int32 = requestAccess.DataKeys(row.RowIndex).Values(2)
                Dim typeID As Int32 = requestAccess.DataKeys(row.RowIndex).Values(1)
                Dim chkIsAdmin As CheckBox = row.FindControl("chkIsAdmin")

                Dim rec As DataRow = tmpUser.RequestTypes.Select(String.Format("RequestTypeAccessID={0}", RequestTypeAccessID))(0)

                Dim newRow As DataRow = dtRequestAccess.NewRow
                newRow("RequestType") = rec("RequestType")
                newRow("Department") = rec("Department")
                newRow("IsActive") = rec("IsActive")
                newRow("HasIntegration") = rec("HasIntegration")
                newRow("RequestTypeID") = rec("RequestTypeID")
                newRow("IsAdmin") = chkIsAdmin.Checked
                newRow("UserDetailsID") = rec("UserDetailsID")
                newRow("IsExternal") = rec("IsExternal")
                newRow("TypeID") = rec("TypeID")

                dtRequestAccess.Rows.Add(newRow)
            End If
        Next

        tmpUser.RequestTypes = dtRequestAccess

        UserManager.Save(tmpUser, True, True, If(Request.Form(chkWA.UniqueID) = "on", True, False))
        notMain.Notifications.Add(tmpUser.Notifications)

        If Not notMain.HasErrors Then
            If (Request.QueryString IsNot Nothing AndAlso Not String.IsNullOrEmpty(Request.QueryString.Get("userid"))) Then
                SetupPageAddEditUser(UserManager.GetUser(String.Empty, Request.QueryString.Get("userid")))
            Else
                SetupPageViewAll()
            End If
        End If
    End Sub

    Protected Sub lnkCancelAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkCancelAction.Click
        SetupPageViewAll()
    End Sub

    Protected Sub lnkViewAllUsers_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkViewAllUsers.Click
        SetupPageViewAll()
    End Sub

    Protected Sub lnkAddNewUser_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddNewUser.Click
        SetupPageAddEditUser(Nothing)
    End Sub

    Protected Sub gvwTraining_RowDataBound(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.GridViewRowEventArgs) Handles gvwTraining.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim ddlTrainingLevel As DropDownList = DirectCast(e.Row.FindControl("ddlTrainingLevel"), DropDownList)
            Dim lblAddedBy As Label = DirectCast(e.Row.FindControl("lblAddedBy"), Label)
            Dim chkTraining As CheckBox = DirectCast(e.Row.FindControl("chkTraining"), CheckBox)

            If (chkTraining.Checked) Then
                ddlTrainingLevel.Enabled = True
            Else
                ddlTrainingLevel.Enabled = False
            End If

            chkTraining.InputAttributes.Add("onclick", "EnableDisableCheckbox_Click('" & ddlTrainingLevel.ClientID & "', '" & chkTraining.ClientID & "', '" & UserManager.GetCurrentUser.UserName & "', '" & lblAddedBy.ClientID & "');")

            ddlTrainingLevel.DataTextField = "LookupType"
            ddlTrainingLevel.DataValueField = "LookupID"
            ddlTrainingLevel.DataSource = level
            ddlTrainingLevel.DataBind()
            ddlTrainingLevel.SelectedValue = DirectCast(e.Row.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(e.Row.RowIndex).Values(0).ToString()
        End If
    End Sub

    Protected Sub gvwUsers_RowCreated(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.GridViewRowEventArgs) Handles gvwUsers.RowCreated
        If e.Row.RowType = DataControlRowType.DataRow Then
            If (DataBinder.Eval(e.Row.DataItem, "IsActive") IsNot Nothing) Then
                If (DataBinder.Eval(e.Row.DataItem, "IsActive").ToString() = 0) Then
                    e.Row.BackColor = Drawing.Color.Yellow
                End If
            End If
        End If
    End Sub
End Class