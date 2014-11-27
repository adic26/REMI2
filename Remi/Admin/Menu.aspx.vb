﻿Imports REMI.Bll
Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Contracts

Public Class Menu
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            ddlDepartments.DataSource = LookupsManager.GetLookups(LookupType.Department, 0, 0, 1)
            ddlDepartments.DataBind()

            MenuBindData()
        End If

        MenuAccessBindData()
    End Sub

    Protected Sub SetGvwHeader() Handles grdMenuAccess.PreRender
        Helpers.MakeAccessable(grdMenuAccess)
    End Sub

    Protected Sub SetMenuGvwHeader() Handles grdMenu.PreRender
        Helpers.MakeAccessable(grdMenu)
    End Sub

    Protected Sub MenuAccessBindData()
        grdMenuAccess.DataSource = SecurityManager.GetMenuAccessByDepartment(String.Empty, ddlDepartments.SelectedItem.Value)
        grdMenuAccess.DataBind()
    End Sub

    Protected Sub MenuBindData()
        grdMenu.DataSource = SecurityManager.GetMenu()
        grdMenu.DataBind()
    End Sub

    Protected Sub grdMenu_OnRowEditing(ByVal sender As Object, ByVal e As GridViewEditEventArgs)
        grdMenu.EditIndex = e.NewEditIndex
        MenuBindData()
        Dim lblName As Label = grdMenu.Rows(e.NewEditIndex).FindControl("lblName")
        Dim txtName As TextBox = grdMenu.Rows(e.NewEditIndex).FindControl("txtName")
        Dim lblUrl As Label = grdMenu.Rows(e.NewEditIndex).FindControl("lblUrl")
        Dim txtUrl As TextBox = grdMenu.Rows(e.NewEditIndex).FindControl("txtUrl")

        lblName.Visible = False
        lblUrl.Visible = False
        txtName.Visible = True
        txtUrl.Visible = True
    End Sub

    Protected Sub grdMenu_OnRowCancelingEdit(ByVal sender As Object, ByVal e As GridViewCancelEditEventArgs)
        grdMenu.EditIndex = -1
        MenuBindData()
    End Sub

    Protected Sub grdMenu_RowUpdating(ByVal sender As Object, ByVal e As GridViewUpdateEventArgs)
        Dim txtName As TextBox = grdMenu.Rows(e.RowIndex).FindControl("txtName")
        Dim txtUrl As TextBox = grdMenu.Rows(e.RowIndex).FindControl("txtUrl")
        Dim menuID As Int32
        Int32.TryParse(grdMenu.DataKeys(e.RowIndex).Values(0), menuID)

        Dim isSaved As Boolean = SecurityManager.EditMenu(menuID, txtName.Text, txtUrl.Text)

        If (isSaved) Then
            notMain.Notifications.Add(New Notification("i2", NotificationType.Information, "The Menu Was Updated Successfully"))
        Else
            notMain.Notifications.Add(New Notification("e1", NotificationType.Warning, "The Menu Was Not Updated Successfully"))
        End If

        grdMenu.EditIndex = -1
        MenuBindData()
        MenuAccessBindData()
    End Sub

    Protected Sub grdMenuAccess_RowDeleting(sender As Object, e As GridViewDeleteEventArgs)
        Dim menuDepartmentID As Int32
        Int32.TryParse(grdMenuAccess.DataKeys(e.RowIndex).Values(1), menuDepartmentID)

        Dim isSaved As Boolean = SecurityManager.DeleteMenuAccess(menuDepartmentID)

        If (isSaved) Then
            notMain.Notifications.Add(New Notification("i2", NotificationType.Information, "The Menu Access Was Deleted Successfully"))
        Else
            notMain.Notifications.Add(New Notification("e1", NotificationType.Warning, "The Menu Access Was Not Deleted Successfully"))
        End If

        MenuAccessBindData()
        REMIAppCache.RemoveMenuAccess(ddlDepartments.SelectedItem.Value)
        REMIAppCache.SetMenuAccess(ddlDepartments.SelectedItem.Value, SecurityManager.GetMenuAccessByDepartment(String.Empty, ddlDepartments.SelectedItem.Value))
    End Sub

    Protected Sub btnAddAccess_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim menuID As Int32 = 0
        Int32.TryParse(Request.Form(grdMenuAccess.FooterRow.FindControl("ddlMenuOptions").UniqueID), menuID)

        Dim isSaved As Boolean = SecurityManager.AddMenuAccess(menuID, ddlDepartments.SelectedItem.Value)

        If (isSaved) Then
            notMain.Notifications.Add(New Notification("i2", NotificationType.Information, "The Menu Access Was Inserted Successfully"))
        Else
            notMain.Notifications.Add(New Notification("e1", NotificationType.Warning, "The Menu Access Was Not Inserted Successfully"))
        End If

        MenuAccessBindData()
        REMIAppCache.RemoveMenuAccess(ddlDepartments.SelectedItem.Value)
        REMIAppCache.SetMenuAccess(ddlDepartments.SelectedItem.Value, SecurityManager.GetMenuAccessByDepartment(String.Empty, ddlDepartments.SelectedItem.Value))
    End Sub
End Class