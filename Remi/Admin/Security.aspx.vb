Imports Remi.Bll
Imports Remi.Validation
Imports Remi.BusinessEntities
Imports Remi.Contracts

Public Class Security
    Inherits System.Web.UI.Page

#Region "Page Load"
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not (Page.IsPostBack) Then
            If Not UserManager.GetCurrentUser.IsAdmin Then
                Response.Redirect("~/")
            End If

            BindServices()
            ddlDepartments.DataSource = LookupsManager.GetLookups("Department", 0, 0, 1)
            ddlDepartments.DataBind()
        End If

        gvwSecurity.DataSource = SecurityManager.GetRolesPermissionsGrid()
        gvwSecurity.DataBind()

        BindServicesAccess(ddlDepartments.SelectedItem.Value)
    End Sub
#End Region

#Region "PreRender"
    Protected Sub SetGvwHeader() Handles gvwSecurity.PreRender
        Helpers.MakeAccessable(gvwSecurity)
    End Sub

    Protected Sub SetServicesHeader() Handles grdServices.PreRender
        Helpers.MakeAccessable(grdServices)
    End Sub

    Protected Sub SetServiceAccessHeader() Handles grdServiceAccess.PreRender
        Helpers.MakeAccessable(grdServiceAccess)
    End Sub
#End Region

#Region "Roles/Permissions"
    Protected Sub btnAddRole_OnClick(ByVal sender As Object, ByVal e As System.EventArgs)
        Dim roleName As String = Request.Form(gvwSecurity.FooterRow.FindControl("txtNewRole").UniqueID)
        Dim permissionID As String = Request.Form(gvwSecurity.FooterRow.FindControl("ddlPermission").UniqueID)

        Dim isSaved As Boolean = SecurityManager.AddNewRole(roleName, permissionID)

        If (isSaved) Then
            notMain.Notifications.Add(New Notification("i2", NotificationType.Information, "The New Role Was Inserted Successfully"))
        Else
            notMain.Notifications.Add(New Notification("e1", NotificationType.Warning, "The New Role Was Not Inserted Successfully"))
        End If

        gvwSecurity.DataSource = SecurityManager.GetRolesPermissionsGrid()
        gvwSecurity.DataBind()
    End Sub

    Protected Sub gvwSecurity_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwSecurity.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            e.Row().Cells(0).CssClass = "removeStyle"

            For i As Integer = 1 To e.Row().Cells.Count - 1
                Dim chk As New CheckBox()
                If (e.Row().Cells(i).Text = "1") Then
                    chk.Checked = True
                End If
                chk.InputAttributes.Add("onclick", "EnableDisablePermission_Click('" & e.Row().Cells(0).Text & "', '" & gvwSecurity.HeaderRow.Cells(i).Text & "');")

                e.Row().Cells(i).Controls.Add(chk)
            Next
        ElseIf e.Row.RowType = DataControlRowType.Footer Then
            Dim txt As New TextBox()
            Dim btn As New Button()
            Dim lbl As New Label()
            Dim ddl As New DropDownList()
            btn.ID = "btnAddRole"
            btn.Text = "Add Role"
            txt.ID = "txtNewRole"
            lbl.ID = "lblRole"
            lbl.Text = "New Role: "
            ddl.ID = "ddlPermission"
            ddl.DataValueField = "PermissionID"
            ddl.DataTextField = "Permission"
            ddl.DataSource = SecurityManager.GetPermissions()
            ddl.DataBind()

            AddHandler btn.Click, AddressOf btnAddRole_OnClick

            e.Row().Cells(0).Controls.Add(lbl)
            e.Row().Cells(0).Controls.Add(txt)
            e.Row().Cells(1).Controls.Add(ddl)
            e.Row().Cells(2).Controls.Add(btn)
        End If
    End Sub

    <System.Web.Services.WebMethod()> _
    Public Shared Function AddRemovePermission(ByVal permission As String, ByVal role As String) As Boolean
        Dim success As Boolean = SecurityManager.AddRemovePermission(permission, role)

        If (success) Then
            REMIAppCache.RemovePermission(permission)
        End If

        Return success
    End Function
#End Region

#Region "Services"
    Protected Sub grdServices_OnRowEditing(ByVal sender As Object, ByVal e As GridViewEditEventArgs)
        grdServices.EditIndex = e.NewEditIndex
        BindServices()

        Dim lblServiceName As Label = grdServices.Rows(e.NewEditIndex).FindControl("lblServiceName")
        Dim txtServiceName As TextBox = grdServices.Rows(e.NewEditIndex).FindControl("txtServiceName")
        Dim chkActive As CheckBox = grdServices.Rows(e.NewEditIndex).FindControl("chkActive")

        chkActive.Enabled = True
        lblServiceName.Visible = False
        txtServiceName.Visible = True
    End Sub

    Protected Sub grdServices_OnRowCancelingEdit(ByVal sender As Object, ByVal e As GridViewCancelEditEventArgs)
        grdServices.EditIndex = -1
        BindServices()
    End Sub

    Protected Sub btnAddService_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim serviceName As String = Request.Form(grdServices.FooterRow.FindControl("txtServiceName").UniqueID)

        Dim isSaved As Boolean = SecurityManager.AddNewService(serviceName)

        If (isSaved) Then
            notMain.Notifications.Add(New Notification("i2", NotificationType.Information, "The Service Was Inserted Successfully"))
        Else
            notMain.Notifications.Add(New Notification("e1", NotificationType.Warning, "The Service Was Not Inserted Successfully"))
        End If

        BindServices()
    End Sub

    Protected Sub btnAddServiceAccess_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim serviceID As Int32
        Dim departmentID As Int32
        Int32.TryParse(Request.Form(grdServiceAccess.FooterRow.FindControl("ddlServiceOptions").UniqueID), serviceID)
        Int32.TryParse(ddlDepartments.SelectedItem.Value.ToString(), departmentID)

        Dim isSaved As Boolean = SecurityManager.AddServiceAccess(departmentID, serviceID)

        If (isSaved) Then
            notMain.Notifications.Add(New Notification("i2", NotificationType.Information, "The Service Access Was Inserted Successfully"))
        Else
            notMain.Notifications.Add(New Notification("e1", NotificationType.Warning, "The Service Access Was Not Inserted Successfully"))
        End If

        BindServicesAccess(departmentID)
        REMIAppCache.RemoveServiceAccess(departmentID)
        REMIAppCache.SetServiceAccess(departmentID, SecurityManager.GetServicesAccess(departmentID))
    End Sub

    Protected Sub grdServices_RowUpdating(ByVal sender As Object, ByVal e As GridViewUpdateEventArgs)
        Dim lblServiceName As Label = grdServices.Rows(e.RowIndex).FindControl("lblServiceName")
        Dim txtServiceName As TextBox = grdServices.Rows(e.RowIndex).FindControl("txtServiceName")
        Dim chkActive As CheckBox = grdServices.Rows(e.RowIndex).FindControl("chkActive")
        Dim active As Int32 = 1
        Dim serviceID As Int32 = 0
        Int32.TryParse(grdServices.DataKeys(e.RowIndex).Values(0), serviceID)

        If (Not Request.Form(chkActive.UniqueID) = "on") Then
            active = 0
        End If

        Dim isSaved As Boolean = SecurityManager.EditService(serviceID, txtServiceName.Text, active)

        If (isSaved) Then
            notMain.Notifications.Add(New Notification("i2", NotificationType.Information, "The Service Was Updated Successfully"))
        Else
            notMain.Notifications.Add(New Notification("e1", NotificationType.Warning, "The Service Was Not Updated Successfully"))
        End If

        grdServices.EditIndex = -1
        BindServices()
    End Sub

    Protected Sub BindServices()
        grdServices.DataSource = SecurityManager.GetServices()
        grdServices.DataBind()
    End Sub

    Protected Sub BindServicesAccess(ByVal departmentID As Int32)
        grdServiceAccess.DataSource = SecurityManager.GetServicesAccess(departmentID)
        grdServiceAccess.DataBind()
    End Sub

    Protected Sub grdServiceAccess_RowDeleting(sender As Object, e As GridViewDeleteEventArgs)
        Dim departmentID As Int32
        Dim serviceAccessID As Int32
        Int32.TryParse(ddlDepartments.SelectedItem.Value, departmentID)
        Int32.TryParse(grdServiceAccess.DataKeys(e.RowIndex).Values(1), serviceAccessID)

        Dim isSaved As Boolean = SecurityManager.DeleteServiceAccess(serviceAccessID)

        If (isSaved) Then
            notMain.Notifications.Add(New Notification("i2", NotificationType.Information, "The Service Access Was Deleted Successfully"))
        Else
            notMain.Notifications.Add(New Notification("e1", NotificationType.Warning, "The Service Access Was Not Deleted Successfully"))
        End If

        BindServicesAccess(departmentID)
        REMIAppCache.RemoveServiceAccess(ddlDepartments.SelectedItem.Value)
        REMIAppCache.SetServiceAccess(ddlDepartments.SelectedItem.Value, SecurityManager.GetServicesAccess(departmentID))
    End Sub
#End Region
End Class